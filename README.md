# Plataforma de apoio — Projeto Integrador 2

Front-end em Flutter e API em Node.js/Express com PostgreSQL. O SQLite continua
na prévia acadêmica descartável e nos testes locais sem Docker.

`iniciar.ps1 -Api` conecta a busca e a gestão à API local. Sem `-Api`, a busca
abre em **Demonstração · dados fictícios**, com dados embutidos e sem GPS ou
filtro de distância. Ao rodar o Flutter diretamente, `API_BASE_URL` seleciona a
API por padrão. Use `MOCK_SEARCH=true` para escolher a demonstração de forma
explícita, inclusive quando houver uma URL configurada para gestão.

## Organização do código

O aplicativo está dividido em `app/`, `core/`, `data/` e `ui/`, com telas,
componentes e view models separados por funcionalidade. Os testes seguem a mesma
organização. Consulte [ARCHITECTURE.md](ARCHITECTURE.md) para a árvore de pastas,
as responsabilidades de cada camada e as orientações para adicionar código.

## Executar

Para uma instalação de desenvolvimento, use **Node.js 24 ou superior**,
**Dart 3.11 ou superior** e um SDK **Flutter 3.38.1 ou superior** que inclua
esse Dart. Coloque `flutter\bin` no `PATH` ou passe `-FlutterSdk` com a pasta
do SDK. O script usa o SDK em `Downloads\flutter` como alternativa.

Na raiz do projeto, com Docker e Compose v2 em execução:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
# Abra .env e preencha POSTGRES_PASSWORD com uma senha local exclusiva.
docker compose up --build --wait
Invoke-RestMethod http://127.0.0.1:3000/api/v1/ready
```

Para experimentar os fluxos de gestão em um banco novo e vazio:

```powershell
$env:DEMO_PASSWORD = [guid]::NewGuid().ToString('N')
docker compose exec -e DEMO_PASSWORD api npm run seed
# Use o valor desta variável para entrar com gestor@example.test.
$env:DEMO_PASSWORD
.\iniciar.ps1 -Api
```

O Compose aplica as migrações antes de iniciar a API. Use `docker compose up
--build --wait` após alterar o backend. O volume mantém os dados em
`docker compose down` e na próxima subida. Para diagnóstico, use
`docker compose ps -a` e `docker compose logs --tail 100 api migrate db`.
Veja [o guia de operação](docs/operacao-postgresql.md) para usar uma porta
diferente, importar uma cópia do SQLite ou restaurar um backup.

Em caminhos com caracteres fora de ASCII, o script cria um alias temporário
para a compilação. A opção `-Offline` usa o cache local de pacotes Dart e
continua exigindo as versões do lockfile.

Se o PowerShell bloquear a execucao do script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Api
```

Se aparecer `Shader compilation error` no navegador, reinicie o Flutter e abra
a URL local com `?rendering=software` antes de qualquer `#`, por exemplo
`http://localhost:8080/?rendering=software`. Esse modo usa CanvasKit por CPU para
contornar falhas de WebGL; pode reduzir o desempenho. Sem o parametro, o
aplicativo continua usando a renderizacao padrao.

## Gestao

Clique em Gestão na tela inicial e entre com a conta fictícia criada pelo seed.
Selecione Centro de Apoio Central, consulte o estoque, registre uma movimentação
e abra o histórico. Refaça uma busca pública para conferir a atualização.

A sessão fica em memória durante a navegação. Recarregar exige novo login.
Sair limpa a sessão local e tenta invalidar o token no servidor. Contas da
Prefeitura abrem o painel de instituições do seu município.

Veja o [guia de Gestão](GUIA_GESTAO.md), o [contrato da API](backend/README.md)
e o [relatório do redesign](docs/redesign-gestao-prefeitura.md).

## Funcionalidades

- Consulta publica sem conta, lista, filtros e detalhes.
- Busca pela API ou demonstracao local.
- Login, seleção dos pontos autorizados, vínculo pelo catálogo e pesquisa no estoque.
- Saldo, unidade, data e informacoes de publicacao.
- Entrada, saida ou ajuste, com previa do saldo e controle de versao.
- Historico com saldo anterior/resultante e nome do responsavel.
- Tratamento de falhas, conflito de estoque, sessao expirada e logout.

Na busca conectada, o navegador pode fornecer latitude e longitude. Use
**Buscar sem localização** para consultar sem pedir acesso ao GPS.
O termo e a intenção são preservados. Você pode habilitar a distância depois,
usando o controle de localização nos resultados. A API calcula a distância em
linha reta. Os dados do seed são ilustrativos, embora o modo API
permita consultar e editar os registros persistidos.
Gestores podem cadastrar e editar pontos (incluindo contato, coordenadas e
ativação) e configurar a publicação de cada item pelo botão Publicação no estoque.
Para iniciar o estoque de um ponto novo, use **Vincular item do catálogo**.
O item começa com saldo zero e fica oculto da consulta até a publicação explícita.
A Prefeitura pode consultar e cadastrar instituições e alterar a situação
da verificação com justificativa. Convites e recuperação de senha seguem
pendentes.
Escopo e roteiro das sprints: [SPRINTS.md](SPRINTS.md).

## Validacao

```powershell
.\iniciar.ps1 -Action check -Api
```

O comando executa análise Dart, testes Flutter, testes Node, integração com
SQLite em memória e compilação web em modo API. Instale as dependências Node
locais com `npm.cmd ci --prefix backend` antes da validação. Com
`TEST_DATABASE_URL` configurada, a integração usa schemas isolados no PostgreSQL.
Veja [os comandos de teste PostgreSQL](docs/operacao-postgresql.md#testes).

Para empacotar a versão conectada, indique a URL de destino explicitamente com
`-ApiBaseUrl` ou com a variável `API_BASE_URL`. `-Action build -Api` rejeita a
ausência da URL. `-Action build` sem `-Api` gera a demonstração.

```powershell
.\iniciar.ps1 -Action build -Api -ApiBaseUrl http://127.0.0.1:3000/api/v1
```

Para verificar somente a integração Dart → API, execute na raiz:

```powershell
.\iniciar.ps1 -Action integration
```

O comando inicia uma API em porta local temporária com banco de teste isolado,
executa o teste de gestão e encerra a API. Verifica o percurso do cadastro de um
ponto ao primeiro item publicado, incluindo reenvio, histórico e desativação.

## Pacote de avaliação

```powershell
.\iniciar.ps1 -Action package
```

O comando gera uma pasta `build/entrega-local-…` com Flutter Web compilado,
backend e [roteiro de avaliação](ENTREGA_LOCAL.md). Na pasta `backend` do pacote,
execute `npm.cmd ci` e `npm.cmd run preview`. O terminal mostra o endereço e a
senha de teste. A interface e a API compartilham a porta da prévia, que usa
somente SQLite em memória com dados fictícios.
