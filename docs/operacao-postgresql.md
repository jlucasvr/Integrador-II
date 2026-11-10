# Operação local com PostgreSQL

Comece pelo [README](../README.md). O Compose precisa do Docker em execução e
de um `.env` com senha local. Node.js 24+ no computador é necessário para
rodar testes da API ou iniciar o servidor fora do Docker. Para Flutter Web,
use o SDK indicado no README e Edge; o frontend continua no computador para
preservar hot reload, DevTools e a experiência de depuração do SDK.

## Subida e diagnóstico

- `docker compose up --build --wait`: sobe o banco, aguarda o health check,
  aplica as migrações em um serviço de execução única e inicia a API.
  `migrate` em `Exited (0)` é o resultado esperado.
- `docker compose run --rm migrate`: aplica migrações pendentes. Não edite
  um SQL já aplicado; adicione o próximo arquivo numerado e mantenha os
  anteriores no repositório. O executor bloqueia execuções simultâneas,
  verifica checksums e usa uma transação.
- `docker compose ps -a` e `docker compose logs --tail 100 api migrate db`:
  mostram estado e falhas. `/api/v1/health` verifica o processo;
  `/api/v1/ready` retorna 503 se o banco ou o esquema inicial estiver indisponível.
- `docker compose restart api` reinicia só a API; `docker compose down`
  remove os contêineres, preservando o volume. Para testar do zero sem apagar
  o banco atual, use outro nome de projeto com `-p`, outro arquivo de ambiente
  com `--env-file` e portas distintas. `down -v` apaga o banco do projeto
  selecionado; use apenas em um ambiente confirmado como descartável.

Se a porta estiver ocupada, altere `APOIO_API_PORT` ou `APOIO_PG_PORT` no
`.env`. Se alterar a porta da API para 3001, rode
`.iniciar.ps1 -Api -ApiBaseUrl http://127.0.0.1:3001/api/v1`.
O Flutter Web tem sua própria porta; a URL da API é independente. Se restringir
CORS, permita a origem exata do Flutter; para estabilizar a porta em execução
direta, use `flutter run -d edge --web-port 8080` com o
`--dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1`.

Os serviços Compose estão publicados só em loopback. Um navegador no próprio
computador usa `127.0.0.1`; no emulador Android padrão, `10.0.2.2` aponta para
o host; um dispositivo físico precisa alcançar o IP do computador pela rede.
Esses dois últimos caminhos dependem do host e das regras de rede do ambiente
de teste. A opção padrão foi validada para Web; uma configuração móvel deve
ser testada separadamente, sem expor a porta do PostgreSQL.

Se a senha mudar no `.env` depois da criação do volume, o PostgreSQL preserva
a senha original. Use a credencial anterior ou rotacione-a dentro do banco e
atualize os serviços juntos. Recriar contêineres sozinho não altera a senha.

## Configuração fora do Compose

Em `backend`, rode `npm ci`, configure `DATABASE_URL` ou
`PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` e `PGPASSWORD`, e então rode
`npm run migrate` e `npm start`. A API escuta por padrão em
`HOST=127.0.0.1`, `PORT=3000`. `DB_PATH` era da API antiga.

`CORS_ORIGINS` recebe origens exatas, separadas por vírgula. Vazio no
desenvolvimento aceita origens HTTP de loopback com porta. Com
`NODE_ENV=production`, a lista é obrigatória e só aceita HTTPS.
`TRUST_PROXY` fica desabilitado por padrão. Atrás de proxy, configure somente
IPs ou sub-redes controladas, restrinja o acesso direto à API e faça o proxy
sanear os cabeçalhos encaminhados; valide os IPs vistos pelo rate limiter.

`npm run seed` usa `DEMO_PASSWORD` (12–256 caracteres) para duas contas
fictícias: `gestor@example.test` e `prefeitura@example.test`. Requer banco
vazio e é bloqueado com `NODE_ENV=production`. Depois do seed, remova a
variável da sessão de terminal com `Remove-Item Env:DEMO_PASSWORD` quando não
precisar mais dela. O seed não imprime a senha nem escreve credencial em disco.

## Testes

Na raiz, com PostgreSQL de desenvolvimento iniciado:

