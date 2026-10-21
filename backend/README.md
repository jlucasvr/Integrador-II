# API da plataforma de apoio

Node.js 24+, Express 5 e SQLite. Banco persistente local em `data/apoio.sqlite`, criado na inicialização. Primeira versão para desenvolvimento da dupla; servidor escuta somente em `127.0.0.1`.

## Executar

No PowerShell, dentro da pasta `backend`:

```powershell
npm.cmd install
npm.cmd run seed
npm.cmd start
```

Neste computador, o banco demonstrativo já foi criado; use apenas `npm.cmd start`. Em uma instalação nova, execute `seed` somente uma vez num banco vazio. Cria instituições, pontos, catálogo, estoques e dois usuários fictícios. Não apaga nem substitui banco existente. As senhas aleatórias ficam em `data/demo-access.txt`, ignorado pelo Git. Não compartilhe esse arquivo ou publique as contas demonstrativas.

Saúde: `http://127.0.0.1:3000/api/v1/health`. Testes: `npm.cmd test` (banco isolado em memória; não altera dados locais).

## Conectar Flutter

Mantenha a API em um terminal. Em outro, na raiz do projeto:

```powershell
.\iniciar.ps1 -Api
```

Sem `-Api`, o front-end continua utilizando os dados fictícios embutidos. O banco também contém dados fictícios; a diferença é que busca e alterações passam pelo servidor e persistem.

## Endpoints públicos

| Método | Caminho após `/api/v1` | Função |
|---|---|---|
| GET | `/health` | Saúde do servidor |
| GET | `/points?q=agua&intent=help&location=Cidade%20Exemplo` | Busca pública |
| GET | `/points/:id` | Detalhes públicos |

Busca: `q` obrigatório; `intent=help` ou `donate`; `location` opcional filtra texto de região/endereço (trechos separados por vírgula precisam corresponder). `lat` e `lon` opcionais, informados juntos, calculam distância em linha reta, nunca rota. `radiusKm` exige coordenadas; `availableOnly=true` restringe distribuição disponível. Doação é filtrada por aceitação, não por saldo.

Resposta: `{ "data": [ { "point": {...}, "resource": {...}, "alternative": false } ], "meta": {...} }`.

Sem coordenadas, `distanceKm=null`. O Flutter ainda não envia coordenadas: use todas as distâncias. Não há geocodificação de endereço, e nomes/endereço/coordenadas do seed são ilustrativos.

Ordem: correspondências de item/categoria antes de alternativas; em cada grupo, disponível primeiro, depois distância (quando calculada) e nome. Alternativas só aparecem se não houver resultado direto que satisfaça os filtros. Vocabulário inicial explícito: água mineral → Água, comida → Alimentos, sabonete → Higiene, agasalho → Abrigo. Não há busca semântica.

## Autenticação e rotas privadas

`POST /auth/login`: `{ "email": "gestor@example.test", "password": "senha do arquivo local" }`. Resposta contém `data.token` e `data.expiresAt`.

Use `Authorization: Bearer TOKEN` nas demais rotas. Token aleatório, hash armazenado no banco, validade de 8 horas. Senhas usam scrypt com salt. Login limitado a 20 tentativas por IP em 15 minutos.

| Método | Caminho | Acesso |
|---|---|---|
| GET | `/auth/me` | Usuário autenticado |
| POST | `/auth/logout` | Invalida sessão |
| GET | `/manage/points` | Pontos do gestor |
| GET | `/manage/points/:id/stock` | Saldo real e versão do estoque do gestor |
| POST | `/manage/stocks/:id/movements` | Entrada, saída ou ajuste |
| GET | `/manage/stocks/:id/movements` | Últimas 100 movimentações |
| PATCH | `/manage/stocks/:id/publication` | Configuração pública do item |
| GET / POST | `/manage/institutions` | Prefeitura: listar/cadastrar instituição pendente |
| PATCH | `/manage/institutions/:id/verification` | Prefeitura da instituição: verificar/suspender |

Movimentação:

```json
{ "type": "exit", "quantity": 20, "expectedVersion": 0, "note": "Distribuição registrada" }
```

`entry` soma; `exit` subtrai; `adjustment` define a quantidade real encontrada. Apenas inteiros, unidade definida pelo catálogo (não misturar garrafas/litros). Entrada/saída positivas; ajuste permite zero. Obtenha `version` na consulta privada e envie como `expectedVersion`. Saldo e histórico são gravados na mesma transação. Conflito retorna 409: recarregue antes de confirmar novamente. Não repetir automaticamente uma movimentação após falha de rede sem consultar saldo/histórico. A interface bloqueia reenvio nessas situações e oferece conferência do estoque.

Publicação: enviar `public_quantity`, `visible`, `distributable`, `accepts_donation` (todos booleanos) e `expectedVersion`. Quantidade privada nunca aparece em endpoints públicos; disponibilidade exige saldo positivo e distribuição habilitada. Item invisível é omitido. Verificação: `{ "status": "verified", "note": "Justificativa da prefeitura" }`; mudanças são registradas com responsável e data.

Erros: `{ "error": { "code": "STALE_STOCK", "message": "..." } }`; 400 dados inválidos, 401 sessão, 403 permissão, 404 recurso inexistente, 409 conflito/saldo, 429 excesso de tentativas.

## Modelo e decisões

Prefeitura → instituições → pontos → estoque por item. Vínculos autorizam gestores por instituição. Um item tem categoria e unidade; cada ponto tem quantidade, publicação, distribuição e aceitação independentes. Movimentações guardam antes/depois/responsável. Instituição pendente ou suspensa não aparece publicamente.

SQLite foi escolhido para iniciar sem servidor de banco adicional. Tem esquema relacional, restrições e transações. PostgreSQL poderá ser avaliado para implantação com múltiplas instâncias; não há migração automática para ele nesta entrega. Esquema inicial está em `src/database.js`; futuras alterações precisam de migrações versionadas, preservando os dados.

Configuração via variáveis `PORT`, `DB_PATH`, `CORS_ORIGINS` (origens separadas por vírgula). Por padrão, o desenvolvimento aceita apenas origens HTTP de localhost/127.0.0.1 com porta. Cadastro automático de administrador não existe.

## Próximas etapas

- Telas Flutter de login, seleção de ponto, estoque, movimentação e histórico já implementadas. Veja GUIA_GESTAO.md na raiz.
- Convites com expiração e aceitação para vincular gestores; recuperação e confirmação de e-mail.
- CRUD de pontos, catálogo e equipe; contatos reais da instituição.
- Localização/geocodificação e mapa real.
- Paginação de busca/histórico, trilha de auditoria ampliada e migrações evolutivas.
- Para publicação: configuração de ambiente, HTTPS, backup/recuperação, contas reais e revisão dos critérios de verificação. Não expor esta demonstração diretamente como serviço público.

A prefeitura mantém a decisão de verificação; o endpoint não substitui a conferência dos critérios acordados pelo grupo/professor. Prevenção de riscos permanece com escopo a definir.


