const express = require("express");
const cors = require("cors");

const app = express();
const PORT = 2001; 

// Middleware
app.use(cors());
app.use(express.json());

// Pricing Schema (in NPR / Rs.)
const RATES = {
  civil: { name: "Civil Mall", standardPerHour: 60 },
  labim: { name: "Labim Mall", standardPerHour: 80 },
  ranipokhari: { name: "Rani Pokhari", standardPerHour: 40 },
  dharahara: { name: "Dharahara Tower", standardPerHour: 50 }
};

const OVERTIME_MULTIPLIER = 3; // 3x Penalty for overtime

// In-memory data structures matching the 4 facilities from main1.dart
let facilitiesData = {
  civil: Array.from({ length: 8 }, (_, i) => ({ id: i, isFree: true, entryTime: null, endTime: null, vehicleNo: null })),
  labim: Array.from({ length: 6 }, (_, i) => ({ id: i, isFree: true, entryTime: null, endTime: null, vehicleNo: null })),
  ranipokhari: Array.from({ length: 12 }, (_, i) => ({ id: i, isFree: true, entryTime: null, endTime: null, vehicleNo: null })),
  dharahara: Array.from({ length: 10 }, (_, i) => ({ id: i, isFree: true, entryTime: null, endTime: null, vehicleNo: null }))
};

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

// 1. Get entire infrastructure status for a targeted facility
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

// 2. Commit a booking entry reservation from the App UI
app.post('/api/parking/:facilityId/book', (req, res) => {
  const { facilityId } = req.params;
  const { index, durationInMinutes, vehicleNo } = req.body;

  const targetFacility = facilitiesData[facilityId];
  if (!targetFacility) return res.status(444).json({ success: false, message: "Unknown facility." });
  if (index === undefined || index < 0 || index >= targetFacility.length) {
    return res.status(400).json({ success: false, message: "Invalid grid spot position index." });
  }
  if (!targetFacility[index].isFree) {
    return res.status(400).json({ success: false, message: "Target space slot is already reserved." });
  }

  const entryTime = new Date();
  const endTime = new Date(entryTime.getTime() + durationInMinutes * 60000);

  targetFacility[index] = {
    id: index,
    isFree: false,
    entryTime: entryTime.toISOString(),
    endTime: endTime.toISOString(),
    vehicleNo: vehicleNo || "Unknown"
  };

  res.status(200).json({
    success: true,
    message: "Spot secured successfully",
    spot: targetFacility[index]
  });
});

// 3. Clear/Release a space slot and compute the final invoice penalty
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

  // Reset parameters back to raw initial baseline values
  targetFacility[index] = { id: index, isFree: true, entryTime: null, endTime: null, vehicleNo: null };

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

// Port connection verification log
app.listen(PORT, () => {
  console.log("connected to server at 2001");
});