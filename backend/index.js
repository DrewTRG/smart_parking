const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const axios = require("axios");
process.env.TZ = "Asia/Kuala_Lumpur";

const app = express();
app.use(cors());
app.use(express.json());

// ======================
// ESP32 CONFIG (ONLY Mall A spot 17)
// ======================
const ESP32_IP = "http://10.21.175.77"; // remember to change to ESP32 IP
const ESP32_MALL_ID = 1;                // Mall A
const ESP32_SPOT_ID = 17;               // Spot ID 17 (NOT spot_number)

// Helper: check if this action should trigger ESP32
function isEspTarget(spotId, mallId) {
    return Number(spotId) === ESP32_SPOT_ID && Number(mallId) === ESP32_MALL_ID;
}

// Call ESP32 endpoint: /reserve, /arrive, /leave
async function triggerEsp32(action) {
    try {
        await axios.get(`${ESP32_IP}/${action}`, { timeout: 2000 });
        console.log(`ESP32 triggered: ${action}`);
    } catch (err) {
        console.log(`ESP32 not reachable (${action}):`, err.message);
    }
}

// MySQL connection (XAMPP)
const db = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "smartspot",
    timezone: "+08:00",
    dateStrings: true,
});

db.connect((err) => {
    if (err) console.log("Database connection failed:", err);
    else console.log("Connected to MySQL using XAMPP!");
});

