const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const path = require('path');

const app = express();

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());

// =========================================================================
// DATA STRUCTURES & IN-MEMORY DATABASE
// =========================================================================

const facilities = {
  civil: {
    id: 'civil',
    facilityName: 'Civil Mall Parking',
    locationName: 'Sundhara, Kathmandu',
    coordinates: { lat: 27.700769, lng: 85.315383 },
    ratePerHour: 60,
    totalSpots: 8,
    spots: [
      { id: 1, spotCode: 'C-01', isFree: true, bookedBy: null },
      { id: 2, spotCode: 'C-02', isFree: false, bookedBy: 'BA 2 PA 1234' },
      { id: 3, spotCode: 'C-03', isFree: true, bookedBy: null },
      { id: 4, spotCode: 'C-04', isFree: true, bookedBy: null },
      { id: 5, spotCode: 'C-05', isFree: false, bookedBy: 'BA 1 JAH 5678' },
      { id: 6, spotCode: 'C-06', isFree: true, bookedBy: null },
      { id: 7, spotCode: 'C-07', isFree: true, bookedBy: null },
      { id: 8, spotCode: 'C-08', isFree: true, bookedBy: null }
    ]
  },
  labim: {
    id: 'labim',
    facilityName: 'Labim Mall Parking',
    locationName: 'Pulchowk, Lalitpur',
    coordinates: { lat: 27.678400, lng: 85.316800 },
    ratePerHour: 80,
    totalSpots: 6,
    spots: [
      { id: 1, spotCode: 'L-01', isFree: true, bookedBy: null },
      { id: 2, spotCode: 'L-02', isFree: true, bookedBy: null },
      { id: 3, spotCode: 'L-03', isFree: false, bookedBy: 'LU 3 CHA 9988' },
      { id: 4, spotCode: 'L-04', isFree: true, bookedBy: null },
      { id: 5, spotCode: 'L-05', isFree: true, bookedBy: null },
      { id: 6, spotCode: 'L-06', isFree: true, bookedBy: null }
    ]
  },
  ranipokhari: {
    id: 'ranipokhari',
    facilityName: 'Rani Pokhari Underground Parking',
    locationName: 'Jamal, Kathmandu',
    coordinates: { lat: 27.708000, lng: 85.314900 },
    ratePerHour: 40,
    totalSpots: 12,
    spots: [
      { id: 1, spotCode: 'RP-01', isFree: true, bookedBy: null },
      { id: 2, spotCode: 'RP-02', isFree: true, bookedBy: null },
      { id: 3, spotCode: 'RP-03', isFree: true, bookedBy: null },
      { id: 4, spotCode: 'RP-04', isFree: false, bookedBy: 'BAGMATI 01-025-CHA-1122' },
      { id: 5, spotCode: 'RP-05', isFree: true, bookedBy: null },
      { id: 6, spotCode: 'RP-06', isFree: true, bookedBy: null },
      { id: 7, spotCode: 'RP-07', isFree: true, bookedBy: null },
      { id: 8, spotCode: 'RP-08', isFree: true, bookedBy: null },
      { id: 9, spotCode: 'RP-09', isFree: false, bookedBy: 'BA 2 PA 4321' },
      { id: 10, spotCode: 'RP-10', isFree: true, bookedBy: null },
      { id: 11, spotCode: 'RP-11', isFree: true, bookedBy: null },
      { id: 12, spotCode: 'RP-12', isFree: true, bookedBy: null }
    ]
  },
  dharahara: {
    id: 'dharahara',
    facilityName: 'Dharahara Tower Plaza Parking',
    locationName: 'Sundhara, Kathmandu',
    coordinates: { lat: 27.700500, lng: 85.312200 },
    ratePerHour: 50,
    totalSpots: 10,
    spots: [
      { id: 1, spotCode: 'DH-01', isFree: false, bookedBy: 'BA 18 PA 7711' },
      { id: 2, spotCode: 'DH-02', isFree: false, bookedBy: 'PRADESH 3-02-001' },
      { id: 3, spotCode: 'DH-03', isFree: true, bookedBy: null },
      { id: 4, spotCode: 'DH-04', isFree: true, bookedBy: null },
      { id: 5, spotCode: 'DH-05', isFree: true, bookedBy: null },
      { id: 6, spotCode: 'DH-06', isFree: false, bookedBy: 'BA 2 PA 9090' },
      { id: 7, spotCode: 'DH-07', isFree: true, bookedBy: null },
      { id: 8, spotCode: 'DH-08', isFree: true, bookedBy: null },
      { id: 9, spotCode: 'DH-09', isFree: true, bookedBy: null },
      { id: 10, spotCode: 'DH-10', isFree: true, bookedBy: null }
    ]
  }
};

const bookingHistory = [];

// =========================================================================
// MIDDLEWARE LOGGING
// =========================================================================

