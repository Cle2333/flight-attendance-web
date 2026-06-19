const express = require('express');
const { recordOperations, settingsOperations, userOperations } = require('../database-simple');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// ==================== 用户信息相关 ====================

// 获取当前用户信息
router.get('/user/profile', authenticate, async (req, res) => {
  try {
    const user = await userOperations.getById(req.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: '用户不存在' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    console.error('获取用户信息错误:', error);
    res.status(500).json({ success: false, message: '获取用户信息失败' });
  }
});

// 更新用户信息
router.put('/user/profile', authenticate, async (req, res) => {
  try {
    const { nickname, avatar } = req.body;
    const updates = {};
    if (nickname) updates.nickname = nickname;
    if (avatar !== undefined) updates.avatar = avatar;

    const user = await userOperations.updateUser(req.userId, updates);
    res.json({ success: true, message: '更新成功', data: user });
  } catch (error) {
    console.error('更新用户信息错误:', error);
    res.status(500).json({ success: false, message: '更新用户信息失败' });
  }
});

// ==================== 打卡记录相关 ====================

// 获取所有打卡记录
router.get('/records', authenticate, async (req, res) => {
  try {
    const records = await recordOperations.getByUserId(req.userId);
    res.json({
      success: true,
      data: records
    });
  } catch (error) {
    console.error('获取记录错误:', error);
    res.status(500).json({
      success: false,
      message: '获取记录失败'
    });
  }
});

// 添加打卡记录
router.post('/records', authenticate, async (req, res) => {
  try {
    const { time, note } = req.body;

    if (!time) {
      return res.status(400).json({
        success: false,
        message: '打卡时间不能为空'
      });
    }

    const result = await recordOperations.add(req.userId, time, note);
    res.json({
      success: true,
      message: '打卡成功',
      data: { id: result.lastInsertRowid }
    });
  } catch (error) {
    console.error('添加记录错误:', error);
    res.status(500).json({
      success: false,
      message: '添加记录失败'
    });
  }
});

// 更新打卡记录
router.put('/records/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { time, note } = req.body;

    if (!time) {
      return res.status(400).json({
        success: false,
        message: '打卡时间不能为空'
      });
    }

    const result = await recordOperations.update(id, req.userId, time, note);

    if (result.changes === 0) {
      return res.status(404).json({
        success: false,
        message: '记录不存在'
      });
    }

    res.json({
      success: true,
      message: '更新成功'
    });
  } catch (error) {
    console.error('更新记录错误:', error);
    res.status(500).json({
      success: false,
      message: '更新记录失败'
    });
  }
});

// 删除打卡记录
router.delete('/records/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await recordOperations.delete(id, req.userId);

    if (result.changes === 0) {
      return res.status(404).json({
        success: false,
        message: '记录不存在'
      });
    }

    res.json({
      success: true,
      message: '删除成功'
    });
  } catch (error) {
    console.error('删除记录错误:', error);
    res.status(500).json({
      success: false,
      message: '删除记录失败'
    });
  }
});

// 同步所有打卡记录（从本地到服务器）
router.post('/records/sync', authenticate, async (req, res) => {
  try {
    const { records } = req.body;

    if (!Array.isArray(records)) {
      return res.status(400).json({
        success: false,
        message: '记录格式错误'
      });
    }

    await recordOperations.syncAll(req.userId, records);

    res.json({
      success: true,
      message: '同步成功',
      data: { count: records.length }
    });
  } catch (error) {
    console.error('同步记录错误:', error);
    res.status(500).json({
      success: false,
      message: '同步记录失败'
    });
  }
});

// ==================== 设置相关 ====================

// 获取用户设置
router.get('/settings', authenticate, async (req, res) => {
  try {
    const settings = await settingsOperations.getByUserId(req.userId);
    res.json({
      success: true,
      data: settings || {
        precision_setting: 'minute',
        effect: 'plane',
        theme: 'dark',
        quotes: ['飞行是对天空的诗意探索。', '天空是飞行员的画布。', '每一次起飞都是一次冒险。']
      }
    });
  } catch (error) {
    console.error('获取设置错误:', error);
    res.status(500).json({
      success: false,
      message: '获取设置失败'
    });
  }
});

// 更新用户设置
router.put('/settings', authenticate, async (req, res) => {
  try {
    const { precision, effect, theme, quotes } = req.body;

    await settingsOperations.update(req.userId, precision, effect, theme, quotes);

    res.json({
      success: true,
      message: '设置保存成功'
    });
  } catch (error) {
    console.error('更新设置错误:', error);
    res.status(500).json({
      success: false,
      message: '更新设置失败'
    });
  }
});

module.exports = router;