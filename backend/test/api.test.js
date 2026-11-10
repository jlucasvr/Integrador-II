import { testDatabase } from './support/database.js';
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createApp } from '../src/app.js';

const db = await testDatabase('test-password-not-for-deployment');
const server=createApp(db).listen(0,'127.0.0.1');
let base,manager,admin;
async function request(path,{method='GET',token,body,...rest}={}) {
  const response=await fetch(base+path,{method,headers:{'Content-Type':'application/json',
    ...(token?{Authorization:`Bearer ${token}`}:{})},...(body?{body:JSON.stringify(body)}:{}),...rest});
  const raw=await response.text();return {status:response.status,body:raw?JSON.parse(raw):null};
}
before(async()=>{
  if(!server.listening) await once(server,'listening');
  base=`http://127.0.0.1:${server.address().port}/api/v1`;
  manager=(await request('/auth/login',{method:'POST',body:{email:'gestor@example.test',password:'test-password-not-for-deployment'}})).body.data.token;
  admin=(await request('/auth/login',{method:'POST',body:{email:'prefeitura@example.test',password:'test-password-not-for-deployment'}})).body.data.token;
});
after(async()=>{server.closeAllConnections();await new Promise(resolve=>server.close(resolve));await db.close();});

test('consulta pública oculta saldo privado e calcula distância somente com coordenadas',async()=>{
  const result=await request('/points?q=agua');
  assert.equal(result.status,200);
  const hidden=result.body.data.find(h=>h.point.id==='norte');
  assert.equal(hidden.resource.publicQuantity,null);
  assert.equal(hidden.resource.available,true);
  assert.equal(hidden.point.distanceKm,null);
  assert.equal(JSON.stringify(result.body).includes('password_hash'),false);
  assert.equal(JSON.stringify(hidden).includes('"quantity"'),false);
  const located=await request('/points?q=agua&lat=-23.55&lon=-46.63');
  assert.equal(located.body.data.find(h=>h.point.id==='central').point.distanceKm,0);
});
test('doação aceita independe de estoque disponível',async()=>{
  const r=await request('/points?q=agua&intent=donate');
  assert.equal(r.body.data.find(h=>h.point.id==='sul').resource.acceptsDonation,true);
  assert.equal(r.body.data.find(h=>h.point.id==='sul').resource.available,false);
});
test('alternativas e lista vazia não inventam correspondências',async()=>{
  const r=await request('/points?q=agua%20mineral');
  assert.ok(r.body.data.length>0);
  assert.ok(r.body.data.every(h=>h.alternative));
  assert.deepEqual((await request('/points?q=medicamento')).body.data,[]);
  assert.equal((await request('/points?q=agua&location=Centro%2C%20Cidade%20Exemplo')).body.meta.total,1);
});
test('seleção por ponto respeita disponibilidade, raio e intenção antes das alternativas', async (t) => {
  const item = (...values) => db.run('INSERT INTO items(id,name,category,unit) VALUES (?,?,?,?)', ...values);
  const stock = (...values) => db.run('INSERT INTO stocks(id,point_id,item_id,quantity,updated_at) VALUES (?,?,?,0,?)', ...values);
  t.after(() => db.exec(`
    DELETE FROM stocks WHERE id IN ('test-filtered', 'test-mineral');
    DELETE FROM items WHERE id IN ('test-filtered', 'test-mineral');
  `));
  await item('test-filtered', 'Água filtrada', 'Água', 'litros');
  await item('test-mineral', 'Água mineral', 'Água', 'garrafas');
  const timestamp = new Date().toISOString();
  await stock('test-filtered', 'central', 'test-filtered', timestamp);
  await stock('test-mineral', 'norte', 'test-mineral', timestamp);

  for (const filter of ['', '&availableOnly=true']) {
    const { body } = await request(`/points?q=agua${filter}`);
    assert.equal(body.data.find(hit => hit.point.id === 'central').resource.id, 'central-water');
  }
  const direct = await request('/points?q=agua%20mineral');
  assert.deepEqual(direct.body.data.map(hit => [hit.point.id, hit.alternative]), [['norte', false]]);
  const near = await request('/points?q=agua%20mineral&lat=-23.55&lon=-46.63&radiusKm=0.5&availableOnly=true');
  assert.deepEqual(near.body.data.map(hit => [hit.point.id, hit.resource.id, hit.alternative]),
    [['central', 'central-water', true]]);
  const donation = await request('/points?q=agua%20mineral&intent=donate&availableOnly=true');
  assert.equal(donation.body.data[0].resource.id, 'test-mineral');
  assert.equal(donation.body.data[0].resource.available, false);
});
test('validação rejeita coordenadas e filtros inválidos',async()=>{
  for(const query of ['lat=999&lon=0','lat=0','lat=%20&lon=%20','lat=0&lat=0&lon=0','radiusKm=2','intent=admin','availableOnly=1']) {
    assert.equal((await request(`/points?q=agua&${query}`)).status,400);
  }
  assert.equal((await request('/points?q=%CC%81')).status,400);
});
test('preflight local permite a chave de reenvio de cadastro', async () => {
  const response = await fetch(`${base}/manage/points`, {
    method: 'OPTIONS',
    headers: {
      Origin: 'http://localhost:8080',
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'authorization,content-type,idempotency-key',
    },
  });
  assert.equal(response.status, 204);
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:8080');
  assert.match(response.headers.get('access-control-allow-headers'), /\bIdempotency-Key\b/i);
});
test('rotas privadas exigem sessão e vínculo com a instituição',async()=>{
  assert.equal((await request('/manage/points/central/stock')).status,401);
  assert.equal((await request('/manage/points/norte/stock',{token:manager})).status,403);
  assert.equal((await request('/manage/institutions',{token:manager})).status,403);
  assert.equal((await request('/auth/login',{method:'POST',body:{email:'gestor@example.test',password:'wrong'}})).status,401);
  const r=await request('/manage/points/central/stock',{token:manager});
  assert.equal(r.status,200);assert.equal(r.body.data.find(s=>s.id==='central-water').quantity,120);
});
test('saída excedente é rejeitada sem alterar saldo ou histórico',async()=>{
  const r=await request('/manage/stocks/central-water/movements',{method:'POST',token:manager,
    body:{type:'exit',quantity:121,expectedVersion:0}});
  assert.equal(r.status,409);assert.equal(r.body.error.code,'INSUFFICIENT_STOCK');
  assert.equal((await db.get('SELECT quantity FROM stocks WHERE id=?', 'central-water')).quantity,120);
  assert.equal(Number((await db.get('SELECT COUNT(*) AS n FROM movements')).n),0);
});
test('saídas concorrentes com o mesmo saldo permitem somente uma confirmação',async()=>{
  const results=await Promise.all([1,2].map(()=>request('/manage/stocks/central-water/movements',{
    method:'POST',token:manager,body:{type:'exit',quantity:80,expectedVersion:0}})));
  assert.deepEqual(results.map(r=>r.status).sort(),[201,409]);
  assert.equal((await db.get('SELECT quantity FROM stocks WHERE id=?', 'central-water')).quantity,40);
  assert.equal(Number((await db.get('SELECT COUNT(*) AS n FROM movements')).n),1);
});
test('ajuste define o saldo real e grava responsável no histórico',async()=>{
  const r=await request('/manage/stocks/central-water/movements',{method:'POST',token:manager,
    body:{type:'adjustment',quantity:20,expectedVersion:1,note:'Contagem física'}});
  assert.equal(r.status,201);assert.equal(r.body.data.resultingBalance,20);
  const history=await request('/manage/stocks/central-water/movements',{token:manager});
  assert.equal(history.body.data[0].user_id,'demo-manager');
  assert.equal(history.body.data[0].previous_balance,40);
});
test('somente a prefeitura pode verificar e suspensão remove o ponto da consulta pública',async()=>{
  const body={status:'suspended',note:'Verificação de teste'};
  assert.equal((await request('/manage/institutions/inst-sul/verification',{method:'PATCH',token:manager,body})).status,403);
  assert.equal((await request('/manage/institutions/inst-sul/verification',{method:'PATCH',token:admin,body})).status,200);
  assert.equal((await request('/points/sul')).status,404);
  assert.ok(!(await request('/points?q=agua')).body.data.some(h=>h.point.id==='sul'));
});
test('prefeitura cadastra instituição pendente e não acessa outra prefeitura', async () => {
  await db.run("INSERT INTO municipalities VALUES ('other-city','Outra cidade')");
  await db.run("INSERT INTO institutions VALUES ('other-inst','Outra instituição','other-city','pending')");
  assert.equal((await request('/manage/institutions', { method: 'POST', token: manager, body: { name: 'Sem acesso' } })).status, 403);
  const created = await request('/manage/institutions', { method: 'POST', token: admin, body: { name: 'Nova instituição' } });
  assert.equal(created.status, 201);
  assert.equal(created.body.data.status, 'pending');
  const institutions = (await request('/manage/institutions', { token: admin })).body.data;
  assert.ok(institutions.some((i) => i.id === created.body.data.id));
  assert.ok(!institutions.some((i) => i.id === 'other-inst'));
  const denied = await request('/manage/institutions/other-inst/verification', {
    method: 'PATCH', token: admin, body: { status: 'verified', note: 'Fora do município' },
  });
  assert.equal(denied.status, 404);
  assert.equal((await db.get("SELECT status FROM institutions WHERE id='other-inst'")).status, 'pending');
});
test('publicação exige versão e nunca entrega quantidade privada',async()=>{
  const body={public_quantity:false,visible:true,distributable:true,accepts_donation:true,expectedVersion:2};
  assert.equal((await request('/manage/stocks/central-water/publication',{method:'PATCH',token:manager,body})).status,200);
  const point=(await request('/points/central')).body.data;
  assert.equal(point.resources.find(r=>r.id==='central-water').publicQuantity,null);
  assert.equal((await request('/manage/stocks/central-water/publication',{method:'PATCH',token:manager,body})).status,409);
});
test('logout invalida o token e origem externa é bloqueada',async()=>{
  assert.equal((await request('/health',{headers:{Origin:'https://untrusted.example'}})).status,403);
  assert.equal((await request('/auth/logout',{method:'POST',token:manager})).status,204);
  assert.equal((await request('/auth/me',{token:manager})).status,401);
});
