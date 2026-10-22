# Arquitetura do aplicativo Flutter

A organização segue a separação de responsabilidades recomendada no
[guia de arquitetura do Flutter](https://docs.flutter.dev/app-architecture/guide).
Os nomes de arquivos e pastas usam `snake_case`, e as classes usam `UpperCamelCase`.
O Flutter fornece recomendações de arquitetura; a árvore de diretórios é adaptada
às funcionalidades deste aplicativo.

```text
lib/
  main.dart                      # Ponto de entrada
  app/                           # Inicialização, dependências e MaterialApp
  core/
    errors/                      # Falhas compartilhadas
    utils/                       # Normalização e formatação de datas
  data/
    fixtures/                    # Dados demonstrativos
    mappers/                     # Conversão das respostas públicas da API
    models/                      # Modelos de busca, sessão e estoque
    repositories/                # Acesso aos dados e regras de sessão
    services/                    # HTTP, serialização e falhas de transporte
  ui/
    core/
      layout/                    # Limites de largura e espaçamento
      theme/                     # Tema Material compartilhado
      view_models/               # Ciclo de carregamento de listas
      widgets/                   # Componentes compartilhados
    auth/
      view_models/               # Estado assíncrono do login
      views/                     # Formulário de acesso
    management/
      view_models/               # Busca no estoque e movimentações
      views/                     # Gestão, pontos, estoque e histórico
      widgets/                   # Cartões de estoque e movimentações
    search/
      view_models/               # Localização, filtros e ordenação dos resultados
      views/                     # Busca e resultados
      widgets/                   # Categorias, filtros, cartões e busca fixa
    support_points/
      formatters/                # Apresentação da disponibilidade pública
      views/                     # Detalhes de um ponto
      widgets/                   # Tabela de recursos
test/
  data/repositories/             # Contratos de busca remota e demonstrativa
  fixtures/                      # API simulada, sem alterar o banco local
  helpers/                       # Ações compartilhadas dos testes de interface
  ui/                            # Testes por funcionalidade
```

## Fluxo e responsabilidades

`main.dart` abre `AppBootstrap`. O bootstrap cria as dependências uma vez,
injeta os repositórios no aplicativo e fecha os clientes HTTP ao ser descartado.
`API_BASE_URL` seleciona a API remota ou os dados demonstrativos da consulta pública.
Temporariamente, `MOCK_SEARCH` tem padrão `true` no modo debug e prioriza os dados
locais. Nesse modo, `locationFilteringEnabled=false` desativa a restrição por
distância nos resultados, preservando os filtros de item, intenção e disponibilidade.
`--dart-define=MOCK_SEARCH=false` restaura a seleção pela URL da API.

A busca usa exclusivamente coordenadas. `LocationService` captura a posição pelo
`geolocator`, e `LocationViewModel` controla carregamento, falhas e nova tentativa.
O serviço é injetável para testar o fluxo sem acessar a localização real.
`SearchQuery` transporta latitude e longitude, enviadas como `lat` e `lon` à API.
`SearchDock` mantém as coordenadas e o formulário fixos na base da home e dos
resultados, inclusive com rolagem ou teclado aberto. Novos termos são consultados
na mesma tela de resultados, preservando coordenadas e filtros.

As views compõem widgets, mantêm os controladores de formulário e cuidam da
navegação. Os view models expõem estado e ações através de `ChangeNotifier`.
Filtros e ordenação de resultados, validação de movimentações e tratamento do
estado assíncrono ficam fora dos métodos `build`.

Os repositórios entregam modelos para a interface. `PointRepository` é o contrato
da consulta pública, implementado por `ApiPointRepository` e
`MockPointRepository`. `ManagementRepository` centraliza a sessão em memória,
expiração, autorização e operações de gestão. Os serviços encapsulam o HTTP;
eles não importam componentes de interface. O mapper da busca pública preserva
quantidades e distâncias desconhecidas como `null`.

O backend Node.js continua em `backend/`, com seu próprio ciclo de execução e
testes. As ferramentas opcionais de integração permanecem em `tool/`.

## Onde adicionar código

- Nova tela: `ui/<funcionalidade>/views/`.
- Componente da funcionalidade: `ui/<funcionalidade>/widgets/`.
- Estado ou regra de apresentação: `ui/<funcionalidade>/view_models/`.
- Componente visual compartilhado: `ui/core/`.
- Modelo, integração ou acesso a dados: a subpasta correspondente em `data/`.
- Teste: `test/` espelhando a responsabilidade ou funcionalidade.

Use imports explícitos de `package:apoio_app/...`. Não importe `main.dart` para
acessar telas ou modelos. Injete repositórios pelos construtores para permitir
testes com clientes simulados. Preserve a expiração de sessão, o controle de
versão do estoque e o bloqueio de reenvio após uma resposta incerta.

## Validar

```powershell
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
```
