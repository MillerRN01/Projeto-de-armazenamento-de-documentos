import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { createServer } from 'http';
import { config } from './config/environment';
import routes from './routes';
import { errorHandler } from './middleware/errorHandler';
import { WebSocketService } from './services/websocketService';
import { setupScheduledTasks } from './services/schedulerService';

// Cria a aplicação Express
const app = express();

// Cria servidor HTTP
const server = createServer(app);

// Inicializa WebSocket
WebSocketService.initialize(server);

// Middleware de segurança
app.use(helmet());

// Configuração CORS
app.use(cors({
  origin: process.env.FRONTEND_URL,
  credentials: true
}));

// Compressão de resposta
app.use(compression());

// Parse de JSON e form data
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Diretório de uploads
app.use('/uploads', express.static(config.UPLOAD_DIR));

// Rotas da API
app.use('/api', routes);

// Middleware de tratamento de erros
app.use(errorHandler);

// Inicia o servidor
const PORT = config.PORT;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  
  // Inicia tarefas agendadas
  setupScheduledTasks();
});

export default server;
