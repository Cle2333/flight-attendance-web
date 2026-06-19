const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDatabase } = require('./database-simple');
const authRoutes = require('./routes/auth');
const apiRoutes = require('./routes/api');
const adminRoutes = require('./routes/admin');

const app = express();
const PORT = process.env.PORT || 8080;

// 中间件
app.use(cors());
app.use(express.json());

// API 路由
app.use('/api/auth', authRoutes);
app.use('/api', apiRoutes);
app.use('/api/admin', adminRoutes);

// 测试路由
app.get('/api/test', (req, res) => {
  res.json({ success: true, message: 'API works!' });
});

// 静态文件服务（用于生产环境）
app.use(express.static(path.join(__dirname, '..')));

// SPA fallback - 排除所有 API 路径
app.get('*', (req, res) => {
  if (!req.path.startsWith('/api')) {
    res.sendFile(path.join(__dirname, '..', 'index.html'));
  }
});

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({
    success: false,
    message: '服务器内部错误'
  });
});

// 初始化数据库并启动服务器
(async () => {
  try {
    await initDatabase();
    app.listen(PORT, () => {
      console.log(`航班打卡服务器运行在 http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('数据库初始化失败:', error);
    process.exit(1);
  }
})();
