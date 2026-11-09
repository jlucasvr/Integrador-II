# Plataforma de apoio — Projeto Integrador 2

Front-end em Flutter e API local em Node.js/Express com SQLite.

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

Terminal 1:

```powershell
cd 'C:\Users\João\Documents\Projetos\Projeto Integrador 2\backend'
npm.cmd ci
npm.cmd start
```

Terminal 2:

```powershell
cd 'C:\Users\João\Documents\Projetos\Projeto Integrador 2'
.\iniciar.ps1 -Api
```

Reinicie o processo da API depois de atualizar o backend. O banco demonstrativo
existente pode ser reutilizado. Execute `seed` somente em uma instalação nova com
banco vazio.

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

Clique em Gestao na tela inicial. Conta gestora: gestor@example.test. A senha local esta em backend/data/demo-access.txt. Selecione Centro de Apoio Central, consulte o estoque, registre uma movimentacao e abra o historico. Refaca uma busca publica para conferir a atualizacao.

Sessao mantida em memoria durante a navegacao; recarregar exige novo login. Sair limpa a sessao local e tenta invalidar o token no servidor. Sessao expirada retorna ao login. Painel da prefeitura e convites ficam para as proximas etapas.

Guia detalhado: GUIA_GESTAO.md. Contrato da API e decisoes: backend/README.md.

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
linha reta. Os dados do seed SQLite também são ilustrativos, embora o modo API
permita consultar e editar os registros persistidos.
Gestores podem cadastrar e editar pontos (incluindo contato, coordenadas e
ativação) e configurar a publicação de cada item pelo botão Publicação no estoque.
Para iniciar o estoque de um ponto novo, use **Vincular item do catálogo**.
O item começa com saldo zero e fica oculto da consulta até a publicação explícita.
Convites, recuperação de senha e painel da prefeitura seguem pendentes.
PostgreSQL foi escolhido para implantação; esta versão ainda executa com SQLite.
Escopo e roteiro das sprints: [SPRINTS.md](SPRINTS.md).

## Validacao

```powershell
.\iniciar.ps1 -Action check -Api
```

O comando executa análise Dart, testes Flutter, testes Node, integração com
SQLite em memória e compilação web em modo API.

Para empacotar a versão conectada, indique a URL de destino explicitamente com
`-ApiBaseUrl` ou com a variável `API_BASE_URL`. `-Action build -Api` rejeita a
ausência da URL. `-Action build` sem `-Api` gera a demonstração.

```powershell
.\iniciar.ps1 -Action build -Api -ApiBaseUrl http://127.0.0.1:3000/api/v1
```

Para verificar a integração Dart → API → SQLite, instale as dependências do
backend e execute na raiz:

```powershell
.\iniciar.ps1 -Action integration
```

O comando inicia uma API em porta local temporária com SQLite em memória,
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
