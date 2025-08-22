const express = require('express');
const mysql = require('mysql2/promise');
const redis = require('redis');
const promClient = require('prom-client');
const helmet = require('helmet');
const cors = require('cors');
const winston = require('winston');

const app = express();
const PORT = process.env.PORT || 3000;

// MONITORING - Prometheus metrics
const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics();

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

// LOGGER
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: '/app/logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: '/app/logs/combined.log' }),
    new winston.transports.Console()
  ]
});

// MIDDLEWARE
app.use(helmet()); // Added for app security
app.use(cors());   // Added to enable CORS
app.use(express.json());

// Middleware to count response time
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
    httpRequestTotal
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .inc();
  });
  next();
});

// DATABASE CONNECTIONS

let mysqlConnection;
let redisClient;

async function initializeConnections() {
  try {
    // MySQL connection
    mysqlConnection = await mysql.createConnection({
      host: process.env.MYSQL_HOST || 'localhost',
      port: process.env.MYSQL_PORT || 3306,
      user: process.env.MYSQL_USER || 'root',
      password: process.env.MYSQL_PASSWORD || '',
      database: process.env.MYSQL_DATABASE || 'nodeapp'
    });
    
    logger.info('MySQL connected successfully');

    // Redis connection
    redisClient = redis.createClient({
      url: `redis://${process.env.REDIS_HOST || 'redis'}:${process.env.REDIS_PORT || 6379}`,
      socket: {
        reconnectStrategy: (retries) => Math.min(retries * 50, 1000)
      }
    });
    
    redisClient.on('error', (err) => {
      logger.error('Redis Client Error:', err);
    });

    redisClient.on('connect', () => {
      logger.info('Redis client connecting...');
    });

    redisClient.on('ready', () => {
      logger.info('Redis client ready');
    });
    
    await redisClient.connect();
    logger.info('Redis connected successfully');

  } catch (error) {
    logger.error('Database connection failed:', error);
    process.exit(1);
  }
}

// ROUTES

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Metrics endpoint for Prometheuss
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});

// Main page
app.get('/', async (req, res) => {
  try {
    // Test Redis cache
    const cacheKey = 'homepage_visits';
    let visits = await redisClient.get(cacheKey);
    visits = visits ? parseInt(visits) + 1 : 1;
    await redisClient.set(cacheKey, visits);

    // Test MySQL
    const [rows] = await mysqlConnection.execute(
      'SELECT COUNT(*) as total FROM users'
    );

    res.json({
      message: 'Hello from Docker Compose!',
      visits: visits,
      users_in_db: rows[0].total,
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    logger.error('Error in main route:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Endpoint for adding users
app.post('/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    
    if (!name || !email) {
      return res.status(400).json({ error: 'Name and email is required' });
    }

    const [result] = await mysqlConnection.execute(
      'INSERT INTO users (name, email, created_at) VALUES (?, ?, NOW())',
      [name, email]
    );

    // Clear Redis cache after adding new user
    await redisClient.del('users_list');

    res.status(201).json({
      id: result.insertId,
      name,
      email
    });
  } catch (error) {
    logger.error('Error creating user:', error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// List users from Redis cache
app.get('/users', async (req, res) => {
  try {
    const cacheKey = 'users_list';
    
    // Validate Redis cache
    let users = await redisClient.get(cacheKey);
    
    if (users) {
      logger.info('Serving users from cache');
      return res.json(JSON.parse(users));
    }

    // If user isn't present in cache, get user from db
    const [rows] = await mysqlConnection.execute(
      'SELECT id, name, email, created_at FROM users ORDER BY created_at DESC'
    );

    // Save in cache for 5 minutes
    await redisClient.setEx(cacheKey, 300, JSON.stringify(rows));
    
    logger.info('Serving users from database');
    res.json(rows);
  } catch (error) {
    logger.error('Error fetching users:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// ERROR HANDLING
app.use((err, req, res, next) => {
  logger.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// SERVER START
async function startServer() {
  try {
    await initializeConnections();
    
    app.listen(PORT, '0.0.0.0', () => {
      logger.info(`Server running on port ${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  if (mysqlConnection) await mysqlConnection.end();
  if (redisClient) await redisClient.quit();
  process.exit(0);
});

startServer();