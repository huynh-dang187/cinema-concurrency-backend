// ============================================================================
// CINEMA BACKEND SERVER
// Express.js + SQL Server (mssql library)
// Endpoints: GET /api/seats, POST /api/hold, POST /api/payment
// ============================================================================

require('dotenv').config();  // Load .env file

const http = require('http');
const express = require('express');
const sql = require('mssql');
const cors = require('cors');

const { Server: SocketIOServer } = require('socket.io');

const app = express();

// HTTP server (needed for Socket.IO)
const httpServer = http.createServer(app);

// Socket.IO server (realtime seat updates)
const io = new SocketIOServer(httpServer, {
    cors: {
        origin: ['http://localhost:3000', 'http://localhost:8000'],
        methods: ['GET', 'POST'],
        credentials: true
    }
});

// ============================================================================
// CONFIGURATION
// ============================================================================

const sqlConfig = {
    server: process.env.SQL_SERVER,
    database: process.env.SQL_DATABASE,
    authentication: {
        type: 'default',
        options: {
            userName: process.env.SQL_USER,
            password: process.env.SQL_PASSWORD
        }
    },
    options: {
        encrypt: true,
        trustServerCertificate: true,
        enableKeepAlive: true,
        connectionTimeout: 30000,
        requestTimeout: 30000
    }
};

// ============================================================================
// MIDDLEWARE
// ============================================================================

