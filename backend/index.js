const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
const bcrypt = require("bcryptjs");

const app = express();
app.use(cors());
app.use(express.json());

// MySQL connection (XAMPP)
const db = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",         // default for XAMPP
    database: "smartspot"
});

db.connect(err => {
    if (err) {
        console.log("Database connection failed:", err);
    } else {
        console.log("Connected to MySQL using XAMPP!");
    }
});

// Test API (API Starts Here)
app.get("/", (req, res) => {
    res.send("Backend running successfully!");
});

// Get all parking spots
app.get("/spots", (req, res) => {
    db.query("SELECT * FROM parking_spots", (err, results) => {
        if (err) {
            return res.json({ success: false, error: err });
        }
        res.json({ success: true, spots: results });
    });
});

// Reserve a parking spot
app.post("/reserve", (req, res) => {
    const { userId, spotId } = req.body;

    const insertSql =
        "INSERT INTO reservations (user_id, spot_id, status) VALUES (?, ?, 'reserved')";

    db.query(insertSql, [userId, spotId], (err, result) => {
        if (err) {
            return res.json({ success: false, error: err });
        }

        // after reservation, update parking_spots to mark it as unavailable
        const updateSql = "UPDATE parking_spots SET isAvailable = 0 WHERE id = ?";

        db.query(updateSql, [spotId], (err2) => {
            if (err2) {
                return res.json({ success: false, error: err2 });
            }

            res.json({
                success: true,
                reservationId: result.insertId,
                message: "Spot reserved and marked as occupied",
            });
        });
    });
});

// User registration
app.post("/register", (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.json({ success: false, message: "Missing fields" });
    }

    // Check if email already exists
    const checkSql = "SELECT * FROM users WHERE email = ?";
    db.query(checkSql, [email], (err, results) => {
        if (err) return res.json({ success: false, error: err });

        if (results.length > 0) {
            return res.json({ success: false, message: "Email already registered" });
        }

        // Hash password
        const salt = bcrypt.genSaltSync(10);
        const hash = bcrypt.hashSync(password, salt);

        const insertSql =
            "INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)";

        db.query(insertSql, [name, email, hash], (err2, result) => {
            if (err2) return res.json({ success: false, error: err2 });

            res.json({
                success: true,
                userId: result.insertId,
                message: "Registration successful",
            });
        });
    });
});

// User login
app.post("/login", (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.json({ success: false, message: "Missing email or password" });
    }

    const sql = "SELECT * FROM users WHERE email = ?";
    db.query(sql, [email], (err, results) => {
        if (err) return res.json({ success: false, error: err });

        if (results.length === 0) {
            return res.json({ success: false, message: "Invalid email or password" });
        }

        const user = results[0];

        const passwordMatch = bcrypt.compareSync(password, user.password_hash);
        if (!passwordMatch) {
            return res.json({ success: false, message: "Invalid email or password" });
        }

        // Login success
        res.json({
            success: true,
            userId: user.id,
            name: user.name,
            email: user.email,
            message: "Login successful",
        });
    });
});

// Start backend server
app.listen(3000, () => {
    console.log("Backend server running on port 3000");
});
