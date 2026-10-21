# Gestão de estoque implementada

Projeto: `C:\Users\João\Documents\Projetos\Projeto Integrador 2`.

## Executar

Inicie ou reinicie a API no terminal do back-end:

```powershell
cd 'C:\Users\João\Documents\Projetos\Projeto Integrador 2\backend'
npm.cmd start
```

Em outro terminal:

```powershell
cd 'C:\Users\João\Documents\Projetos\Projeto Integrador 2'
.\iniciar.ps1 -Api
```

Na tela pública, clique em **Gestão**. Entre com `gestor@example.test`; a senha está no arquivo local `backend/data/demo-access.txt`. A conta gestora de demonstração administra somente o Centro de Apoio Central. Não compartilhe o arquivo de credenciais.

## Experimentar o fluxo

1. Entre e selecione Centro de Apoio Central.
2. Encontre Água potável no estoque e clique em Movimentar.
3. Escolha Entrada, informe uma quantidade e confira o saldo resultante antes de confirmar.
4. Abra Histórico e confira saldo anterior, saldo resultante e responsável.
5. Volte à consulta pública e refaça a busca para conferir a atualização.

As alterações no aplicativo usam o banco local e persistem. Para experimentar sem alterar esse banco, os testes usam dados isolados.

**Entrada** soma; **saída** subtrai; **ajuste** define a quantidade real encontrada, inclusive zero. As unidades são fixas por item. Saída maior que o saldo é bloqueada. Conflito de versão ou falta de confirmação de uma operação exige conferir saldo/histórico antes de repetir.

## Sessão e permissões

A sessão é mantida em memória durante a navegação e dura no máximo 8 horas. Recarregar ou fechar o aplicativo exige novo login; não há armazenamento persistente do token no navegador nesta etapa. O botão Sair limpa a sessão local e tenta invalidá-la na API. Resposta 401 retorna à tela de login.

A consulta pública segue sem login. No modo sem API (`iniciar.ps1`), Gestão explica como iniciar o servidor. Contas da prefeitura são reconhecidas, mas o painel da prefeitura ainda não foi implementado.

## O que está pronto

Login, seleção de pontos, pesquisa de itens no estoque, saldo e informações de publicação, entrada/saída/ajuste, prévia do saldo, histórico com responsável, logout e tratamento de sessão/conexão/conflitos.

Os dados iniciais são fictícios; mapa e contatos continuam demonstrativos. Alterar configurações públicas de um item pela interface, convites, recuperação de senha e painel da prefeitura continuam para as próximas etapas.

## Verificação

```powershell
.\iniciar.ps1 -Action check -Api
```

Executa análise, testes e compilação web no modo API. Há testes dos fluxos em larguras de celular e computador. O fluxo real cliente Flutter → API → SQLite foi verificado em um banco isolado.
