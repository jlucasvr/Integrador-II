# Próximas entregas

## Sprint 1 — Cadastro e edição de pontos

- Cadastro para instituições às quais o gestor está vinculado.
- Edição de nome, endereço, região, horário, contato e coordenadas.
- Ativação e desativação sem apagar estoque ou histórico.
- Validação no cliente e no servidor, autorização por instituição e controle de versão.
- Contato e região apresentados nos detalhes públicos.
- Novos pontos começam sem itens: a vinculação de itens do catálogo será uma próxima entrega.

## Sprint 2 — Publicação do estoque

- Configuração por item: visibilidade, quantidade pública, distribuição e doação.
- Prévia do efeito na consulta pública.
- Controle de versão compartilhado com as movimentações de estoque.
- Conflito ou resposta incerta exige voltar e recarregar antes de reenviar.

## Banco de dados

PostgreSQL é o banco escolhido para a implantação. O runtime desta entrega ainda
usa SQLite. A migração física será uma entrega específica: adaptar a camada de
persistência para operações assíncronas e transações PostgreSQL, criar migrações
versionadas, transferir os dados e executar a suíte contra o novo banco.
Não executar seed sobre o banco demonstrativo existente.

Nesta entrega, a evolução SQLite adiciona contato e versão dos pontos sem
remover registros existentes.

## Roteiro de conferência

1. Iniciar a API e entrar como gestor.
2. Em Meus pontos, cadastrar um ponto e editar os dados pelo ícone de lápis.
3. Abrir um ponto com estoque e escolher Publicação em um item.
4. Salvar as opções e repetir a busca pública com a API e `MOCK_SEARCH=false`.
5. Conferir visibilidade, quantidade, disponibilidade e doações.
6. Desativar um ponto e confirmar que ele sai da consulta pública.
