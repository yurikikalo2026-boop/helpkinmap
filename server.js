const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const path = require('path');
const http = require('http');
const socketIO = require('socket.io');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') || '*',
    methods: ['GET', 'POST']
  }
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://unpkg.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://unpkg.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:", "blob:"],
      connectSrc: ["'self'", "https://unpkg.com", "https://*.tile.openstreetmap.org"]
    }
  }
}));

app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true
}));

app.use(compression());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: (process.env.RATE_LIMIT_WINDOW || 15) * 60 * 1000,
  max: process.env.RATE_LIMIT_MAX_REQUESTS || 100,
  message: 'Too many requests from this IP, please try again later.'
});

app.use('/api/', limiter);

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// SPA route fallback for client-side navigation
app.get(['/', '/login', '/register', '/dashboard'], (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ============================================
// Sample Data (In production, use a database)
// ============================================

let users = [];
let helpRequests = [];
let connections = [];
let messages = [];

// Sample users
users = [
  {
    id: '1',
    name: 'Олена Коваленко',
    email: 'olena@example.com',
    passwordHash: '$2b$10$examplehash',
    bio: 'Викладач англійської мови, з родиною переїхала до Німеччини у 2022 році.',
    location: { country: 'Germany', city: 'Berlin', lat: 52.520008, lng: 13.404954 },
    helpOffers: ['housing', 'language'],
    offerDetails: 'Можу допомогти з вивченням англійської та німецької мов. Маю досвід викладання 10+ років.',
    connections: ['2', '4', '5', '8'],
    createdAt: new Date('2022-03-15')
  },
  {
    id: '2',
    name: 'Андрій Мельник',
    email: 'andrii@example.com',
    passwordHash: '$2b$10$examplehash',
    bio: 'IT спеціаліст, працюю в міжнародній компанії.',
    location: { country: 'Poland', city: 'Warsaw', lat: 52.229676, lng: 21.012229 },
    helpOffers: ['job', 'language'],
    offerDetails: 'Можу допомогти з пошуком роботи в IT сфері та вивченням польської мови.',
    connections: ['1', '4', '5'],
    createdAt: new Date('2022-04-10')
  },
  {
    id: '3',
    name: 'Марія Шевченко',
    email: 'maria@example.com',
    passwordHash: '$2b$10$examplehash',
    bio: 'Медичний працівник, живу в Канаді 3 роки.',
    location: { country: 'Canada', city: 'Toronto', lat: 43.651070, lng: -79.347015 },
    helpOffers: ['housing', 'education', 'language'],
    offerDetails: 'Можу надати тимчасове житло та допомогти з адаптацією в Канаді.',
    connections: [],
    createdAt: new Date('2021-06-20')
  }
];

helpRequests = [
  {
    id: 'req1',
    authorId: '1',
    title: 'Потрібне тимчасове житло у Варшаві',
    description: 'Шукаю тимчасове житло для сім\'ї з 3 осіб на 2 тижні у Варшаві. Приїжджаємо 15 березня.',
    type: 'housing',
    location: { country: 'Poland', city: 'Warsaw' },
    status: 'open',
    visibility: 'network-only',
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    responses: []
  }
];

// ============================================
// API Routes
// ============================================

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Auth routes
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    
    // Validate input
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Check if user exists
    if (users.find(u => u.email === email)) {
      return res.status(409).json({ error: 'User already exists' });
    }
    
    // In production: hash password with bcrypt
    // const passwordHash = await bcrypt.hash(password, 10);
    
    const newUser = {
      id: String(Date.now()),
      name,
      email,
      passwordHash: 'hashed_password', // Replace with actual hash
      bio: '',
      location: { country: '', city: '', lat: 0, lng: 0 },
      helpOffers: [],
      offerDetails: '',
      connections: [],
      createdAt: new Date()
    };
    
    users.push(newUser);
    
    // In production: generate JWT token
    const token = 'jwt_token_here'; // Replace with actual JWT
    
    res.status(201).json({
      message: 'User registered successfully',
      user: { id: newUser.id, name: newUser.name, email: newUser.email },
      token
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'Missing credentials' });
    }
    
    const user = users.find(u => u.email === email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // In production: verify password with bcrypt
    // const isValid = await bcrypt.compare(password, user.passwordHash);
    
    // In production: generate JWT token
    const token = 'jwt_token_here';
    
    res.json({
      message: 'Login successful',
      user: { id: user.id, name: user.name, email: user.email },
      token
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// User routes
app.get('/api/users', (req, res) => {
  // Return users without sensitive data
  const publicUsers = users.map(({ passwordHash, ...user }) => user);
  res.json(publicUsers);
});

app.get('/api/users/:id', (req, res) => {
  const user = users.find(u => u.id === req.params.id);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  const { passwordHash, ...publicUser } = user;
  res.json(publicUser);
});

app.put('/api/users/:id', (req, res) => {
  // In production: verify JWT and ensure user can only update their own profile
  const userIndex = users.findIndex(u => u.id === req.params.id);
  
  if (userIndex === -1) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  const allowedUpdates = ['name', 'bio', 'location', 'helpOffers', 'offerDetails'];
  const updates = {};
  
  allowedUpdates.forEach(field => {
    if (req.body[field] !== undefined) {
      updates[field] = req.body[field];
    }
  });
  
  users[userIndex] = { ...users[userIndex], ...updates };
  
  const { passwordHash, ...updatedUser } = users[userIndex];
  res.json(updatedUser);
});

// Help Request routes
app.get('/api/help-requests', (req, res) => {
  const { type, status, visibility } = req.query;
  
  let filtered = helpRequests;
  
  if (type) filtered = filtered.filter(r => r.type === type);
  if (status) filtered = filtered.filter(r => r.status === status);
  if (visibility) filtered = filtered.filter(r => r.visibility === visibility);
  
  res.json(filtered);
});

app.post('/api/help-requests', (req, res) => {
  // In production: verify JWT
  const { title, description, type, location, visibility } = req.body;
  
  if (!title || !description || !type) {
    return res.status(400).json({ error: 'Missing required fields' });
  }
  
  const newRequest = {
    id: `req${Date.now()}`,
    authorId: '1', // Replace with actual user ID from JWT
    title,
    description,
    type,
    location: location || { country: '', city: '' },
    status: 'open',
    visibility: visibility || 'network-only',
    createdAt: new Date(),
    responses: []
  };
  
  helpRequests.push(newRequest);
  res.status(201).json(newRequest);
});

app.put('/api/help-requests/:id', (req, res) => {
  // In production: verify user owns the request
  const requestIndex = helpRequests.findIndex(r => r.id === req.params.id);
  
  if (requestIndex === -1) {
    return res.status(404).json({ error: 'Request not found' });
  }
  
  const allowedUpdates = ['title', 'description', 'status', 'location'];
  const updates = {};
  
  allowedUpdates.forEach(field => {
    if (req.body[field] !== undefined) {
      updates[field] = req.body[field];
    }
  });
  
  helpRequests[requestIndex] = { ...helpRequests[requestIndex], ...updates };
  res.json(helpRequests[requestIndex]);
});

// Connection routes
app.post('/api/connections', (req, res) => {
  const { userId2, relationship } = req.body;
  
  const newConnection = {
    id: `conn${Date.now()}`,
    userId1: '1', // Replace with actual user ID from JWT
    userId2,
    relationship: relationship || 'friend',
    status: 'pending',
    initiatedBy: '1',
    requestedAt: new Date()
  };
  
  connections.push(newConnection);
  res.status(201).json(newConnection);
});

app.put('/api/connections/:id', (req, res) => {
  const connectionIndex = connections.findIndex(c => c.id === req.params.id);
  
  if (connectionIndex === -1) {
    return res.status(404).json({ error: 'Connection not found' });
  }
  
  const { status } = req.body;
  if (status === 'accepted' || status === 'blocked') {
    connections[connectionIndex].status = status;
    connections[connectionIndex].acceptedAt = new Date();
    
    // Add to both users' connections list
    if (status === 'accepted') {
      const conn = connections[connectionIndex];
      const user1 = users.find(u => u.id === conn.userId1);
      const user2 = users.find(u => u.id === conn.userId2);
      
      if (user1 && !user1.connections.includes(conn.userId2)) {
        user1.connections.push(conn.userId2);
      }
      if (user2 && !user2.connections.includes(conn.userId1)) {
        user2.connections.push(conn.userId1);
      }
    }
  }
  
  res.json(connections[connectionIndex]);
});

// ============================================
// Socket.IO for Real-time Chat
// ============================================

const activeUsers = new Map(); // Map of userId -> socketId

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  // User authentication
  socket.on('authenticate', (userId) => {
    activeUsers.set(userId, socket.id);
    socket.userId = userId;
    
    // Notify user's connections
    const user = users.find(u => u.id === userId);
    if (user && user.connections) {
      user.connections.forEach(connId => {
        const connSocketId = activeUsers.get(connId);
        if (connSocketId) {
          io.to(connSocketId).emit('user-online', { userId });
        }
      });
    }
  });
  
  // Send message
  socket.on('send-message', (data) => {
    const { recipientId, content } = data;
    
    const message = {
      id: `msg${Date.now()}`,
      senderId: socket.userId,
      recipientId,
      content,
      sentAt: new Date()
    };
    
    messages.push(message);
    
    // Send to recipient if online
    const recipientSocketId = activeUsers.get(recipientId);
    if (recipientSocketId) {
      io.to(recipientSocketId).emit('new-message', message);
    }
    
    // Confirm to sender
    socket.emit('message-sent', message);
  });
  
  // Typing indicator
  socket.on('typing', (recipientId) => {
    const recipientSocketId = activeUsers.get(recipientId);
    if (recipientSocketId) {
      io.to(recipientSocketId).emit('user-typing', { userId: socket.userId });
    }
  });
  
  // Disconnect
  socket.on('disconnect', () => {
    if (socket.userId) {
      activeUsers.delete(socket.userId);
      
      // Notify connections
      const user = users.find(u => u.id === socket.userId);
      if (user && user.connections) {
        user.connections.forEach(connId => {
          const connSocketId = activeUsers.get(connId);
          if (connSocketId) {
            io.to(connSocketId).emit('user-offline', { userId: socket.userId });
          }
        });
      }
    }
    console.log('User disconnected:', socket.id);
  });
});

// ============================================
// Serve PWA
// ============================================

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ============================================
// Error Handling
// ============================================

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// ============================================
// Start Server
// ============================================

server.listen(PORT, () => {
  console.log(`
    ╔════════════════════════════════════════╗
    ║   Help Kin Map Server Running 🇺🇦      ║
    ║                                        ║
    ║   Port: ${PORT}                        ║
    ║   Environment: ${process.env.NODE_ENV || 'development'}              ║
    ║   URL: http://localhost:${PORT}        ║
    ║                                        ║
    ║   API: http://localhost:${PORT}/api    ║
    ║   WebSocket: ws://localhost:${PORT}    ║
    ╚════════════════════════════════════════╝
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
