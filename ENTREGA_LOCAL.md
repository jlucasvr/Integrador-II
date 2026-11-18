# Plataforma de Apoio — avaliação local

Este pacote executa a interface web e a API no mesmo endereço local. Por padrão, a prévia inicia SQLite em memória; para persistir as alterações, defina `PREVIEW_DB_PATH` com o caminho de um arquivo SQLite antes de executar. `PREVIEW_PORT` fixa a porta local, se desejado.

## Iniciar

Em um terminal PowerShell, dentro da pasta `backend` do pacote, execute:

```powershell
npm.cmd ci
npm.cmd run preview
```

O pacote requer Node.js 24 ou superior. `npm ci` instala as versões do lockfile e pode precisar de acesso ao registry. Depois da instalação, o servidor usa uma porta local livre. Abra o endereço exibido no terminal no Edge ou Chrome. O terminal também mostra a senha temporária do gestor de avaliação, gerada a cada execução.

## Roteiro de avaliação

1. Na tela inicial, confira o aviso **Avaliação local · dados fictícios**. Escolha **Preciso de ajuda**, busque **Água potável** e ative sua localização. Abra um ponto e confira os detalhes.
2. Em **Gestão**, entre com `gestor@example.test` e a senha exibida na primeira inicialização do banco. Em **Meus pontos**, selecione uma instituição de Rio Verde ou cadastre um ponto de teste. Exemplo de coordenadas sintéticas locais: latitude `-17.797` e longitude `-50.925`.
3. Abra o estoque do ponto e escolha **Vincular item do catálogo → Água potável**. Confira o saldo zero e o aviso de item oculto.
4. Em **Movimentar**, registre uma entrada de 7 unidades do catálogo e confira o resultado em **Histórico**.
5. Em **Publicação**, habilite a exibição e a distribuição. Para conferir a faixa do saldo na ficha pública, habilite também a quantidade pública. Volte à busca e procure o ponto pelo nome na lista de resultados de **Água potável**.
6. Desative o ponto na gestão e repita a busca. Confira que ele saiu da consulta pública e que seu saldo e histórico seguem acessíveis na gestão.
7. Repita a busca em uma janela estreita e navegue com `Tab`, `Shift+Tab` e `Enter`. Verifique se o foco está visível e se a busca só é liberada após capturar a localização.

Use `Ctrl+C` para encerrar a prévia. Se o navegador mostrar erro de shader, reabra a URL acrescentando `/?rendering=software`.
