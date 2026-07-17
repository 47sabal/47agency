const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors()); // Allows Flutter app (web/mobile) to connect

const JWT_SECRET = 'smartpark_nepal_super_secret_key_123';

// Mock Database (In real apps, use MongoDB or PostgreSQL)
const users = [];

// Helper to simulate a pre-registered user for testing
(async () => {
    const hashedPassword = await bcrypt.hash('password123', 10);
    users.push({
        email: 'test@smartpark.com.np',
        password: hashedPassword,
        name: 'Ram Bahadur'
    });
})();

// --- LOGIN ROUTE ---
app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;

    // Basic Validation
    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required.' });
    }

    // Find User
    const user = users.find(u => u.email.toLowerCase() === email.toLowerCase());
    if (!user) {
        return res.status(401).json({ message: 'Invalid email or password.' });
    }

    // Verify Password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
        return res.status(401).json({ message: 'Invalid email or password.' });
    }

    // Generate Token
    const token = jwt.sign({ email: user.email, name: user.name }, JWT_SECRET, { expiresIn: '7d' });

    return res.status(200).json({
        message: 'Login successful',
        token,
        user: { name: user.name, email: user.email }
    });
});

// --- REGISTER ROUTE (Bonus for your Sign Up flow) ---
app.post('/api/auth/register', async (req, res) => {
    const { email, password, name } = req.body;

    if (!email || !password) return res.status(400).json({ message: 'Missing fields.' });
    if (users.some(u => u.email === email)) return res.status(400).json({ message: 'Email already exists.' });

    const hashedPassword = await bcrypt.hash(password, 10);
    users.push({ email, password: hashedPassword, name: name || 'User' });

    return res.status(201).json({ message: 'User registered successfully!' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`SmartPark Backend running on port ${PORT}`));