```powershell
npm.cmd ci --prefix backend
npm.cmd test --prefix backend
# Substitua SENHA_LOCAL pela senha do banco; codifique caracteres reservados da URL.
$env:TEST_DATABASE_URL = 'postgresql://apoio:SENHA_LOCAL@127.0.0.1:5433/apoio'
npm.cmd --prefix backend run test:postgres
.iniciar.ps1 -Action integration -Api
Remove-Item Env:TEST_DATABASE_URL
.iniciar.ps1 -Action check -Api
```

O teste PostgreSQL precisa de permissão para criar schemas. Usa schemas
aleatórios, aplica migrações, popula fixtures e remove somente os schemas que
criou. Use credenciais locais de teste. A integração Dart usa o mesmo
isolamento quando a variável está definida. Sem ela, os testes comuns e a
integração Dart usam SQLite em memória. Sem acesso à internet, use `-Offline`
no script Flutter quando o cache de dependências já estiver preenchido.

## Importar uma base SQLite existente

1. Pare a API SQLite anterior e guarde uma cópia consistente em local
   protegido. Se houver WAL, faça snapshot com o comando `.backup` do
   SQLite ou preserve os arquivos associados após fechar os escritores.
   Copiar apenas o arquivo principal enquanto há WAL pode perder alterações.
2. Crie um PostgreSQL de destino isolado e vazio, rode `npm run migrate`
   e **não rode o seed**. De `backend`, com a conexão apontando ao destino,
   rode `npm run import:sqlite -- "C:\caminho\copia.sqlite"`.
3. Compare a contagem por tabela emitida pelo importador, faça login e confira
   amostras de pontos, saldos, visibilidade, histórico e verificação. IDs,
   vínculos, hashes de senha, registros históricos e chaves de reenvio são
   preservados. Sessões antigas são descartadas; todos precisam entrar de novo.

O importador lê SQLite v1–v3 em modo somente leitura, valida integridade,
confere contagens e aplica chaves e restrições PostgreSQL numa única
transação. Se falhar, o destino permanece sem as linhas importadas. Preserve
a origem até verificar o destino e seu backup. Se o corte precisar ser
revertido, mantenha o PostgreSQL sem novas escritas e volte à cópia/versão
anterior. Se já houver novas escritas, reconcilie-as antes de voltar;
não há sincronização bidirecional.

## Backup e restauração

Exemplo com usuário e base `apoio`, em PowerShell, na raiz. Use uma pasta
protegida fora de versionamento. O arquivo contém dados e hashes de
credenciais/sessões. Troque o nome do banco de teste se já existir.

```powershell
New-Item -ItemType Directory -Force build/backups | Out-Null
docker compose exec -T db pg_dump -U apoio -d apoio -Fc -f /tmp/apoio.dump
docker compose cp db:/tmp/apoio.dump build/backups/apoio.dump
Get-FileHash build/backups/apoio.dump -Algorithm SHA256
docker compose cp build/backups/apoio.dump db:/tmp/apoio-restore.dump
docker compose exec -T db createdb -U apoio apoio_restore_check
docker compose exec -T db pg_restore -U apoio -d apoio_restore_check --single-transaction --exit-on-error --no-owner --no-privileges /tmp/apoio-restore.dump
```

Compare contagens da origem e do destino, incluindo `schema_migrations`,
`users`, `memberships`, `institutions`, `points`, `items`, `stocks`,
`movements` e `verification_events`. Confira amostras de estoque e histórico:

```powershell
$query = 'SELECT count(*) FROM stocks; SELECT count(*) FROM movements; SELECT quantity FROM stocks WHERE id = ''central-water''; SELECT resulting_balance FROM movements WHERE stock_id = ''central-water'' ORDER BY sequence DESC LIMIT 1;'
docker compose exec -T db psql -U apoio -d apoio -v ON_ERROR_STOP=1 -c $query
docker compose exec -T db psql -U apoio -d apoio_restore_check -v ON_ERROR_STOP=1 -c $query
```

Em uma restauração operacional, pare escritas, restaure em um banco vazio e
verifique com uma instância isolada da API antes de trocar a conexão. Invalide
sessões restauradas antes de voltar a atender usuários (`DELETE FROM sessions`
no destino). Guarde o volume anterior até confirmar o resultado; para
recuperar um volume perdido, recrie só o banco, restaure antes de subir a API
e depois execute as migrações pendentes. Remova as cópias temporárias do
contêiner após confirmar a cópia protegida. Defina frequência, retenção e
testes periódicos de restauração antes de usar dados reais.
