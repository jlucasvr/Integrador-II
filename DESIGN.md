# Identidade visual provisoria

Referencia: wireframe monocromatico aprovado pelo usuario em 14/10/2026.

- Modo de uso: consulta publica e gestao de estoque.
- Cores: branco, cinza claro #EEEEEE, texto/botoes/selecao #292929. Bordas claras padronizadas em #D0D0D0 solido, 1 pixel; elementos preenchidos em preto mantem borda #292929 da mesma cor do preenchimento. Campo em foco usa contorno #292929 de 2 pixels.
- Poppins local, peso 500 para textos, rotulos e acoes; peso 700 reservado aos destaques. Corpo 14, auxiliares 12, titulos de tela 20; chamada inicial 48 com peso 800 e descricao 18.
- Selecao de ajuda/doacao e categorias agrupadas junto a busca fixa na base da home, com intervalo de 8 pixels entre os controles.
- Campos e botoes em formato de pilula; altura minima dos botoes 44.
- Busca fixa na base da home e dos resultados, com campo e botao de lupa integrados em uma unica pilula.
- Pilula de localizacao flutuante alinhada a esquerda acima da busca, com icone a esquerda e texto a direita; apos a captura, reduz por animacao de 420 ms a um circulo com o icone, mantendo a borda esquerda fixa. Coordenadas aparecem apenas apos a captura, como valores numericos sem rotulos, a 4 pixels da barra. A lupa e branca.
- Consulta publica sem login; entrada da gestao preservada no cabecalho.
- Cabecalho compartilhado com nome do app em pilula, gestao em botao circular e voltar quando houver navegacao anterior. Todos com 48 pixels de altura, borda suave e sombra discreta. Fundo em gradiente branco no topo para transparente embaixo.
- Resultados em lista, sem mapa. Filtros expansivos preservam a pesquisa e o campo mantem o termo pesquisado.
- Nos resultados, a contagem aparece como eyebrow "X resultados para" acima do termo, em Poppins 12/500, com singular para um resultado. Filtros ficam em pilula flutuante de 48 pixels no topo direito, abaixo da gestao, com icone a direita. Pilula e painel sao sobrepostos e nao reservam espaco no cabecalho nem deslocam os resultados.
- Aviso de consulta sem conta logo abaixo da selecao de ajuda/doacao, centralizado em tamanho 11.
- Resultados em cards de cantos de 28 pixels, com icone da instituicao, nome em peso 700, categoria/distancia em pilulas e acao de detalhes em pilula preenchida. Disponibilidade aparece ao lado do nome do recurso como texto e icone pequenos, sem pilula ou fundo proprio. Quantidade aparece apenas nos detalhes.
- Detalhes exibem recursos em tabela, doacoes e contato.
- Nenhum horario aberto/agora ou selo de verificacao e inventado pelo tema; o conteudo permanece vinculado aos dados existentes.
- Tema compartilhado com login e gestao, definido em lib/ui/core/theme/wireframe_theme.dart.

O aviso de dados ficticios foi removido das telas. Referencia visual orienta hierarquia e componentes, enquanto a navegacao segue o comportamento Flutter existente.
