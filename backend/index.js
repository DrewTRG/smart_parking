const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");

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

    const sql = "INSERT INTO reservations (user_id, spot_id, status) VALUES (?, ?, 'reserved')";

    db.query(sql, [userId, spotId], (err, result) => {
        if (err) {
            return res.json({ success: false, error: err });
        }
        res.json({ success: true, reservationId: result.insertId });
    });
});

// Start backend server
app.listen(3000, () => {
    console.log("Backend server running on port 3000");
});
