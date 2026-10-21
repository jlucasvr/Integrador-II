import { randomBytes } from 'node:crypto';
import { writeFileSync } from 'node:fs';
import { openDatabase,seedDemo } from './database.js';
const db=openDatabase();
try {
  const password=randomBytes(18).toString('base64url');
  seedDemo(db,password);
  writeFileSync('data/demo-access.txt',`Somente desenvolvimento local.\nGestor: gestor@example.test\nPrefeitura: prefeitura@example.test\nSenha: ${password}\n`,{flag:'wx'});
  console.log('Dados fictícios criados. Credenciais locais em data/demo-access.txt (ignorado pelo Git).');
} finally { db.close(); }
