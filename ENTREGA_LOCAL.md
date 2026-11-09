# Plataforma de Apoio — avaliação local

Este pacote executa a interface web e a API no mesmo endereço local. A prévia inicia um banco SQLite em memória com dados fictícios. Ao encerrar o processo, as alterações dessa sessão são descartadas.

## Iniciar

Em um terminal PowerShell, dentro da pasta `backend` do pacote, execute:

```powershell
npm.cmd ci
npm.cmd run preview
```

O pacote requer Node.js 24 ou superior. `npm ci` instala as versões do lockfile e pode precisar de acesso ao registry. Depois da instalação, o servidor usa uma porta local livre. Abra o endereço exibido no terminal no Edge ou Chrome. O terminal também mostra a senha temporária do gestor de avaliação, gerada a cada execução.

## Roteiro de avaliação

1. Na tela inicial, confira o aviso **Avaliação local · dados fictícios**. Use **Buscar sem localização** para consultar **Água potável**. Abra um ponto e confira os detalhes.
2. Em **Gestão**, entre com `gestor@example.test` e a senha do terminal. Em **Meus pontos**, cadastre um ponto ativo para a instituição já vinculada. Exemplo de coordenadas sintéticas: latitude `-23.55` e longitude `-46.63`.
3. Abra o estoque do ponto e escolha **Vincular item do catálogo → Água potável**. Confira o saldo zero e o aviso de item oculto.
4. Em **Movimentar**, registre uma entrada de 7 unidades do catálogo e confira o resultado em **Histórico**.
5. Em **Publicação**, habilite a exibição e a distribuição. Para conferir o saldo na ficha pública, habilite também a quantidade pública. Volte à busca sem localização e procure o ponto pelo nome na lista de resultados de **Água potável**.
6. Desative o ponto na gestão e repita a busca. Confira que ele saiu da consulta pública e que seu saldo e histórico seguem acessíveis na gestão.
7. Repita a busca em uma janela estreita e navegue com `Tab`, `Shift+Tab` e `Enter`. Verifique se o foco está visível e se é possível continuar sem localização.

Use `Ctrl+C` para encerrar a prévia. Se o navegador mostrar erro de shader, reabra a URL acrescentando `/?rendering=software`.