app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.url}`);
  next();
});

// =========================================================================
// ROUTE HANDLERS & API ENDPOINTS
// =========================================================================

// Root Health Check Route
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    system: 'SmartPark Nepal Express API',
    version: '1.0.0',
    availableFacilities: Object.keys(facilities)
  });
});

// GET: Get all facilities summary
app.get('/api/parking', (req, res) => {
  const summary = {};
  for (const [key, facility] of Object.entries(facilities)) {
    const availableSpots = facility.spots.filter(s => s.isFree).length;
    summary[key] = {
      id: facility.id,
      facilityName: facility.facilityName,
      locationName: facility.locationName,
      coordinates: facility.coordinates,
      ratePerHour: facility.ratePerHour,
      totalSpots: facility.totalSpots,
      availableSpots: availableSpots,
      spots: facility.spots
    };
  }
  res.json({
    success: true,
    count: Object.keys(summary).length,
    data: summary
  });
});

// GET: Fetch individual facility by ID
app.get('/api/parking/:facilityId', (req, res) => {
  const { facilityId } = req.params;
  const facility = facilities[facilityId.toLowerCase()];

  if (!facility) {
    return res.status(404).json({
      success: false,
      message: `Facility '${facilityId}' not found. Valid IDs: civil, labim, ranipokhari, dharahara`
    });
  }

  const availableSpots = facility.spots.filter(s => s.isFree).length;

  res.json({
    success: true,
    id: facility.id,
    facilityName: facility.facilityName,
    locationName: facility.locationName,
    coordinates: facility.coordinates,
    ratePerHour: facility.ratePerHour,
    totalSpots: facility.totalSpots,
    availableSpots: availableSpots,
    spots: facility.spots
  });
});

// POST: Book a spot in a specific facility
app.post('/api/parking/:facilityId/book', (req, res) => {
  const { facilityId } = req.params;
  const { index, durationInMinutes, vehicleNo } = req.body;

  const facility = facilities[facilityId.toLowerCase()];

  if (!facility) {
    return res.status(404).json({
      success: false,
      message: `Facility '${facilityId}' not found.`
    });
  }

  if (index === undefined || index === null || typeof index !== 'number') {
    return res.status(400).json({
      success: false,
      message: 'Missing or invalid "index" parameter in request body.'
    });
  }

  if (index < 0 || index >= facility.spots.length) {
    return res.status(400).json({
      success: false,
      message: `Invalid spot index ${index}. Available range: 0 to ${facility.spots.length - 1}`
    });
  }

  const targetSpot = facility.spots[index];

  if (!targetSpot.isFree) {
    return res.status(409).json({
      success: false,
      message: `Spot #${index} (${targetSpot.spotCode}) at ${facility.facilityName} is already occupied.`
    });
  }

  // Calculate estimated cost
  const duration = durationInMinutes || 60;
  const estimatedCost = (facility.ratePerHour / 60) * duration;
  const registrationVehicle = vehicleNo || 'UNREGISTERED';

  // Reserve the spot
  targetSpot.isFree = false;
  targetSpot.bookedBy = registrationVehicle;

  const bookingRecord = {
    bookingId: `BK-${Date.now()}`,
    facilityId: facility.id,
    facilityName: facility.facilityName,
    spotIndex: index,
    spotCode: targetSpot.spotCode,
    vehicleNo: registrationVehicle,
    durationMinutes: duration,
    costCalculated: estimatedCost,
    timestamp: new Date().toISOString()
  };

  bookingHistory.push(bookingRecord);

  console.log(`[BOOKING SUCCESS] ${registrationVehicle} -> ${facility.facilityName} Spot ${targetSpot.spotCode}`);

  res.json({
    success: true,
    message: `Spot ${targetSpot.spotCode} successfully booked at ${facility.facilityName}`,
    bookingDetails: bookingRecord
  });
});

// POST: Release/Free up a spot
app.post('/api/parking/:facilityId/release', (req, res) => {
  const { facilityId } = req.params;
  const { index } = req.body;

  const facility = facilities[facilityId.toLowerCase()];

  if (!facility) {
    return res.status(404).json({
      success: false,
      message: `Facility '${facilityId}' not found.`
    });
  }

  if (index === undefined || index === null || index < 0 || index >= facility.spots.length) {
    return res.status(400).json({
      success: false,
      message: 'Invalid spot index provided.'
    });
  }

  const targetSpot = facility.spots[index];

  if (targetSpot.isFree) {
    return res.status(400).json({
      success: false,
      message: `Spot ${targetSpot.spotCode} is already open.`
    });
  }

  const previousVehicle = targetSpot.bookedBy;
  targetSpot.isFree = true;
  targetSpot.bookedBy = null;

  console.log(`[RELEASE SUCCESS] Released ${targetSpot.spotCode} (was booked by ${previousVehicle})`);

  res.json({
    success: true,
    message: `Spot ${targetSpot.spotCode} at ${facility.facilityName} is now free.`,
    releasedVehicle: previousVehicle
  });
});

// GET: Retrieve transaction/booking history
app.get('/api/history', (req, res) => {
  res.json({
    success: true,
    totalBookings: bookingHistory.length,
    history: bookingHistory
  });
});

// 404 Fallback for unknown endpoints
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} does not exist.`
  });
});

// =========================================================================
// SERVER STARTUP & FLUTTER AUTOMATIC LAUNCHER
// =========================================================================

const PORT = process.env.PORT || 2001;

app.listen(PORT, () => {
  console.log(`\n======================================================`);
  console.log(`  SmartPark Nepal Express API Server Active`);
  console.log(`  Listening on: http://localhost:${PORT}`);
  console.log(`======================================================\n`);
  console.log(`[AUTO-LAUNCH] Initializing Flutter Web Application...`);

  const flutterPath = path.join(__dirname, 'Flutter', 'main');

  const flutterProcess = spawn('cmd.exe', ['/c', 'flutter run -d chrome --web-port=3000'], {
    cwd: flutterPath,
    stdio: 'inherit',
    shell: true
  });

  flutterProcess.on('error', (err) => {
    console.error('[AUTO-LAUNCH ERROR] Failed to start Flutter child process:', err);
  });
});
