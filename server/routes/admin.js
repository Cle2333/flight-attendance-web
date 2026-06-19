const express = require('express');
const { userOperations, recordOperations } = require('../database-simple');

const router = express.Router();

// 注意：管理员路由不需要认证（内部使用）

// 获取所有用户
router.get('/users', async (req, res) => {
  try {
    const users = await userOperations.getAll();
    res.json({
      success: true,
      data: users
    });
  } catch (error) {
    console.error('获取用户列表错误:', error);
    res.status(500).json({
      success: false,
      message: '获取用户列表失败'
    });
  }
});

// 删除用户
router.delete('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await userOperations.delete(id);
    if (result.changes === 0) {
      return res.status(404).json({
        success: false,
        message: '用户不存在'
      });
    }
    res.json({
      success: true,
      message: '删除成功'
    });
  } catch (error) {
    console.error('删除用户错误:', error);
    res.status(500).json({
      success: false,
      message: '删除用户失败'
    });
  }
});

// 获取排行榜
router.get('/leaderboard', async (req, res) => {
  try {
    const { type } = req.query;
    const users = await userOperations.getAll();
    const leaderboard = [];

    for (const user of users) {
      try {
        const records = await recordOperations.getByUserId(user.id);
        let filteredRecords = records;
        if (type === 'week') {
          const now = new Date();
          const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          filteredRecords = records.filter(r => new Date(r.time) >= weekAgo);
        }
        leaderboard.push({
          id: user.id,
          username: user.account,
          nickname: user.nickname,
          avatar: user.avatar || '✈️',
          count: filteredRecords.length
        });
      } catch (e) {}
    }

    leaderboard.sort((a, b) => b.count - a.count);
    res.json({
      success: true,
      data: leaderboard
    });
  } catch (error) {
    console.error('获取排行榜错误:', error);
    res.status(500).json({
      success: false,
      message: '获取排行榜失败'
    });
  }
});

// 获取用户详情
router.get('/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const users = await userOperations.getAll();
    const user = users.find(u => u.id === parseInt(id));
    if (!user) {
      return res.status(404).json({
        success: false,
        message: '用户不存在'
      });
    }
    const records = await recordOperations.getByUserId(parseInt(id));
    res.json({
      success: true,
      data: {
        ...user,
        records: records
      }
    });
  } catch (error) {
    console.error('获取用户详情错误:', error);
    res.status(500).json({
      success: false,
      message: '获取用户详情失败'
    });
  }
});

// 获取统计数据
router.get('/stats', async (req, res) => {
  try {
    const users = await userOperations.getAll();
    const allRecords = [];
    for (const user of users) {
      try {
        const records = await recordOperations.getByUserId(user.id);
        allRecords.push(...records);
      } catch (e) {}
    }
    res.json({
      success: true,
      data: {
        totalUsers: users.length,
        totalRecords: allRecords.length,
        todayRecords: allRecords.filter(r => {
          const today = new Date().toDateString();
          return new Date(r.time).toDateString() === today;
        }).length
      }
    });
  } catch (error) {
    console.error('获取统计数据错误:', error);
    res.status(500).json({
      success: false,
      message: '获取统计数据失败'
    });
  }
});

module.exports = router;