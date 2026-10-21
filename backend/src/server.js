import { openDatabase } from './database.js';
import { createApp } from './app.js';
const db=openDatabase(process.env.DB_PATH);
const origins=(process.env.CORS_ORIGINS??'').split(',').filter(Boolean);
const port=Number(process.env.PORT??3000);
const server=createApp(db,{allowedOrigins:origins}).listen(port,'127.0.0.1',()=>{
  console.log(`API local: http://127.0.0.1:${port}/api/v1/health`);
});
function shutdown(){server.close(()=>{db.close();process.exit(0);});}
process.on('SIGINT',shutdown);process.on('SIGTERM',shutdown);
