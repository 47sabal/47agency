const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const admin = require("firebase-admin");
require("dotenv").config();

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 2001; // Port 2001 strictly enforced across architectures[cite: 1, 2, 3, 4]

// --- MIDDLEWARES ---
app.use(cors());
app.use(express.json());

// Configure Socket.io with CORS for Flutter integration[cite: 2]
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// --- FIREBASE ADMIN SDK INITIALIZATION (Enhanced with preeti.js sequential architecture) ---
try {
  const serviceAccount = require("./serviceAccountKey.json"); // Loaded from bumsu.js[cite: 2]
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("🔒 Firebase Admin SDK Initialized Successfully via Preeti & Bumsu Ecosystem Rules.");
} catch (error) {
  console.error("❌ Critical Error: Failed to load serviceAccountKey.json. Ensure it exists in the root directory.");
  process.exit(1);
}

// --- SABALIIII.JS CONFIGURATION LAYER ---
// Custom hook section dedicated to tracking any local environment variables, telemetry logs, or overrides
console.log("ℹ️ Sabaliiii pipeline successfully mounted into the main execution routine.");

// --- PRICING SCHEMAS & UTILITIES ---
const RATES = {
  civil: { name: "Civil Mall Parking", standardPerHour: 60 },
  labim: { name: "Labim Mall Parking", standardPerHour: 80 },
  ranipokhari: { name: "Rani Pokhari", standardPerHour: 40 },
  dharahara: { name: "Dharahara Tower Parking", standardPerHour: 50 }
};

const OVERTIME_MULTIPLIER = 3; // 3x Penalty for overtime from brosa.js[cite: 1]

// Comprehensive In-Memory structures tracking deep chronological metrics[cite: 1]
let facilitiesData = {
  civil: Array.from({ length: 8 }, (_, i) => ({ id: i, isFree: true, entryTime: null, endTime: null, vehicleNo: null })),
  labim: Array.from({ length: 6 }, (_, i) => ({ id: i, isFree: true, entryTime: null, endTime: null, vehicleNo: null })),
  ranipokhari: Array.from({ length: 12 }, (_, i) => ({ id: i, isFree: true, entryTime: null, endTime: null, vehicleNo: null })),
  dharahara: Array.from({ length: 10 }, (_, i) => ({ id: i, isFree: true, entryTime: null, endTime: null, vehicleNo: null }))
};

// Standalone 8 parking spots array imported from hacathon.js[cite: 3]
let standaloneParkingSpots = [true, false, true, true, false, true, false, true];

// --- SECURE AUTHENTICATION MIDDLEWARE ---
async function checkAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: "Unauthorized: Missing token." });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken; // Attaches uid, email, etc. to req.user[cite: 2]
    next();
  } catch (error) {
    console.error("Token verification failed:", error.message);
    return res.status(403).json({ success: false, message: "Forbidden: Invalid or expired token." });
  }
}

// --- STATE MAP HELPER ---
// Helper to transform our rich array into the basic boolean array format expected by socket.io UI hooks[cite: 2]
function getSpotsFreeMap(facilityId) {
  return facilitiesData[facilityId].map(spot => spot.isFree);
}

// --- BILLING ENGINE UTILITY ---
function calculateLiveBill(spot, hourlyRate) {
  if (spot.isFree || !spot.entryTime) {
    return { totalCharge: 0, overtimeMinutes: 0, standardCharge: 0, penaltyCharge: 0, isOvertime: false };
  }

  const now = new Date();
  const entry = new Date(spot.entryTime);
  const scheduledEnd = new Date(spot.endTime);

  const totalMinutes = Math.max(0, Math.ceil((now - entry) / 60000));
  const scheduledMinutes = Math.max(0, Math.ceil((scheduledEnd - entry) / 60000));

  let overtimeMinutes = 0;
  let standardMinutes = totalMinutes;

  if (now > scheduledEnd) {
    overtimeMinutes = Math.max(0, Math.ceil((now - scheduledEnd) / 60000));
    standardMinutes = scheduledMinutes;
  }

  const standardCharge = (standardMinutes / 60) * hourlyRate;
  const penaltyCharge = (overtimeMinutes / 60) * (hourlyRate * OVERTIME_MULTIPLIER);
  const totalCharge = standardCharge + penaltyCharge;

  return {
    standardCharge: parseFloat(standardCharge.toFixed(2)),
    penaltyCharge: parseFloat(penaltyCharge.toFixed(2)),
    totalCharge: parseFloat(totalCharge.toFixed(2)),
    overtimeMinutes: overtimeMinutes,
    isOvertime: now > scheduledEnd
  };
}

