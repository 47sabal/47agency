const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();

// 1. Initialize Firebase Admin SDK
try {
  const serviceAccount = require("./serviceAccountKey.json");
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("🔒 Firebase Admin SDK Initialized Successfully.");
} catch (error) {
  console.error("❌ Critical Error: Failed to load serviceAccountKey.json. Ensure it exists in the root directory.");
  process.exit(1);
}

const app = express();
const server = http.createServer(app);

// 2. Configure Socket.io with CORS for Flutter integration
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.json());

// In-Memory Database for Parking Facilities (civil, dharahara, labim)
let parkingDatabase = {
  civil: {
    name: "Civil Mall Parking",
    totalSpots: 8,
    spotsFree: [true, false, true, true, false, true, false, true], // true = Free, false = Occupied
    ratePerHour: 50
  },
  dharahara: {
    name: "Dharahara Tower Parking",
    totalSpots: 10,
    spotsFree: [true, true, false, true, true, false, true, true, false, true],
    ratePerHour: 60
  },
  labim: {
    name: "Labim Mall Parking",
    totalSpots: 6,
    spotsFree: [false, false, true, true, false, true],
    ratePerHour: 80
  }
};

// --- SECURE AUTHENTICATION MIDDLEWARE ---
async function checkAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: "Unauthorized: Missing token." });
  }

  const token = authHeader.split(' ')[1];

  try {
    // Validate token against Firebase Auth servers
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken; // Attaches uid, email, etc. to req.user
    next();
  } catch (error) {
    console.error("Token verification failed:", error.message);
    return res.status(403).json({ success: false, message: "Forbidden: Invalid or expired token." });
  }
}

// --- API ENDPOINTS ---

// Get all parking facilities and statuses
app.get('/api/parking', (req, res) => {
  res.status(200).json({ success: true, data: parkingDatabase });
});

// Secure endpoint: Book a parking slot (Requires valid Firebase Auth Header)
app.post('/api/parking/:facilityId/book', checkAuth, (req, res) => {
  const { facilityId } = req.params;
  const { index } = req.body; // Spot index being booked
  const userId = req.user.uid; // Secured UID from Firebase

  const facility = parkingDatabase[facilityId];

  if (!facility) {
    return res.status(404).json({ success: false, message: "Facility not found." });
  }

  if (index < 0 || index >= facility.totalSpots) {
    return res.status(400).json({ success: false, message: "Invalid spot index." });
  }

  if (!facility.spotsFree[index]) {
    return res.status(400).json({ success: false, message: "Spot is already occupied." });
  }

  // Book the spot
  facility.spotsFree[index] = false;

  // Emit live WebSocket update to all connected Flutter apps
  io.emit('parkingUpdate', { facilityId, spotsFree: facility.spotsFree });

  console.log(`[Success] User ${userId} booked spot ${index} at ${facilityId}`);
  res.status(200).json({ 
    success: true, 
    message: `Spot ${index + 1} successfully booked at ${facility.name}!`,
    spotsFree: facility.spotsFree 
  });
});

// IoT Hardware simulation endpoint: Toggle spot state (ESP32 IR Sensor integration)
app.post('/api/parking/:facilityId/toggle', (req, res) => {
  const { facilityId } = req.params;
  const { index, isFree } = req.body;

  const facility = parkingDatabase[facilityId];
  if (!facility) return res.status(404).json({ success: false, message: "Facility not found." });

  facility.spotsFree[index] = isFree;

  // Push instant changes to UI clients
  io.emit('parkingUpdate', { facilityId, spotsFree: facility.spotsFree });

  console.log(`[IoT Signal] Facility ${facilityId} spot ${index} is now ${isFree ? 'Free' : 'Occupied'}`);
  res.status(200).json({ success: true, spotsFree: facility.spotsFree });
});

// --- SOCKET.IO REAL-TIME COMMUNICATION ---
io.on('connection', (socket) => {
  console.log(`📱 Client connected: ${socket.id}`);

  // Send current database state immediately upon connection
  socket.emit('initialState', parkingDatabase);

  socket.on('disconnect', () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 2001;
server.listen(PORT, () => {
  console.log(`🚀 SmartPark Server running on port ${PORT}`);
});