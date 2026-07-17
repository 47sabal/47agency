const express = require("express");
const cors = require("cors");

const app = express();
// Using your requested Port 2001 [cite: 10]
const PORT = 2001; 

// Middleware
app.use(cors());
app.use(express.json());

// In-memory database for the 8 parking spots (true = free, false = occupied)
let parkingSpots = [true, false, true, true, false, true, false, true];

// --- REST API ENDPOINTS ---

// 1. Get current status of all spots
app.get('/api/parking', (req, res) => {
  res.status(200).json({
    success: true,
    data: parkingSpots,
    totalSpots: parkingSpots.length,
    availableSpots: parkingSpots.filter(spot => spot).length
  });
});

// 2. Update/Toggle a single spot status
app.post('/api/parking/toggle', (req, res) => {
  const { index } = req.body;

  if (index === undefined || index < 0 || index >= parkingSpots.length) {
    return res.status(400).json({ success: false, message: "Invalid spot index." });
  }

  // Toggle the boolean value of the selected spot
  parkingSpots[index] = !parkingSpots[index];

  return res.status(200).json({
    success: true,
    message: `Spot ${index + 1} updated successfully.`,
    data: parkingSpots,
    availableSpots: parkingSpots.filter(spot => spot).length
  });
});

// Using your exact listening configuration block [cite: 10]
app.listen(PORT, () => {
  console.log("connected to server at 2001");
});