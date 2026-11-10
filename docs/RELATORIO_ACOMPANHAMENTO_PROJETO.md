# Relatório de Acompanhamento do Projeto

Estamos desenvolvendo o **Apoio**, uma plataforma para facilitar a busca por recursos de ajuda e orientar quem quer doar. Já conseguimos demonstrar o caminho completo, do registro de uma entrada de estoque até a consulta pública. Também temos um painel para a Prefeitura acompanhar as instituições do município. Hoje, esses fluxos funcionam em ambiente local, com dados de teste. Ainda precisamos definir como o serviço será operado com contas, instituições e estoques reais.

## 1. Sobre o projeto

Quem procura água, alimentos ou itens de higiene precisa saber onde encontrar ajuda. Quem quer doar precisa saber quais pontos aceitam o recurso. Nossa proposta é reunir essas informações em uma consulta pública, alimentada por quem administra os pontos de distribuição.

No dia a dia, imaginamos três usos. A **população** consulta os recursos sem criar conta. O **gestor** mantém os dados dos pontos e registra o que entra e sai do estoque. A **Prefeitura** acompanha as instituições do próprio município e registra a situação da verificação de cada uma. Assim, cada perfil cuida de uma parte da informação que chega ao público.

## 2. O que já desenvolvemos

### Consulta pública

- A busca permite indicar se a pessoa procura ajuda ou quer doar. Os resultados levam à ficha do ponto, com endereço, região, horário, contato quando informado e recursos publicados. Quando há uma alternativa prevista e nenhuma correspondência direta atende aos filtros, a busca pode sugerir essa alternativa.
- A pessoa pode continuar sem compartilhar a localização. Se compartilhar, pode filtrar por distância. Essa distância é em linha reta, sem indicação de trajeto ou tempo de viagem.
- Na busca por ajuda, é possível mostrar apenas itens disponíveis. Na busca por doação, um ponto pode aparecer mesmo com saldo zero, desde que tenha publicado o item e aceite recebê-lo. O saldo exato só aparece quando o gestor autoriza sua divulgação.

### Acesso e gestão de pontos

- O acesso por e-mail e senha abre o painel correspondente ao perfil. Gestores veem os pontos das instituições às quais estão vinculados. A Prefeitura consulta as instituições do seu município. Já testamos contas de demonstração para os dois perfis.
- Em **Meus Pontos**, o gestor pode buscar por nome ou instituição, abrir o estoque e cadastrar ou editar pontos autorizados. Pode atualizar endereço, contato, horário e localização. Desativar um ponto o retira da consulta pública e preserva seu estoque e histórico.

### Estoque, movimentações e publicação

- Um ponto novo começa sem estoque. O gestor vincula um item do catálogo existente, que já indica a unidade de medida. O item começa com saldo zero e oculto do público. O painel permite buscar e filtrar itens sem saldo, ocultos ou disponíveis para distribuição.
- O gestor pode registrar **entrada, saída ou ajuste**. Antes da confirmação, o aplicativo mostra o saldo esperado. Se uma saída ultrapassar o saldo ou se outra pessoa alterar o estoque no meio da operação, o sistema impede que a movimentação seja salva com aqueles dados.
- O histórico mostra as movimentações mais recentes por item, com saldo anterior, saldo resultante e responsável. Na publicação, o gestor controla separadamente a visibilidade do item, a divulgação da quantidade, a distribuição e a aceitação de doações. Para o ponto aparecer ao público, ele também precisa estar ativo e sua instituição, verificada.

### Prefeitura

- O painel municipal lista as instituições do município, mostra quantas estão em cada situação e permite buscar, filtrar e priorizar as pendentes.
- A Prefeitura pode cadastrar uma instituição, que começa como **pendente**, e depois marcá-la como **verificada**, **suspensa** ou **pendente** novamente. Antes de confirmar, a tela explica o efeito na consulta pública e exige uma justificativa. O sistema guarda a decisão, mas o painel ainda não exibe o histórico dessas mudanças.

## 3. O que já está funcionando

Confirmamos os itens abaixo. Também conseguimos gerar a versão para navegador e revisamos capturas das telas administrativas em larguras de celular, tablet e computador (Grande beneficío de utilizar o flutter).

- [x] Buscar ajuda ou opções de doação sem conta, continuar sem localização e abrir a ficha pública de um ponto.
- [x] Entrar com as contas de teste de Gestor e Prefeitura e restringir operações conforme o perfil e os vínculos.
- [x] Cadastrar, editar e desativar pontos de distribuição autorizados.
- [x] Vincular itens do catálogo, registrar movimentações e consultar o saldo e o histórico.
- [x] Publicar um recurso e confirmar na busca pública que a quantidade pode ficar oculta.
- [x] Cadastrar uma instituição pendente e registrar mudanças de situação com justificativa no painel da Prefeitura.
- [x] Rodar o projeto localmente com dados de demonstração e recuperar uma cópia do banco em um ambiente de teste.

