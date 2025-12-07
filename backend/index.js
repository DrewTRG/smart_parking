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
    password: "",
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
app.get("/spots/:mallId", (req, res) => {
    const mallId = req.params.mallId;

    const sql = "SELECT * FROM parking_spots WHERE mall_id = ?";
    db.query(sql, [mallId], (err, results) => {
        if (err) return res.json({ success: false, error: err });

        res.json({ success: true, spots: results });
    });
});


// Reserve a parking spot
app.post("/reserve", (req, res) => {
    const { userId, spotId, mallId } = req.body;

    const insertSql =
        "INSERT INTO reservations (user_id, spot_id, mall_id, status) VALUES (?, ?, ?, 'reserved')";

    db.query(insertSql, [userId, spotId, mallId], (err, result) => {
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

// Get active reservations for a user
app.get("/reservations/:userId", (req, res) => {
    const userId = req.params.userId;

    const sql = `
        SELECT reservations.id,
               reservations.status,
               reservations.created_at,
               reservations.spot_id,
               reservations.mall_id,
               parking_spots.spot_number
        FROM reservations
        JOIN parking_spots ON reservations.spot_id = parking_spots.id
        WHERE reservations.user_id = ? AND reservations.status = 'reserved'
        ORDER BY reservations.created_at DESC
    `;

    db.query(sql, [userId], (err, results) => {
        if (err) return res.json({ success: false, error: err });

        res.json({
            success: true,
            reservations: results
        });
    });
});

// Cancel a reservation
app.post("/cancel", (req, res) => {
    const { reservationId } = req.body;

    // Step 1: Get the spot_id of the reservation
    const findSql = "SELECT spot_id FROM reservations WHERE id = ?";
    db.query(findSql, [reservationId], (err, rows) => {
        if (err || rows.length === 0) {
            return res.json({ success: false, message: "Reservation not found" });
        }

        const spotId = rows[0].spot_id;

        // Step 2: Cancel reservation
        const cancelSql = `
            UPDATE reservations SET status = 'cancelled'
            WHERE id = ?
        `;

        db.query(cancelSql, [reservationId], (err2) => {
            if (err2) return res.json({ success: false, error: err2 });

            // Step 3: Set parking spot back to available
            const freeSpotSql = `
                UPDATE parking_spots SET isAvailable = 1
                WHERE id = ?
            `;
            db.query(freeSpotSql, [spotId], (err3) => {
                if (err3) return res.json({ success: false, error: err3 });

                res.json({
                    success: true,
                    message: "Reservation cancelled and spot freed."
                });
            });
        });
    });
});

// Get completed reservation history
app.get("/history/:userId", (req, res) => {
    const userId = req.params.userId;

    const sql = `
    SELECT 
        reservations.id,
        reservations.status,
        reservations.created_at,
        reservations.mall_id,
        parking_spots.spot_number
    FROM reservations
    JOIN parking_spots 
        ON reservations.spot_id = parking_spots.id
    WHERE reservations.user_id = ?
      AND reservations.status IN ('completed', 'cancelled')
    ORDER BY reservations.created_at DESC
`;

    db.query(sql, [userId], (err, results) => {
        if (err) return res.json({ success: false, error: err });

        res.json({
            success: true,
            history: results
        });
    });
});

app.post("/deleteHistory", (req, res) => {
    const { reservationId } = req.body;

    const sql = `
        DELETE FROM reservations
        WHERE id = ? AND status IN ('completed', 'cancelled')
    `;

    db.query(sql, [reservationId], (err, result) => {
        if (err) return res.json({ success: false, error: err });

        return res.json({
            success: true,
            message: "History entry deleted"
        });
    });
});

// Mark reservation as completed
app.post("/complete", (req, res) => {
    const { reservationId } = req.body;

    // First get the spot
    const findSql = "SELECT spot_id FROM reservations WHERE id = ?";
    db.query(findSql, [reservationId], (err, rows) => {
        if (err || rows.length === 0) {
            return res.json({ success: false, message: "Reservation not found" });
        }

        const spotId = rows[0].spot_id;

        // Mark as completed
        const completeSql = `
            UPDATE reservations SET status = 'completed'
            WHERE id = ?
        `;

        db.query(completeSql, [reservationId], (err2) => {
            if (err2) return res.json({ success: false, error: err2 });

            // Free the parking spot
            const freeSql = `
                UPDATE parking_spots SET isAvailable = 1
                WHERE id = ?
            `;
            db.query(freeSql, [spotId], (err3) => {
                if (err3) return res.json({ success: false, error: err3 });

                res.json({
                    success: true,
                    message: "Reservation completed and spot freed."
                });
            });
        });
    });
});


// Start backend server
app.listen(3000, () => {
    console.log("Backend server running on port 3000");
});
