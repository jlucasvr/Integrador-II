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

Na tela pública, clique em **Gestão**. Entre com `gestor@example.test`. A senha está no arquivo local `backend/data/demo-access.txt`. A conta demonstrativa administra os pontos da instituição do Centro de Apoio Central.

## Experimentar o fluxo

1. Em **Meus pontos**, cadastre um ponto ativo para testar e abra seu estoque.
2. Escolha **Vincular item do catálogo**, busque **Água potável** e selecione **Vincular**. Confira o saldo zero e o aviso de item oculto.
3. Abra **Movimentar**, escolha **Entrada**, informe uma quantidade e confirme. Confira o saldo anterior, o saldo resultante e o responsável em **Histórico**.
4. Em **Publicação**, habilite a exibição na consulta pública e a distribuição. Habilite a quantidade pública se quiser mostrá-la.
5. Volte à consulta pública e pesquise **Água potável**. Confira o ponto cadastrado e a disponibilidade nos resultados.

As alterações no aplicativo usam o banco local e persistem. Para experimentar sem alterar esse banco, os testes usam dados isolados.

**Entrada** soma; **saída** subtrai; **ajuste** define a quantidade real encontrada, inclusive zero. As unidades são fixas por item. Saída maior que o saldo é bloqueada. Conflito de versão ou falta de confirmação de uma operação exige conferir saldo/histórico antes de repetir.

## Sessão e permissões

A sessão é mantida em memória durante a navegação e dura no máximo 8 horas. Recarregar ou fechar o aplicativo exige novo login; não há armazenamento persistente do token no navegador nesta etapa. O botão Sair limpa a sessão local e tenta invalidá-la na API. Resposta 401 retorna à tela de login.

A consulta pública segue sem login. No modo sem API (`iniciar.ps1`), Gestão explica como iniciar o servidor. Contas da prefeitura são reconhecidas, mas o painel da prefeitura ainda não foi implementado.

## O que está pronto

Login, cadastro e edição de pontos, vínculo de itens do catálogo, configuração de publicação, movimentações com prévia de saldo, histórico e tratamento de sessão e conflitos.

Os dados iniciais são fictícios. Convites, recuperação de senha e painel da prefeitura seguem pendentes.

## Verificação

```powershell
.\iniciar.ps1 -Action check -Api
```

Executa análise, testes e compilação web no modo API. Há testes dos fluxos em larguras de celular e computador. O fluxo real cliente Flutter → API → SQLite foi verificado em um banco isolado.