app.use(cors({
    origin: ['http://localhost:3000', 'http://localhost:8000'],
    credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ============================================================================
// LOGGER UTILITY
// ============================================================================

const logger = {
    info: (msg) => console.log(`[INFO] ${new Date().toLocaleTimeString()} - ${msg}`),
    error: (msg) => console.error(`[ERROR] ${new Date().toLocaleTimeString()} - ${msg}`),
    success: (msg) => console.log(`✓ [SUCCESS] ${new Date().toLocaleTimeString()} - ${msg}`)
};

// ============================================================================
// SQL SERVER CONNECTION
// ============================================================================

let pool = null;

async function fetchSeatsForShowTime(showTimeId = 1) {
    if (!pool) {
        throw new Error('Database not connected');
    }

    const request = pool.request();
    request.input('ShowTimeID', sql.Int, showTimeId);
    const result = await request.query(`
        SELECT 
            S.SeatID,
            S.SeatName,
            S.[Status],
            S.UserIDHeld,
            U.UserName,
            ST.MovieName,
            ST.ShowTimeID
        FROM Seats S
        LEFT JOIN Users U ON S.UserIDHeld = U.UserID
        LEFT JOIN ShowTimes ST ON S.ShowTimeID = ST.ShowTimeID
        WHERE ST.ShowTimeID = @ShowTimeID
        ORDER BY S.SeatID
    `);

    return result.recordset;
}

async function broadcastSeatsUpdate(showTimeId = 1) {
    try {
        const seats = await fetchSeatsForShowTime(showTimeId);
        io.emit('seats:update', seats);
        logger.info(`Realtime: broadcast seats:update (${seats.length} seats)`);
    } catch (error) {
        logger.error(`Realtime: broadcast failed - ${error.message}`);
    }
}

async function connectDatabase() {
    try {
        pool = new sql.ConnectionPool(sqlConfig);
        await pool.connect();
        logger.success('Kết nối SQL Server thành công!');

        // First broadcast so connected clients can sync instantly
        broadcastSeatsUpdate().catch(() => {});
        return pool;
    } catch (error) {
        logger.error(`Lỗi kết nối: ${error.message}`);
        process.exit(1);
    }
}

// ============================================================================
// SOCKET.IO REALTIME
// ============================================================================

io.on('connection', (socket) => {
    logger.info(`Realtime: client connected (${socket.id})`);

    // Send current seats immediately to the newly connected client
    fetchSeatsForShowTime(1)
        .then((seats) => socket.emit('seats:update', seats))
        .catch((error) => logger.error(`Realtime: initial sync failed - ${error.message}`));

    socket.on('disconnect', (reason) => {
        logger.info(`Realtime: client disconnected (${socket.id}) - ${reason}`);
    });
});

// ============================================================================
// API ENDPOINTS
// ============================================================================

/**
 * GET /api/seats
 * Lấy danh sách tất cả ghế
 * Response: [ { SeatID, SeatName, Status, UserIDHeld, UserName } ]
 */
app.get('/api/seats', async (req, res) => {
    try {
        const seats = await fetchSeatsForShowTime(1);
        logger.info(`Lấy ${seats.length} ghế`);
        return res.json(seats);

    } catch (error) {
        logger.error(`GET /api/seats: ${error.message}`);
        return res.status(500).json({ 
            error: 'Lỗi lấy danh sách ghế',
            message: error.message 
        });
    }
});

/**
 * POST /api/hold
 * Gọi Stored Procedure sp_HoldSeat_Demo
 * Body: { seatId, userId, isSafeMode }
 * Response: { success, message }
 */
app.post('/api/hold', async (req, res) => {
    const { seatId, userId, isSafeMode } = req.body;

    // Validation
    if (!seatId || !userId === undefined || isSafeMode === undefined) {
        return res.status(400).json({ 
            error: 'Thiếu tham số: seatId, userId, isSafeMode' 
        });
    }

    try {
        if (!pool) {
            return res.status(500).json({ error: 'Database not connected' });
        }

        const request = pool.request();
        request.input('SeatID', sql.Int, seatId);
        request.input('UserID', sql.Int, userId);
        request.input('IsSafeMode', sql.Bit, isSafeMode ? 1 : 0);

        logger.info(
            `POST /api/hold: SeatID=${seatId}, UserID=${userId}, SafeMode=${isSafeMode}`
        );

        // Thực thi Stored Procedure
        const result = await request.execute('sp_HoldSeat_Demo');

        logger.success(`Ghế ${seatId} được giữ bởi User ${userId}`);

        // Realtime update to all clients (do not block response)
        broadcastSeatsUpdate().catch(() => {});

        return res.json({
            success: true,
            message: 'Ghế được giữ thành công!',
            seatId: seatId,
            userId: userId
        });

    } catch (error) {
        // ============================================================================
        // XỬ LÝ LỖI ĐẶC BIỆT: Error Code 1222 (Lock timeout)
        // ============================================================================
        if (error.number === 1222) {
            logger.error(`Lock timeout trên ghế ${seatId}`);
            return res.status(400).json({
                error: 'Ghế đang có người giao dịch',
                message: 'Vui lòng chọn ghế khác!',
                seatId: seatId,
                errorCode: 1222
            });
        }

        // Xử lý lỗi custom từ SQL (Error code 50001, 50002, 50003)
        if (error.number >= 50001 && error.number <= 50005) {
            logger.error(`Lỗi SQL: ${error.message}`);
            return res.status(400).json({
                error: 'Không thể giữ ghế',
                message: error.message,
                seatId: seatId,
                errorCode: error.number
            });
        }

        logger.error(`POST /api/hold: ${error.message}`);
        return res.status(500).json({
            error: 'Lỗi server',
            message: error.message
        });
    }
});

/**
 * POST /api/payment
 * Gọi Stored Procedure sp_Payment
 * Body: { seatId, userId, simulateError }
 * Response: { success, message }
 */
app.post('/api/payment', async (req, res) => {
    const { seatId, userId, simulateError } = req.body;

    // Validation
    if (!seatId || !userId || simulateError === undefined) {
        return res.status(400).json({
            error: 'Thiếu tham số: seatId, userId, simulateError'
        });
    }

    try {
        if (!pool) {
            return res.status(500).json({ error: 'Database not connected' });
        }

        const request = pool.request();
        request.input('SeatID', sql.Int, seatId);
        request.input('UserID', sql.Int, userId);
        request.input('SimulateError', sql.Bit, simulateError ? 1 : 0);

        logger.info(
            `POST /api/payment: SeatID=${seatId}, UserID=${userId}, SimulateError=${simulateError}`
        );

        // Thực thi Stored Procedure
        const result = await request.execute('sp_Payment');

        logger.success(`Thanh toán ghế ${seatId} cho User ${userId}`);

        // Realtime update to all clients (do not block response)
        broadcastSeatsUpdate().catch(() => {});

        return res.json({
            success: true,
            message: 'Thanh toán thành công!',
            seatId: seatId,
            userId: userId,
            amount: 150000
        });

    } catch (error) {
        // ============================================================================
        // XỬ LÝ LỖI TỪ TRANSACTION ROLLBACK
        // ============================================================================
        if (error.number >= 50000 && error.number <= 50099) {
            logger.error(`Lỗi thanh toán: ${error.message}`);
            return res.status(400).json({
                error: 'Thanh toán thất bại',
                message: error.message,
                seatId: seatId,
                errorCode: error.number
            });
        }

        logger.error(`POST /api/payment: ${error.message}`);
        return res.status(500).json({
            error: 'Lỗi server',
            message: error.message
        });
    }
});

// ============================================================================
// HEALTH CHECK
// ============================================================================

app.get('/api/health', (req, res) => {
    return res.json({
        status: 'OK',
        timestamp: new Date(),
        database: pool ? 'Connected' : 'Disconnected'
    });
});

// ============================================================================
// ERROR HANDLING MIDDLEWARE
// ============================================================================

app.use((err, req, res, next) => {
    logger.error(`Unhandled error: ${err.message}`);
    return res.status(500).json({
        error: 'Internal Server Error',
        message: err.message
    });
});

// ============================================================================
// SERVER STARTUP
// ============================================================================

const PORT = process.env.PORT || 3000;

async function startServer() {
    try {
        // Kết nối database
        await connectDatabase();

        // Khởi động server
        httpServer.listen(PORT, () => {
            logger.success(`Server chạy trên http://localhost:${PORT}`);
            logger.info('Sẵn sàng nhận request!');
        });

    } catch (error) {
        logger.error(`Lỗi khởi động: ${error.message}`);
        process.exit(1);
    }
}

// Xử lý graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM nhận được - đóng kết nối...');
    if (pool) {
        await pool.close();
    }
    process.exit(0);
});

process.on('SIGINT', async () => {
    logger.info('SIGINT nhận được - đóng kết nối...');
    if (pool) {
        await pool.close();
    }
    process.exit(0);
});

// ============================================================================
// START
// ============================================================================

startServer();

module.exports = app;