## 4. O que ainda falta desenvolver ou corrigir

- [ ] **Contas reais:** implementar os fluxos de convite ou cadastro, vínculo de gestores, retirada de acesso e recuperação de senha. O login já funciona com as contas criadas para teste.
- [ ] **Acompanhamento da Prefeitura:** permitir consultar no painel as decisões anteriores, com data, responsável e justificativa. O registro já existe, mas ainda não pode ser consultado pelo painel.
- [ ] **Catálogo de recursos:** definir e implementar a manutenção dos itens e unidades. Hoje o gestor escolhe itens que já existem no catálogo.

## 5. Tecnologias que estamos utilizando

- **Flutter e Dart:** usamos Flutter para construir as telas e Dart para programar o que acontece nelas. Isso permite manter a consulta pública e os dois painéis no mesmo aplicativo. A versão que demonstramos roda no navegador.
- **Node.js e Express:** mantêm em execução a parte do sistema que recebe pedidos das telas. É ali que conferimos, por exemplo, se o gestor tem permissão para alterar um estoque e se há saldo suficiente.
- **PostgreSQL:** é o banco de dados principal. 
- **Docker:** ajuda o Gabriel e a mim a iniciar o banco e a parte que processa as operações com a mesma configuração. 

## 6. Melhorias recentes

Começamos com a consulta pública e a gestão de estoques. Nas entregas seguintes, acrescentamos cadastro e edição de pontos, controles de publicação e proteção contra cadastros duplicados quando uma resposta se perde. Também ajustamos a busca para continuar sem localização e aplicar os filtros antes de escolher os resultados. Com o vínculo pelo catálogo, passamos a conseguir demonstrar um ponto novo desde o estoque vazio até a primeira publicação.

Depois, preparamos um pacote de avaliação local e conferimos esse percurso no navegador. Passamos a usar o PostgreSQL no ambiente principal e o Docker para facilitar a instalação. 
Colocamos a marca na página inicial e no ícone da aba do navegador(Uma logotipo improvisada). Na revisão dos painéis, reorganizamos o estoque para facilitar a comparação entre itens no computador e o uso no celular(Estamos pensando em deixar a parte de gestores apenas no computador). Também substituímos a mensagem de espera exibida às contas municipais por um painel que permite cadastrar, consultar e verificar instituições.

## 7. Decisões que ainda precisamos tomar

### Quem entrega, recupera e retira o acesso?

**O que já existe.** Temos perfis separados e acesso limitado por vínculo ou município. Ainda não temos um fluxo de gestão de contas para uso real.

**Opções.** A Prefeitura poderia convidar e desvincular gestores do próprio município, ou essas tarefas poderiam ficar com uma administração central. Também precisamos decidir quem autoriza contas da própria Prefeitura e se a recuperação será por e-mail verificado ou com atendimento de um responsável.

**Nossa avaliação.** Delegar parte do trabalho ao município aproxima a decisão de quem conhece as instituições. Centralizar ajuda a aplicar critérios iguais, mas pode aumentar o tempo de atendimento. Em ambos os casos, precisamos definir como confirmar a identidade e retirar o acesso quando alguém deixa a função.

### O que a Prefeitura deve conferir antes de verificar uma instituição?

**O que já existe.** A Prefeitura cadastra e altera a situação das instituições do próprio município, com justificativa. A verificação permite que pontos ativos sejam considerados na consulta pública.

**Opções.** Começar com uma conferência básica, como confirmar o contato e o local de atendimento, ou exigir documentação e um responsável formal antes de verificar. Esse critério provavelmente não será implementado, esse assunto já foi discutido em sala de aula.

### Quando vale a pena mostrar a quantidade disponível?

**O que já existe.** O gestor escolhe, item por item, se a população verá a quantidade exata. Sem esse dado, a consulta ainda informa se o recurso está disponível para distribuição.

**Opções.** Recomendar a quantidade exata quando o saldo puder ser mantido em dia, ou orientar que a disponibilidade seja suficiente na maioria dos casos, com exceções acordadas.

**Nossa avaliação.** Essa opção foi analisada e foi feito uma pesquisa sobre qual ação costuma ser o padrão para esse tipo de comportamento, isso será apresentado a você e assim tomaremos nossa decisão.



