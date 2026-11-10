# Modernização da arquitetura e preparação para implantação

## A. Diagnóstico inicial

O Flutter já consumia a API HTTP por repositórios e serviços. O Express
concentrava rotas e SQL síncrono no mesmo arquivo. A persistência principal
abria SQLite em modo WAL, com chaves estrangeiras e evolução de esquema no
bootstrap. A prévia acadêmica já tinha um ponto de entrada separado e
descartável. Foram revisados busca, cadastro e edição de pontos, catálogo,
estoque, movimentações, publicação, escopo municipal e sessões.

O risco da troca de banco estava nos tipos serializados para o Flutter,
nas transações antes protegidas por `BEGIN IMMEDIATE`, na ordem do histórico
e no arquivo SQLite preexistente. O plano foi manter o contrato REST e as
regras, portar esquema e transações, testar com dois bancos, validar o
Compose e o procedimento de recuperação e só então documentar a operação.
SQL parametrizado com `pg` aproveita as consultas atuais e evita introduzir
um ORM. O Flutter ficou fora dos contêineres para preservar hot reload e
depuração. Empacotar o build Web em contêiner pode ser avaliado no futuro.

## B. Alterações realizadas

| Arquivos | Mudança |
| --- | --- |
| `backend/migrations/001_initial.sql`, `backend/src/migrate.js` | Esquema relacional com restrições e índices; aplicação transacional, lock e checksum. |
| `backend/src/{app,postgres,server,credentials}.js` | Pool, SQL parametrizado, leitura pública em uma consulta, logs JSON e ID de requisição, liveness/readiness, validação de CORS e proxy. Login verifica scrypt fora do loop principal e devolve 429 JSON ao atingir o limite. |
| `backend/src/{import-sqlite,seed,preview,sqlite-adapter,database}.js` | Importação somente leitura, seed PostgreSQL com fixture fictícia, preservação da prévia SQLite e dos arquivos existentes. |
| `compose.yaml`, `backend/Dockerfile`, `backend/.dockerignore`, `.env.example` | Banco PostgreSQL 18 com volume, migração antes da API, API executada como usuário sem privilégios no contêiner, serviços em loopback. |
| `backend/test`, `backend/integration`, `tool/run_management_live_check.mjs`, `iniciar.ps1` | Regressão nos dois bancos, integração Flutter com schema isolado, geração da prévia. |
| `README.md`, `backend/README.md`, `ARCHITECTURE.md`, `GUIA_GESTAO.md`, `docs/operacao-postgresql.md` | Inicialização, contrato, operação, recuperação e testes. |