// Test API
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
        if (err) return res.json({ success: false, error: err });

        const updateSql = "UPDATE parking_spots SET isAvailable = 0 WHERE id = ?";

        db.query(updateSql, [spotId], async (err2) => {
            if (err2) return res.json({ success: false, error: err2 });

            //ESP32 hook ONLY for Mall A spotId 17
            if (isEspTarget(spotId, mallId)) {
                await triggerEsp32("reserve");
            }

            res.json({
                success: true,
                reservationId: result.insertId,
                message: "Spot reserved and marked as unavailable",
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

    const checkSql = "SELECT * FROM users WHERE email = ?";
    db.query(checkSql, [email], (err, results) => {
        if (err) return res.json({ success: false, error: err });
        if (results.length > 0) {
            return res.json({ success: false, message: "Email already registered" });
        }

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

        res.json({
            success: true,
            userId: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            message: "Login successful",
        });
    });
});

// Forgot password
app.post("/forgotPassword", (req, res) => {
    const { email, newPassword } = req.body;

    if (!email || !newPassword) {
        return res.json({ success: false, message: "Missing fields" });
    }

    const checkSql = "SELECT * FROM users WHERE email = ?";
    db.query(checkSql, [email], (err, results) => {
        if (err) return res.json({ success: false, error: err });
        if (results.length === 0) {
            return res.json({ success: false, message: "Email not found" });
        }

        const hash = bcrypt.hashSync(newPassword, 10);
        const updateSql =
            "UPDATE users SET password_hash = ? WHERE email = ?";

        db.query(updateSql, [hash, email], (err2) => {
            if (err2) return res.json({ success: false, error: err2 });

            res.json({
                success: true,
                message: "Password reset successful",
            });
        });
    });
});

// Get active reservations for a user
app.get("/reservations/:userId", (req, res) => {
    const userId = req.params.userId;

    const sql = `
    SELECT 
      reservations.id,
      reservations.status,
      reservations.created_at,
      reservations.mall_id,
      reservations.end_time,
      reservations.penalty_paid,
      parking_spots.spot_number
    FROM reservations
    JOIN parking_spots ON reservations.spot_id = parking_spots.id
    WHERE reservations.user_id = ?
      AND reservations.status IN ('reserved', 'occupied')
    ORDER BY reservations.created_at DESC
  `;

    db.query(sql, [userId], (err, results) => {
        if (err) return res.json({ success: false, error: err });
        res.json({ success: true, reservations: results });
    });
});

// Arrive (mark occupied)
app.post("/arrive", (req, res) => {
    const { reservationId, paidHours } = req.body;

    if (!paidHours) {
        return res.json({ success: false, message: "Missing paid hours" });
    }

    const startTime = new Date();
    //     new Date().toLocaleString("en-US", { timeZone: "Asia/Kuala_Lumpur" })
    // );
    const endTime = new Date(startTime.getTime() + paidHours * 60 * 60 * 1000);

    const updateSql = `
        UPDATE reservations
        SET 
            status = 'occupied',
            start_time = ?,
            paid_hours = ?,
            end_time = ?,
            penalty_paid = 0
        WHERE id = ?
    `;

    db.query(
        updateSql,
        [startTime, paidHours, endTime, reservationId],
        (err) => {
            if (err) return res.json({ success: false, error: err });

            // ESP32 trigger (optional)
            const findSql = "SELECT spot_id, mall_id FROM reservations WHERE id = ?";
            db.query(findSql, [reservationId], async (err2, rows) => {
                if (!err2 && rows.length > 0) {
                    const { spot_id, mall_id } = rows[0];
                    if (isEspTarget(spot_id, mall_id)) {
                        await triggerEsp32("arrive");
                    }
                }

                res.json({
                    success: true,
                    message: "Arrival registered. Parking time started.",
                    startTime,
                    endTime
                });
            });
        }
    );
});

// Extend
app.post("/extendTime", (req, res) => {
    const { reservationId, extraHours } = req.body;

    if (!reservationId || !extraHours) {
        return res.json({ success: false, message: "Missing fields" });
    }

    // Get current end_time & paid_hours
    const findSql = `
        SELECT paid_hours, end_time 
        FROM reservations 
        WHERE id = ? AND status = 'occupied'
    `;

    db.query(findSql, [reservationId], (err, rows) => {
        if (err || rows.length === 0) {
            return res.json({
                success: false,
                message: "Reservation not found or not active",
            });
        }

        const currentPaid = rows[0].paid_hours;
        const currentEnd = new Date(rows[0].end_time);

        const newPaidHours = currentPaid + extraHours;
        const newEndTime = new Date(
            currentEnd.getTime() + extraHours * 60 * 60 * 1000
        );

        const updateSql = `
            UPDATE reservations
            SET paid_hours = ?, end_time = ?
            WHERE id = ?
        `;

        db.query(
            updateSql,
            [newPaidHours, newEndTime, reservationId],
            (err2) => {
                if (err2)
                    return res.json({ success: false, error: err2 });

                res.json({
                    success: true,
                    message: "Parking time extended successfully",
                    newPaidHours,
                    newEndTime,
                });
            }
        );
    });
});


// Leave (mark completed + free spot)
app.post("/leave", (req, res) => {
    const { reservationId } = req.body;

    const sql = `
        SELECT spot_id, mall_id, end_time, penalty_paid
        FROM reservations
        WHERE id = ? AND status = 'occupied'
    `;

    db.query(sql, [reservationId], async (err, rows) => {
        if (err || rows.length === 0) {
            return res.json({ success: false, message: "Reservation not found" });
        }

        const { spot_id, mall_id, end_time, penalty_paid } = rows[0];
        const now = new Date();
        const end = new Date(end_time);

        // ⛔ TIME EXCEEDED & NOT PAID
        if (now > end && penalty_paid === 0) {
            return res.json({
                success: false,
                forcePenalty: true,
                message: "Parking time exceeded. Penalty payment required."
            });
        }

        // ✅ NORMAL LEAVE
        const completeSql = `
            UPDATE reservations
            SET status = 'completed'
            WHERE id = ?
        `;

        db.query(completeSql, [reservationId], (err2) => {
            if (err2) {
                return res.json({ success: false, error: err2 });
            }

            db.query(
                "UPDATE parking_spots SET isAvailable = 1 WHERE id = ?",
                [spot_id],
                async (err3) => {
                    if (err3) {
                        return res.json({ success: false, error: err3 });
                    }

                    // ESP32 trigger
                    if (isEspTarget(spot_id, mall_id)) {
                        await triggerEsp32("leave");
                    }

                    res.json({
                        success: true,
                        message: "Parking session completed."
                    });
                }
            );
        });

    });
});

app.post("/payPenalty", (req, res) => {
    const { reservationId } = req.body;

    const sql = `
        UPDATE reservations
        SET penalty_paid = 1
        WHERE id = ?
    `;

    db.query(sql, [reservationId], (err) => {
        if (err) return res.json({ success: false });

        res.json({
            success: true,
            message: "Penalty paid successfully"
        });
    });
});

// Cancel a reservation
app.post("/cancel", (req, res) => {
    const { reservationId } = req.body;

    // 1. Get spot_id and mall_id
    const findSql = "SELECT spot_id, mall_id FROM reservations WHERE id = ?";
    db.query(findSql, [reservationId], (err, rows) => {
        if (err || rows.length === 0) {
            return res.json({ success: false, message: "Reservation not found" });
        }

        const { spot_id, mall_id } = rows[0];

        // 2. Cancel reservation
        const cancelSql = `
            UPDATE reservations 
            SET status = 'cancelled'
            WHERE id = ?
        `;

        db.query(cancelSql, [reservationId], (err2) => {
            if (err2) return res.json({ success: false, error: err2 });

            // 3. Free parking spot
            const freeSpotSql = `
                UPDATE parking_spots 
                SET isAvailable = 1
                WHERE id = ?
            `;

            db.query(freeSpotSql, [spot_id], async (err3) => {
                if (err3) return res.json({ success: false, error: err3 });

                //ESP32 HOOK — ONLY Mall A, Spot 17
                if (spot_id === ESP32_SPOT_ID && mall_id === 1) {
                    await triggerEsp32("leave"); // LED OFF
                }

                res.json({
                    success: true,
                    message: "Reservation cancelled and spot freed."
                });
            });
        });
    });
});


// History
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
    JOIN parking_spots ON reservations.spot_id = parking_spots.id
    WHERE reservations.user_id = ?
      AND reservations.status IN ('completed', 'cancelled')
    ORDER BY reservations.created_at DESC
  `;

    db.query(sql, [userId], (err, results) => {
        if (err) return res.json({ success: false, error: err });
        res.json({ success: true, history: results });
    });
});

app.post("/deleteHistory", (req, res) => {
    const { reservationId } = req.body;

    const sql = `
    DELETE FROM reservations
    WHERE id = ? AND status IN ('completed', 'cancelled')
  `;

    db.query(sql, [reservationId], (err) => {
        if (err) return res.json({ success: false, error: err });
        res.json({ success: true, message: "History entry deleted" });
    });
});


// ADMIN: 
// Update parking availability
app.post("/admin/updateParking", (req, res) => {
    const { spotId, isAvailable } = req.body;

    const sql = `
        UPDATE parking_spots
        SET isAvailable = ?
        WHERE id = ?
    `;

    db.query(sql, [isAvailable, spotId], (err) => {
        if (err) return res.json({ success: false, error: err });

        res.json({
            success: true,
            message: "Parking slot updated",
        });
    });
});

// ADMIN: Get all users
app.get("/admin/users", (req, res) => {
    const sql = "SELECT id, name, email FROM users WHERE role = 'user'";
    db.query(sql, (err, results) => {
        if (err) return res.json({ success: false, error: err });
        res.json({ success: true, users: results });
    });
});

// ADMIN: Update user details
app.post("/admin/updateUser", (req, res) => {
    const { userId, name, password } = req.body;

    if (!userId || !name) {
        return res.json({ success: false, message: "Missing fields" });
    }

    if (password && password.length > 0) {
        // Change name + password
        const hash = bcrypt.hashSync(password, 10);
        const sql =
            "UPDATE users SET name = ?, password_hash = ? WHERE id = ? AND role = 'user'";
        db.query(sql, [name, hash, userId], (err) => {
            if (err) return res.json({ success: false, error: err });
            res.json({ success: true, message: "User updated" });
        });
    } else {
        // Change name only
        const sql =
            "UPDATE users SET name = ? WHERE id = ? AND role = 'user'";
        db.query(sql, [name, userId], (err) => {
            if (err) return res.json({ success: false, error: err });
            res.json({ success: true, message: "User updated" });
        });
    }
});

// ADMIN: Get all active reservations
app.get("/admin/reservations", (req, res) => {
    const sql = `
        SELECT 
          reservations.id,
          reservations.status,
          users.name AS user_name,
          parking_spots.spot_number,
          reservations.mall_id
        FROM reservations
        JOIN users ON reservations.user_id = users.id
        JOIN parking_spots ON reservations.spot_id = parking_spots.id
        WHERE reservations.status IN ('reserved', 'occupied')
        ORDER BY reservations.created_at DESC
    `;

    db.query(sql, (err, results) => {
        if (err) return res.json({ success: false, error: err });
        res.json({ success: true, reservations: results });
    });
});

// ADMIN: Force cancel reservation
app.post("/admin/cancelReservation", async (req, res) => {
    const { reservationId } = req.body;

    const findSql = "SELECT spot_id, mall_id FROM reservations WHERE id = ?";
    db.query(findSql, [reservationId], (err, rows) => {
        if (err || rows.length === 0) {
            return res.json({ success: false, message: "Reservation not found" });
        }

        const { spot_id, mall_id } = rows[0];

        const cancelSql =
            "UPDATE reservations SET status = 'cancelled' WHERE id = ?";
        db.query(cancelSql, [reservationId], (err2) => {
            if (err2) return res.json({ success: false, error: err2 });

            const freeSql =
                "UPDATE parking_spots SET isAvailable = 1 WHERE id = ?";
            db.query(freeSql, [spot_id], async () => {
                if (isEspTarget(spot_id, mall_id)) {
                    await triggerEsp32("leave");
                }

                res.json({
                    success: true,
                    message: "Reservation cancelled by admin",
                });
            });
        });
    });
});

// ADMIN: Force complete reservation
app.post("/admin/completeReservation", async (req, res) => {
    const { reservationId } = req.body;

    const findSql = "SELECT spot_id, mall_id FROM reservations WHERE id = ?";
    db.query(findSql, [reservationId], (err, rows) => {
        if (err || rows.length === 0) {
            return res.json({ success: false, message: "Reservation not found" });
        }

        const { spot_id, mall_id } = rows[0];

        const completeSql =
            "UPDATE reservations SET status = 'completed' WHERE id = ?";
        db.query(completeSql, [reservationId], (err2) => {
            if (err2) return res.json({ success: false, error: err2 });

            const freeSql =
                "UPDATE parking_spots SET isAvailable = 1 WHERE id = ?";
            db.query(freeSql, [spot_id], async () => {
                if (isEspTarget(spot_id, mall_id)) {
                    await triggerEsp32("leave");
                }

                res.json({
                    success: true,
                    message: "Reservation completed by admin",
                });
            });
        });
    });
});

// Start backend server
app.listen(3000, () => {
    console.log("Backend server running on port 3000");
});
