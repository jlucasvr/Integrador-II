# Sprint 4 — Corrigir a consulta pública

A sprint parte da [integração isolada da Sprint 3](sprint-03.md) e trata os três requisitos da busca pública.

| ID | Entrega | Como verificar |
|---|---|---|
| AP-401 | Raio e disponibilidade seguem com a consulta. A API aplica os filtros antes de selecionar o recurso e oferecer alternativas. Para ajuda, prefere um item disponível entre as correspondências elegíveis do ponto. | Os testes HTTP cobrem dois itens na mesma categoria, correspondência direta fora do raio, alternativa dentro do raio e doação sem saldo. Os testes Dart verificam os parâmetros enviados e a atualização ao trocar o filtro. |
| AP-402 | Coordenadas opcionais. Após falha de captura, **Buscar sem localização** preserva o termo e a intenção. O filtro de raio aparece depois de obter uma posição. | Com a API ligada, recuse o acesso à localização e continue sem GPS. Confirme os resultados e o aviso de distância indisponível. Reative a permissão e use **Usar minha localização** nos resultados para habilitar o raio. |
| AP-403 | A demonstração identifica os dados fictícios na tela inicial, nos resultados e nos detalhes. Nesse modo a consulta funciona sem GPS e sem raio. O build em modo API exige URL explícita. | Execute os dois comandos de build abaixo. Rode o aplicativo sem `-Api` para conferir o aviso demonstrativo. A chamada `-Action build -Api` com `API_BASE_URL` ausente deve falhar antes da compilação. |

```powershell
.\iniciar.ps1 -Action build -Api -ApiBaseUrl http://127.0.0.1:3000/api/v1
.\iniciar.ps1 -Action build
```

Para o teste manual da busca conectada, reinicie o backend e execute `iniciar.ps1 -Api`. O seed do SQLite continua ilustrativo. A demonstração embutida é independente do SQLite.

## Resultado

Os 17 testes Node, os 42 testes Flutter e a integração isolada passaram. A integração consultou a API sem coordenadas e confirmou distância ausente com quantidade pública oculta e recurso disponível. A análise Dart ficou sem apontamentos. Os builds em modo API e demonstração concluíram com o aviso preexistente sobre a fonte Cupertino. A revisão visual usou capturas dos widgets em 320 e 1280 px. A homologação manual em navegador permanece pendente.

A próxima sprint vincula o primeiro item do catálogo a um ponto novo. A decisão proposta é iniciar o vínculo com saldo zero e publicação desativada, com publicação explícita depois da primeira movimentação.