O estoque usa bloqueio de linha para calcular e gravar saldo e histórico
na mesma transação. A versão enviada pelo cliente continua rejeitando
edições concorrentes. A criação idempotente de ponto serializa tentativas
do mesmo gestor e grava ponto e chave juntos. O histórico usa uma sequência
interna para desempatar horários iguais; ela não entra na resposta HTTP.
Os campos privados 0/1 foram preservados e as datas continuam em ISO 8601.
O adaptador segue a orientação do driver de manter [uma única conexão por
transação](https://node-postgres.com/features/transactions).

## C. Como executar

Na raiz: configure `.env` conforme `.env.example`, rode
`docker compose up --build --wait` e depois `.iniciar.ps1 -Api`.
Em banco vazio, o seed pode ser executado separadamente para criar as contas
e o catálogo de teste. Veja o [guia de operação](operacao-postgresql.md)
para os pré-requisitos, comandos de teste, portas, importação e recuperação.

## D. Validação

- Regressão Node: 19 testes na suíte local e 24 na suíte executada com
  PostgreSQL (incluindo a regressão do esquema SQLite legado). Cobertura:
  consulta pública,
  permissões, saldo e histórico, cadastro e edição de pontos, idempotência,
  catálogo, publicação e escopo da prefeitura.
- PostgreSQL: migração repetível, importação de fixtures SQLite v1, v2 e v3,
  origem inalterada por checksum, rejeição de destino preenchido e rollback
  integral de linhas incompatíveis. O arquivo local existente não foi
  importado nem classificado como fictício.
- Docker: build, migração, seed, login e movimento pela API, consulta pública,
  falha simulada do banco e dados preservados na retomada. Um `pg_dump` foi
  copiado ao host e restaurado em outro banco; contagens, saldo e último
  movimento coincidiram. O limite de login foi verificado com HTTP 429.
- Flutter: análise sem problemas, 46 testes, cenário ao vivo
  Flutter → API → PostgreSQL e compilação Web. O pacote acadêmico também
  foi compilado e serviu HTML, favicon e busca com dados fictícios. Houve
  aviso não bloqueante sobre a fonte Cupertino no build.
- A dependência transitiva `body-parser` foi atualizada após o aviso do
  build. `npm audit --omit=dev` retornou zero avisos após a correção.

## E. Antes de uma implantação real

O Compose é de desenvolvimento. Para produção, definir TLS no proxy e na
conexão remota ao banco, origens HTTPS, injeção e rotação de segredos,
contas de aplicação e migração com privilégios separados, backup externo
com retenção e teste de recuperação, alertas e limites de tráfego. O rate
limiter atual é por IP e processo; para várias réplicas, decidir entre
limitação no proxy ou um armazenamento compartilhado. Configure o proxy
para que logs de acesso também omitam consultas com coordenadas. Confirmar
carga, paginação e latência com volume representativo antes de liberar:
a busca reduz viagens ao banco, mas ainda filtra os resultados em memória.

O login e o logout existem; a sessão fica em memória no Flutter, o token
expira em 8 horas e o banco guarda seu hash. A API não oferece criação ou
desativação de contas reais, remoção de sessões de um usuário por um
operador, recuperação de senha, gestão de vínculos ou edição do catálogo
mestre. Há cadastro e verificação de instituições com escopo municipal
e histórico de decisões. Falta decidir quem provisiona, vincula e revoga
contas de Gestor e Prefeitura, quem pode redefinir acessos e por qual canal
a identidade é verificada. Essas decisões também determinam a trilha de
auditoria de contas. Nenhum ambiente externo foi criado.

## CONTEXTO PARA O AGENTE DE UX/UI

O Flutter mantém as camadas de telas e view models em `lib/ui` e os
repositórios que conversam com a API em `lib/data`. O PostgreSQL é
transparente para o cliente. Consulte o [contrato HTTP](../backend/README.md)
antes de alterar formulários, mensagens ou navegação. As adições ao
contrato são `/ready`, `X-Request-Id` para suporte e resposta JSON no 429.
O campo `meta.demo` indica a prévia isolada, não o conteúdo do banco local.

**Gestor.** Em Gestão, entra, vê as instituições vinculadas e os pontos
autorizados, cadastra e edita pontos, seleciona um estoque, vincula itens
do catálogo, registra entrada, saída ou ajuste, consulta o histórico e
edita publicação. Um ponto novo não tem estoque. Um item novo tem saldo
zero e permanece oculto até publicação. Quantidade pública, visibilidade,
distribuição e aceitação de doação são controles distintos. Pontos inativos
ou de instituições pendentes/suspensas não aparecem na busca pública.

**Prefeitura.** A API lista e cadastra instituições no município do usuário;
cadastros começam pendentes. Permite verificar, suspender ou devolver para
pendência com justificativa, responsável e data. O login reconhece o papel,
mas não existe painel Flutter da Prefeitura. Um desenho de painel pode
partir dessas operações; gestão de equipe, recuperação de acesso e
consulta à trilha de verificação exigem contrato adicional. Não pressupor
acesso global, mudanças de estoque pela Prefeitura, nem criação de contas
ao cadastrar uma instituição.

**Estados a preservar.** Tratar carregamento e envio, listas vazias (sem
vínculo, ponto, estoque, catálogo restante ou histórico), indisponibilidade
com nova tentativa, 401 com retorno ao login, 403 com explicação de acesso,
404 de recurso ausente/fora de escopo e 429 com espera. Diferenciar versão
desatualizada, saldo insuficiente, item já vinculado e chave de reenvio
conflitante. Preservar o formulário de ponto e a mesma chave em um reenvio
incerto. Em movimento sem confirmação, orientar a consulta de saldo e
histórico antes de outra tentativa. A publicação não deve sugerir que o
saldo privado será mostrado. Busca sem localização continua disponível.

**Padrões para reaproveitar.** `management_page.dart` organiza Gestão;
`points_view.dart`, `point_form.dart`, `stock_view.dart`,
`publication_form.dart`, `movement_view.dart` e `history_view.dart`
materializam os fluxos atuais. Reutilizar os view models de estoque e
movimentação, `load_failure.dart`, `stock_item_card.dart` e
`stock_movement_tile.dart`, além de tema e componentes de `lib/ui/core`.
Há testes em larguras de celular e desktop. Para dar caráter de CRM,
começar com navegação de Gestão, hierarquia entre ponto e estoque, ações
primárias claras e estados com rótulos. Totais globais, filtros no servidor
e histórico além das últimas 100 movimentações exigem trabalho na API;
evite desenhar esses números como se já estivessem disponíveis.
