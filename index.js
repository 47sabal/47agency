const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { spawn } = require('child_process');
const path = require('path');

const app = express();
const server = http.createServer(app);
const PORT = 2001;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Socket.io
const io = new Server(server, { cors: { origin: "*", methods: ["GET", "POST"] } });

// =========================================================================
// DATA STRUCTURES & CONFIGURATION
// =========================================================================

const OVERTIME_MULTIPLIER = 3;

const facilities = {
  civil: {
    id: 'civil',
    facilityName: 'Civil Mall Parking',
    locationName: 'Sundhara, Kathmandu',
    ratePerHour: 60,
    spots: Array.from({ length: 8 }, (_, i) => ({ id: i, spotCode: `C-${String(i+1).padStart(2, '0')}`, isFree: true, entryTime: null, endTime: null, vehicleNo: null }))
  },
  labim: {
    id: 'labim',
    facilityName: 'Labim Mall Parking',
    locationName: 'Pulchowk, Lalitpur',
    ratePerHour: 80,
    spots: Array.from({ length: 6 }, (_, i) => ({ id: i, spotCode: `L-${String(i+1).padStart(2, '0')}`, isFree: true, entryTime: null, endTime: null, vehicleNo: null }))
  },
  ranipokhari: {
    id: 'ranipokhari',
    facilityName: 'Rani Pokhari Underground Parking',
    locationName: 'Jamal, Kathmandu',
    ratePerHour: 40,
    spots: Array.from({ length: 12 }, (_, i) => ({ id: i, spotCode: `RP-${String(i+1).padStart(2, '0')}`, isFree: true, entryTime: null, endTime: null, vehicleNo: null }))
  },
  dharahara: {
    id: 'dharahara',
    facilityName: 'Dharahara Tower Plaza Parking',
    locationName: 'Sundhara, Kathmandu',
    ratePerHour: 50,
    spots: Array.from({ length: 10 }, (_, i) => ({ id: i, spotCode: `DH-${String(i+1).padStart(2, '0')}`, isFree: true, entryTime: null, endTime: null, vehicleNo: null }))
  }
};

const bookingHistory = [];

// =========================================================================
// BILLING ENGINE
// =========================================================================

function calculateLiveBill(spot, hourlyRate) {
  if (spot.isFree || !spot.entryTime) return { totalCharge: 0, overtimeMinutes: 0, isOvertime: false };

  const now = new Date();
  const entry = new Date(spot.entryTime);
  const scheduledEnd = new Date(spot.endTime);
  const totalMinutes = Math.max(0, Math.ceil((now - entry) / 60000));
  const scheduledMinutes = Math.max(0, Math.ceil((scheduledEnd - entry) / 60000));

  let overtimeMinutes = now > scheduledEnd ? Math.max(0, Math.ceil((now - scheduledEnd) / 60000)) : 0;
  const standardCharge = (Math.min(totalMinutes, scheduledMinutes) / 60) * hourlyRate;
  const penaltyCharge = (overtimeMinutes / 60) * (hourlyRate * OVERTIME_MULTIPLIER);

  return {
    standardCharge: parseFloat(standardCharge.toFixed(2)),
    penaltyCharge: parseFloat(penaltyCharge.toFixed(2)),
    totalCharge: parseFloat((standardCharge + penaltyCharge).toFixed(2)),
    overtimeMinutes,
    isOvertime: now > scheduledEnd
  };
}

// =========================================================================
// API ENDPOINTS
// =========================================================================

app.get('/api/parking', (req, res) => {
  res.json({ success: true, data: facilities });
});

app.get('/api/parking/:facilityId', (req, res) => {
  const facility = facilities[req.params.facilityId.toLowerCase()];
  if (!facility) return res.status(404).json({ success: false, message: "Facility not found" });

  const processedSpots = facility.spots.map(s => ({ ...s, ...calculateLiveBill(s, facility.ratePerHour) }));
  res.json({ success: true, ...facility, spots: processedSpots });
});

app.post('/api/parking/:facilityId/book', (req, res) => {
  const { facilityId } = req.params;
  const { index, durationInMinutes, vehicleNo } = req.body;
  const facility = facilities[facilityId.toLowerCase()];

  if (!facility || !facility.spots[index]) return res.status(400).json({ success: false, message: "Invalid request" });
  if (!facility.spots[index].isFree) return res.status(409).json({ success: false, message: "Spot occupied" });

  const entryTime = new Date();
  const endTime = new Date(entryTime.getTime() + (durationInMinutes || 60) * 60000);

  facility.spots[index] = { ...facility.spots[index], isFree: false, entryTime, endTime, vehicleNo: vehicleNo || "UNKNOWN" };
  
  io.emit('parkingUpdate', { facilityId, spots: facility.spots });
  res.json({ success: true, message: "Booked", spot: facility.spots[index] });
});

app.post('/api/parking/:facilityId/release', (req, res) => {
  const { facilityId } = req.params;
  const { index } = req.body;
  const facility = facilities[facilityId.toLowerCase()];

  if (!facility || !facility.spots[index] || facility.spots[index].isFree) return res.status(400).json({ success: false, message: "Invalid action" });

  const invoice = calculateLiveBill(facility.spots[index], facility.ratePerHour);
  facility.spots[index] = { id: index, spotCode: facility.spots[index].spotCode, isFree: true, entryTime: null, endTime: null, vehicleNo: null };

  io.emit('parkingUpdate', { facilityId, spots: facility.spots });
  res.json({ success: true, invoice });
});

// =========================================================================
// START SERVER
// =========================================================================

server.listen(PORT, () => {
  console.log(`SmartPark API running on http://localhost:${PORT}`);
});