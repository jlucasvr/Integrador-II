# Sprint 3 — Consolidar a gestão

O trabalho parte do cadastro, da edição e da publicação descritos nas Sprints 1 e 2 em [SPRINTS.md](../../../SPRINTS.md). A Sprint 3 consolida esses fluxos sobre SQLite e acrescenta proteção no reenvio de cadastro.

| ID | Entrega | Como verificar |
|---|---|---|
| AP-301 | Integração Dart, Express e SQLite em porta efêmera, com dados sintéticos. A busca identifica o ponto pelo ID mesmo quando há vários resultados. | O comando abaixo valida cadastro, edição, desativação, entrada, histórico e publicação com quantidade oculta. |
| AP-302 | Validação de instituição, coordenadas e termo de busca antes das consultas. | A suíte HTTP espera `400` para entradas inválidas e `403` para uma instituição válida sem vínculo. |
| AP-303 | Cadastro com chave por gestor. O ponto e o registro da tentativa são gravados na mesma transação. | Os testes cobrem reenvio, concorrência, conflito de payload, isolamento de gestores, reversão de falha intermediária e abertura de bases SQLite v1 e v2. O teste Flutter cobre confirmação com a mesma chave e os mesmos dados. |

```powershell
.\iniciar.ps1 -Action integration
```

O comando usa SQLite em memória e requer as dependências do backend instaladas. Para o teste manual com o banco local, reinicie a API e abra o Flutter com `-Api`. A API atualiza o esquema para a versão 3 ao abrir o arquivo existente.

Com o formulário de cadastro aberto, uma resposta incerta oferece **Confirmar cadastro** e mantém os campos travados para repetir a mesma operação. Se fechar o formulário, confira a lista antes de abrir outro cadastro. Clientes da API que enviam `Idempotency-Key` recebem a proteção de reenvio. A mesma chave com dados diferentes retorna `409`.

## Resultado

Os 16 testes Node, os 41 testes Flutter e o teste de integração isolado passaram. A análise Dart ficou sem apontamentos. O build web em modo API foi concluído com o aviso preexistente sobre a fonte Cupertino. A verificação usou uma cópia temporária do Flutter e dados sintéticos. A homologação manual no navegador segue para a entrega final.

A Sprint 4 trata a seleção de recursos, a busca sem GPS e a distinção entre dados fictícios e dados da API. O primeiro vínculo de catálogo permanece na Sprint 5.
