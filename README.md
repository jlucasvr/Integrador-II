# Plataforma de apoio — Projeto Integrador 2

Front-end em Flutter e API local em Node.js/Express com SQLite.

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

Mapa, localizacao e contatos ainda sao demonstrativos. O aplicativo nao envia coordenadas; no modo API, mantenha todas as distancias. Alterar as opcoes de publicacao pela interface, convites, recuperacao de senha e painel da prefeitura seguem pendentes.

## Validacao

```powershell
.\iniciar.ps1 -Action check -Api
```

Analise, testes Flutter e compilacao web conectada a API. Testes da API: npm.cmd test dentro de backend. Os testes utilizam dados isolados e nao alteram o banco de demonstracao.

Existe tambem uma verificacao opcional em tool/management_live_check.dart, que exige uma API isolada com LIVE_API_BASE_URL; nao e executada pela suite padrao. O teste confirma entrada de estoque e atualizacao da busca publica.
