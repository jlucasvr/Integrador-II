# Plataforma de apoio — Projeto Integrador 2

Front-end em Flutter e API local em Node.js/Express com SQLite.

Modo temporario de teste visual: em desenvolvimento, a busca publica usa dados
mockados de todas as categorias e ignora coordenadas e filtros de distancia,
mesmo com `API_BASE_URL` definido. A captura e a exibicao da localizacao continuam
ativas. Para voltar a busca real, acrescente `--dart-define=MOCK_SEARCH=false`
ao comando Flutter, junto de `API_BASE_URL`. Builds de release usam a API por
padrao quando sua URL esta configurada; `MOCK_SEARCH=true` permite testar mocks
explicitamente nesses builds.

## Organização do código

O aplicativo está dividido em `app/`, `core/`, `data/` e `ui/`, com telas,
componentes e view models separados por funcionalidade. Os testes seguem a mesma
organização. Consulte [ARCHITECTURE.md](ARCHITECTURE.md) para a árvore de pastas,
as responsabilidades de cada camada e as orientações para adicionar código.

## Executar

Terminal 1:

```powershell
cd 'C:\Users\João\Documents\Projetos\Projeto Integrador 2\backend'
npm.cmd start
```

Terminal 2:

```powershell
cd 'C:\Users\João\Documents\Projetos\Projeto Integrador 2'
.\iniciar.ps1 -Api
```

Se a API ja estava iniciada, reinicie seu processo para carregar as novas respostas de instituicao/responsavel. Dados demonstrativos ja criados; nao execute seed novamente neste banco.

Sem -Api, a consulta utiliza os dados embutidos. O script usa um alias temporario para contornar erros do Flutter com acentos no caminho e restaura os caminhos das dependencias ao terminar.

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
- Login, selecao dos pontos autorizados e pesquisa no estoque.
- Saldo, unidade, data e informacoes de publicacao.
- Entrada, saida ou ajuste, com previa do saldo e controle de versao.
- Historico com saldo anterior/resultante e nome do responsavel.
- Tratamento de falhas, conflito de estoque, sessao expirada e logout.

A busca usa a localizacao do dispositivo e envia latitude/longitude para a API,
sem entrada manual de endereco. Permita o acesso a localizacao no navegador;
use localhost no desenvolvimento e HTTPS em producao. A barra de busca fica fixa
na home e nos resultados, com as coordenadas acima do campo. O mapa foi removido.
Enderecos, coordenadas dos pontos e contatos do banco demonstrativo continuam
ilustrativos; as distancias da API sao calculadas em linha reta. No modo sem API,
as distancias dos dados embutidos continuam demonstrativas.
Alterar as opcoes de publicacao pela interface, convites, recuperacao de senha e
painel da prefeitura seguem pendentes.

## Validacao

```powershell
.\iniciar.ps1 -Action check -Api
```

Analise, testes Flutter e compilacao web conectada a API. Testes da API: npm.cmd test dentro de backend. Os testes utilizam dados isolados e nao alteram o banco de demonstracao.

Existe tambem uma verificacao opcional em tool/management_live_check.dart, que exige uma API isolada com LIVE_API_BASE_URL; nao e executada pela suite padrao. O teste confirma entrada de estoque e atualizacao da busca publica.
