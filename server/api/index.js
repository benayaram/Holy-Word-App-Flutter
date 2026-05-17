// Holy Word Arena — Main Express Server
require('dotenv').config();
const dns = require('dns');

// Fix for MongoDB Atlas "querySrv ECONNREFUSED" error on some networks
if (dns.setServers) {
  dns.setServers(['8.8.8.8', '8.8.4.4']);
}
if (dns.setDefaultResultOrder) {
  dns.setDefaultResultOrder('ipv4first');
}

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const http = require('http');

const { connectDB, getDB } = require('../lib/db');
const { initFirebase } = require('../lib/auth');
const { initWebSocket } = require('../lib/websocket');

// --- Environment Variable Validation ---
const REQUIRED_ENV_VARS = ['MONGODB_URI', 'FIREBASE_SERVICE_ACCOUNT_BASE64'];
const missing = REQUIRED_ENV_VARS.filter((v) => !process.env[v]);
if (missing.length > 0 && !process.env.VERCEL) {
  console.error(`❌ Missing required environment variables: ${missing.join(', ')}`);
  process.exit(1);
}

// Route imports
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const questionRoutes = require('./routes/questions');
const battleRoutes = require('./routes/battles');
const tournamentRoutes = require('./routes/tournaments');
const sermonRoutes = require('./routes/sermons');
const memoryRoutes = require('./routes/memory');
const churchRoutes = require('./routes/churches');

const app = express();

// === Middleware ===
app.use(helmet({ contentSecurityPolicy: false }));
app.use(compression());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '1mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // max 200 requests per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// AI generation has stricter rate limit + larger body
const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 50, // 50 AI generations per hour per IP
  message: { error: 'AI generation limit reached. Try again later.' },
});
app.use('/api/questions/generate', aiLimiter);

// DB readiness middleware — returns 503 if DB is not yet connected
app.use('/api/', async (req, res, next) => {
  // Allow health check even without DB
  if (req.path === '/health') return next();
  try {
    try {
      getDB();
    } catch {
      await connectDB();
    }
    next();
  } catch (err) {
    console.error('Database connection failed on request:', err.message);
    res.status(503).json({ error: 'Service temporarily unavailable — database starting up' });
  }
});

// === Health Check ===
app.get('/api/health', (req, res) => {
  let dbReady = false;
  try { getDB(); dbReady = true; } catch { /* DB not ready */ }

  res.status(dbReady ? 200 : 503).json({
    status: dbReady ? 'ok' : 'starting',
    service: 'Holy Word Arena API',
    version: '1.0.0',
    database: dbReady ? 'connected' : 'connecting',
    timestamp: new Date().toISOString(),
  });
});

// === Landing Page ===
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Holy Word Arena Server</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f4f7f6; color: #333; }
        .container { text-align: center; padding: 3rem; background: white; border-radius: 16px; box-shadow: 0 10px 30px rgba(0,0,0,0.05); max-width: 500px; }
        h1 { color: #2c3e50; margin-bottom: 1rem; font-size: 2rem; }
        p { color: #7f8c8d; line-height: 1.6; font-size: 1.1rem; }
        .status { margin-top: 2rem; display: inline-block; padding: 0.6rem 1.2rem; background: #e8f8f5; color: #1abc9c; border-radius: 30px; font-weight: bold; font-size: 0.95rem; }
        .pulse { display: inline-block; width: 8px; height: 8px; background-color: #1abc9c; border-radius: 50%; margin-right: 8px; animation: pulse 1.5s infinite; }
        @keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(26, 188, 156, 0.7); } 70% { box-shadow: 0 0 0 10px rgba(26, 188, 156, 0); } 100% { box-shadow: 0 0 0 0 rgba(26, 188, 156, 0); } }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Holy Word Arena API</h1>
        <p>The backend server is up and running successfully. Ready to power the Holy Word Arena application.</p>
        <div class="status"><span class="pulse"></span>Server Online</div>
      </div>
    </body>
    </html>
  `);
});

// === API Routes ===
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/battles', battleRoutes);
app.use('/api/tournaments', tournamentRoutes);
app.use('/api/sermons', sermonRoutes);
app.use('/api/memory', memoryRoutes);
app.use('/api/churches', churchRoutes);

// === 404 Handler ===
app.use('/api/*', (req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// === Error Handler (production-safe) ===
app.use((err, req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Internal server error'
      : err.message,
  });
});

// === Server Startup ===
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // Initialize Firebase Admin
    initFirebase();

    // Connect to MongoDB
    await connectDB();

    // Create HTTP server
    const server = http.createServer(app);

    // Initialize WebSocket
    initWebSocket(server);

    server.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════════╗
║   Holy Word Arena API Server               ║
║   Running on port ${PORT}                      ║
║   Environment: ${process.env.NODE_ENV || 'development'}              ║
╚════════════════════════════════════════════╝
      `);
    });

    // Graceful shutdown
    process.on('SIGTERM', async () => {
      console.log('SIGTERM received, shutting down...');
      const { closeDB } = require('../lib/db');
      await closeDB();
      server.close(() => process.exit(0));
    });

  } catch (err) {
    console.error('❌ Server startup failed:', err);
    process.exit(1);
  }
}

// For Vercel serverless: export the app
// For local dev: start the server
if (process.env.VERCEL) {
  module.exports = app;
} else {
  startServer();
}