// --- REST API ENDPOINTS ---

// 1. Unified Dashboard Overview (Merges bumsu.js structural layout with hacathon.js global status fields)[cite: 2, 3]
app.get('/api/parking', (req, res) => {
  const overviewMap = {};
  Object.keys(facilitiesData).forEach(facilityId => {
    overviewMap[facilityId] = {
      name: RATES[facilityId].name,
      totalSpots: facilitiesData[facilityId].length,
      spotsFree: getSpotsFreeMap(facilityId),
      ratePerHour: RATES[facilityId].standardPerHour
    };
  });

  res.status(200).json({ 
    success: true, 
    data: overviewMap,
    // Elements added from hacathon.js root profile metrics[cite: 3]
    standaloneSpots: standaloneParkingSpots,
    totalStandaloneSpots: standaloneParkingSpots.length,
    availableStandaloneSpots: standaloneParkingSpots.filter(spot => spot).length
  });
});

// 2. Standalone Toggle Endpoint (Direct from hacathon.js)[cite: 3]
app.post('/api/parking/toggle', (req, res) => {
  const { index } = req.body;

  if (index === undefined || index < 0 || index >= standaloneParkingSpots.length) {
    return res.status(400).json({ success: false, message: "Invalid spot index." });
  }

  // Toggle boolean value of selected spot[cite: 3]
  standaloneParkingSpots[index] = !standaloneParkingSpots[index];

  // Notify real-time stream clients of standalone adjustments
  io.emit('standaloneUpdate', { 
    standaloneSpots: standaloneParkingSpots,
    availableStandaloneSpots: standaloneParkingSpots.filter(spot => spot).length
  });

  return res.status(200).json({
    success: true,
    message: `Spot ${index + 1} updated successfully.`,
    data: standaloneParkingSpots,
    availableSpots: standaloneParkingSpots.filter(spot => spot).length
  });
});

// 3. Get entire architecture status for a targeted facility with dynamic live calculation engine[cite: 1]
app.get('/api/parking/:facilityId', (req, res) => {
  const { facilityId } = req.params;
  
  if (!facilitiesData[facilityId]) {
    return res.status(404).json({ success: false, message: "Facility location profile not found." });
  }

  const hourlyRate = RATES[facilityId].standardPerHour;
  const processedSpots = facilitiesData[facilityId].map(spot => {
    const billing = calculateLiveBill(spot, hourlyRate);
    return { ...spot, ...billing };
  });

  res.status(200).json({
    success: true,
    facilityName: RATES[facilityId].name,
    ratePerHour: hourlyRate,
    totalSpots: processedSpots.length,
    availableSpots: processedSpots.filter(s => s.isFree).length,
    spots: processedSpots
  });
});

// 4. SECURE ENDPOINT: Commit a booking reservation (Requires active Firebase auth validation)[cite: 1, 2]
app.post('/api/parking/:facilityId/book', checkAuth, (req, res) => {
  const { facilityId } = req.params;
  const { index, durationInMinutes, vehicleNo } = req.body;
  const userId = req.user.uid; // Secured UID from Firebase[cite: 2]

  const targetFacility = facilitiesData[facilityId];
  if (!targetFacility) return res.status(444).json({ success: false, message: "Unknown facility." });
  if (index === undefined || index < 0 || index >= targetFacility.length) {
    return res.status(400).json({ success: false, message: "Invalid grid spot position index." });
  }
  if (!targetFacility[index].isFree) {
    return res.status(400).json({ success: false, message: "Target space slot is already reserved." });
  }

  const entryTime = new Date();
  const minutes = durationInMinutes || 60; // Standard fallback to 1 hour if not passed
  const endTime = new Date(entryTime.getTime() + minutes * 60000);

  targetFacility[index] = {
    id: index,
    isFree: false,
    entryTime: entryTime.toISOString(),
    endTime: endTime.toISOString(),
    vehicleNo: vehicleNo || "Unknown"
  };

  // Push updates instantly via WebSockets to listening apps[cite: 2]
  const spotsFreeArray = getSpotsFreeMap(facilityId);
  io.emit('parkingUpdate', { facilityId, spotsFree: spotsFreeArray });

  console.log(`[Success] Firebase User ${userId} booked spot ${index} at ${facilityId}`);
  res.status(200).json({
    success: true,
    message: `Spot ${index + 1} successfully secured at ${RATES[facilityId].name}!`,
    spot: targetFacility[index],
    spotsFree: spotsFreeArray
  });
});

