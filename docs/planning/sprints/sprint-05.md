# Sprint 5 — Operar um ponto novo

O fluxo começa em um ponto cadastrado pelo gestor e usa o catálogo existente. O primeiro item é vinculado com saldo zero e fica oculto até uma publicação explícita.

| ID | Entrega | Como verificar |
|---|---|---|
| AP-501 | Rotas autenticadas para listar os itens ainda disponíveis e vincular um deles. O servidor define o estado inicial e preserva a unidade do catálogo. | A suíte HTTP cobre item inexistente, ponto sem autorização, dois vínculos concorrentes e preservação do saldo em caso de duplicidade. |
| AP-502 | A ação **Vincular item do catálogo** aparece no estoque vazio e no estoque já iniciado. A lista permite buscar por nome e categoria. | Os testes Flutter cobrem carregamento, vínculo em tela estreita e desktop, falha de leitura e recuperação após vínculo concorrente. |
| AP-503 | O teste de integração valida o percurso de um ponto novo à consulta pública. | O item oculto fica fora da busca. Após entrada e publicação, o recurso aparece disponível. Desativar o ponto o retira da busca e preserva saldo e histórico. |

## Conferir localmente

Reinicie a API e execute `iniciar.ps1 -Api`. O fluxo usa as tabelas existentes do SQLite. Em **Meus pontos**, cadastre um ponto ativo e abra seu estoque. Vincule **Água potável**, registre a primeira entrada, habilite a visibilidade e a distribuição em **Publicação** e procure o recurso na busca pública.

Para verificar o fluxo com banco descartável, execute na raiz do projeto:

```powershell
.\iniciar.ps1 -Action integration
```

## Resultado

Os 18 testes Node, os 45 testes Flutter e a integração isolada passaram. A análise Dart ficou sem apontamentos. O build web em modo API concluiu com o aviso preexistente da fonte Cupertino. A revisão visual usou capturas dos widgets em 320 e 1280 px. A homologação em navegador e a instalação reproduzível ficam para a Sprint 6.
