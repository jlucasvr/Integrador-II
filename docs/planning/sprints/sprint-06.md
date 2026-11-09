# Sprint 6 — Homologar e entregar

Escopo de entrega acadêmica local, com Flutter Web, Express e SQLite. A prévia do pacote executa com dados sintéticos em memória e usa uma porta de loopback livre.

| ID | Entrega | Evidência esperada |
|---|---|---|
| AP-601 | SDK Flutter selecionável por `PATH` ou `-FlutterSdk`, mínimos alinhados ao lockfile e verificação unificada. | Instalação a partir de uma cópia de fontes sem `.dart_tool` ou `node_modules`. `npm ci` e `flutter pub get --enforce-lockfile` resolvem os lockfiles. O comando `check -Api` executa análise, as duas suítes, integração e build. |
| AP-602 | Homologação em navegador e ajustes localizados de teclado, idioma e contraste. | Busca sem GPS e detalhe público. Em gestão, cadastro, vínculo, primeira entrada, histórico, publicação, atualização pública e desativação. Navegação por Tab e Enter em 320 px. |
| AP-603 | Pacote web com API local e roteiro de avaliação. | `iniciar.ps1 -Action package` gera a pasta de entrega. Dentro do pacote, `npm ci` seguido de `npm run preview` inicia interface e API na mesma origem. A tela identifica os dados fictícios. |

## Roteiro

O arquivo [ENTREGA_LOCAL.md](../../../ENTREGA_LOCAL.md) acompanha o pacote. O modo de desenvolvimento e a verificação unificada estão no [README](../../../README.md).

## Homologação

| Verificação | Resultado |
|---|---|
| Instalação | Windows, Node.js 24.15.0, npm 11.12.1, Flutter 3.47.7 e Dart 3.13.5. As dependências foram instaladas pelos lockfiles em uma cópia sem `.dart_tool` e sem `node_modules`. A instalação Dart usou um cache isolado. |
| Gestão e busca no navegador | No navegador integrado, em 1280 × 720, a busca sem GPS abriu a ficha pública. O fluxo de gestão criou um ponto fictício, vinculou Água potável, registrou a entrada de 7 garrafas, publicou a quantidade e confirmou a ficha pública. Depois da desativação, a busca voltou de quatro para três resultados e o histórico manteve a movimentação de 0 para 7. |
| Teclado e largura estreita | No pacote final extraído, em 320 × 568, `Tab`, `Shift+Tab` e `Enter` acionaram **Buscar sem localização**. A revisão identificou sobreposição visual da barra em tela estreita. O fundo opaco corrigiu o problema e foi verificado no build final. Um teste Flutter cobriu texto ampliado a 200% na mesma largura. |
| Arquivo de entrega | `build/entrega-local-20261109-122133-865.zip`. A extração, a instalação Node e a execução da prévia foram verificadas. A prévia usa credenciais temporárias e SQLite em memória. |

`iniciar.ps1 -Action check -Api` concluiu com análise limpa, 46 testes Flutter, 18 testes Node, integração isolada e build web aprovados. Os builds emitiram o aviso preexistente sobre a fonte Cupertino. A homologação registrou apenas o ambiente local descrito acima.