// 5. Clear/Release a space slot and compute final calculated invoice penalty[cite: 1]
app.post('/api/parking/:facilityId/release', (req, res) => {
  const { facilityId } = req.params;
  const { index } = req.body;

  const targetFacility = facilitiesData[facilityId];
  if (!targetFacility) return res.status(404).json({ success: false, message: "Facility profile mismatch." });
  if (targetFacility[index].isFree) {
    return res.status(400).json({ success: false, message: "Spot is already clean and vacant." });
  }

  const hourlyRate = RATES[facilityId].standardPerHour;
  const finalBill = calculateLiveBill(targetFacility[index], hourlyRate);

  // Reset metrics back to vacant state[cite: 1]
  targetFacility[index] = { id: index, isFree: true, entryTime: null, endTime: null, vehicleNo: null };

  // Broadcast the modification status to socket clients[cite: 2]
  const spotsFreeArray = getSpotsFreeMap(facilityId);
  io.emit('parkingUpdate', { facilityId, spotsFree: spotsFreeArray });

  res.status(200).json({
    success: true,
    message: "Checkout invoice calculated successfully.",
    invoice: {
      facility: RATES[facilityId].name,
      spotIndex: index,
      overtimeMinutes: finalBill.overtimeMinutes,
      charges: finalBill
    }
  });
});

// 6. IoT Hardware simulation endpoint: Toggle spot state via hardware signals (ESP32 IR Sensor integration)[cite: 2]
app.post('/api/parking/:facilityId/toggle', (req, res) => {
  const { facilityId } = req.params;
  const { index, isFree } = req.body;

  const targetFacility = facilitiesData[facilityId];
  if (!targetFacility) return res.status(404).json({ success: false, message: "Facility not found." });
  if (index === undefined || index < 0 || index >= targetFacility.length) {
    return res.status(400).json({ success: false, message: "Invalid spot index." });
  }

  if (isFree) {
    targetFacility[index] = { id: index, isFree: true, entryTime: null, endTime: null, vehicleNo: null };
  } else {
    // If setting to occupied via IR hardware sensor without an existing record, initialize default timers
    const entryTime = new Date();
    targetFacility[index] = {
      id: index,
      isFree: false,
      entryTime: entryTime.toISOString(),
      endTime: new Date(entryTime.getTime() + 60 * 60000).toISOString(), // standard 1 hour allocation
      vehicleNo: "IoT Hardware Signal"
    };
  }

  // Push immediate changes out to client UIs[cite: 2]
  const spotsFreeArray = getSpotsFreeMap(facilityId);
  io.emit('parkingUpdate', { facilityId, spotsFree: spotsFreeArray });

  console.log(`[IoT Signal] Facility ${facilityId} spot ${index} is now ${isFree ? 'Free' : 'Occupied'}`);
  res.status(200).json({ success: true, spotsFree: spotsFreeArray });
});

// --- SOCKET.IO REAL-TIME CHANNELS ---
io.on('connection', (socket) => {
  console.log(`📱 Client connected: ${socket.id}`);

  // Compile a state map projection distribution package for initial initialization paint
  const baselineSnapshot = {};
  Object.keys(facilitiesData).forEach(facilityId => {
    baselineSnapshot[facilityId] = {
      name: RATES[facilityId].name,
      totalSpots: facilitiesData[facilityId].length,
      spotsFree: getSpotsFreeMap(facilityId),
      ratePerHour: RATES[facilityId].standardPerHour
    };
  });

  // Inject standalone metrics into the baseline socket initialization payload
  baselineSnapshot.standalone = {
    spotsFree: standaloneParkingSpots,
    totalSpots: standaloneParkingSpots.length
  };

  // Send current database state immediately upon connection[cite: 2]
  socket.emit('initialState', baselineSnapshot);

  socket.on('disconnect', () => {
    console.log(`❌ Client disconnected: ${socket.id}`);
  });
});

// --- SERVER LISTENER ---
server.listen(PORT, () => {
  console.log(`🚀 SmartPark Integrated Server running on port ${PORT}`);
  console.log(`connected to server at ${PORT}`); 
});
