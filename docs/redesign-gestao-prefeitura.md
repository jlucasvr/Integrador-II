# Redesign operacional da Gestão e da Prefeitura

## Diagnóstico e prioridades

| Superfície | Problema observado | Prioridade |
| --- | --- | --- |
| Meus pontos | A lista dependia do toque no registro para revelar o estoque. Não havia pesquisa, e a situação aparecia apenas para pontos inativos. | Encontrar o ponto e mostrar a próxima ação. |
| Estoque | Cada item repetia uma coluna de informações e três botões. A comparação exigia rolar mesmo no desktop. Abrir uma movimentação ou o histórico desmontava a lista e descartava a busca. | Comparar saldo, distribuição e publicação e voltar à mesma busca. |
| Movimentação e histórico | O cabeçalho identificava a operação e o item, mas o ponto saía de vista. | Manter ponto e retorno explícito ao estoque. |
| Publicação e catálogo | As validações e o tratamento de conflitos já existiam. O estoque vazio tinha texto, mas faltava distinguir primeiro uso de uma busca sem resultado. | Preservar as proteções e separar os estados. |
| Prefeitura | O login reconhecia a conta municipal, mas o Flutter mostrava apenas um aviso. A API já listava, cadastrava e registrava decisões. | Expor essas operações, com atenção às pendências e às consequências de cada decisão. |

## Soluções

- **Meus pontos** pesquisa nome ou instituição sem exigir acentos. Cada
  registro mostra instituição, endereço, situação e ações de estoque e edição.
- **Estoque** usa colunas de item, saldo, distribuição, publicação e ações
  em telas largas. Em espaço menor ou com texto ampliado, os registros passam
  a blocos verticais. A busca combina com filtros de saldo zero, ocultação
  e disponibilidade. Disponibilidade operacional significa saldo positivo
  e distribuição habilitada. Visibilidade pública é uma condição separada.
  Movimentar recebe o botão principal do registro. Publicação e Histórico
  ficam como ações secundárias.
- **Operações** mantêm o nome do ponto visível na movimentação e no histórico.
  Ao voltar ao estoque, a busca e os filtros são reaplicados, inclusive após
  uma movimentação confirmada. O histórico pode ser atualizado e identifica
  o limite de 100 registros. A publicação recebe contexto do ponto e confirma
  quando foi salva. Os formulários existentes continuam protegidos por
  controle de versão e pelos tratamentos de resposta incerta.
- **Prefeitura** lista apenas as instituições retornadas para a conta
  municipal. A lista abre com pendências primeiro e também permite ordenar
  por nome. Os filtros mostram contagens da lista carregada. O detalhe
  identifica a situação atual. O cadastro começa pendente e o formulário de
  decisão exige uma nova situação e justificativa. As consequências públicas
  aparecem antes da confirmação. A interface oferece apenas mudanças de
  situação para evitar registrar a mesma decisão por engano.

## Identidade e acessibilidade

As duas áreas reutilizam Poppins, o tema monocromático, os botões em
pílula, as bordas e o cabeçalho da Plataforma de apoio. As linhas
tabulares usam o cinza claro já previsto no tema e divisores no lugar de
sombras novas. Cabeçalhos, estados vazios, indicadores com ícone e texto,
e colunas operacionais são compartilhados. A interface usa controles
Material com foco e teclado, contagens anunciáveis, rótulos explícitos,
campos com erro textual e quebra de linhas sem depender de cor para o status.

## Validação

- Análise estática do Flutter sem problemas e 48 testes Flutter aprovados.
  A cobertura inclui sessão expirada, estoque vazio, conflito de versão,
  movimentação, publicação e retorno ao estoque com o filtro preservado.
  A compilação Web concluiu com um aviso não bloqueante sobre a fonte
  Cupertino.
- A suíte da API passou em 19 testes. Dois cenários Dart passaram contra a
  API com PostgreSQL em schemas de teste: o fluxo do Gestor da criação do
  ponto à consulta pública e o da Prefeitura do cadastro às três situações,
  com verificação de permissões entre perfis.
- As telas foram renderizadas com dados fictícios em 390, 768 e 1280 px
  para inspecionar hierarquia, contraste e quebra das linhas. Testes de
  interação também cobrem 320 px. A inspeção usou o renderizador de testes
  do Flutter. Ainda falta validar com leitor de tela e pessoas usuárias.

## Contrato e próximos passos

O Flutter consome os contratos existentes para listagem, cadastro e
verificação. A API não fornece histórico de decisões ao cliente, detalhes
cadastrais além dos campos atuais, edição de instituição ou gestão de
equipe. Expor a trilha de decisões e paginar listas volumosas depende de
evolução do contrato. Recomenda-se observar gestores encontrando um item
sem saldo e operadores municipais revisando uma pendência, medindo tempo,
erros e uso da navegação por teclado com registros reais autorizados.
