const express = require('express');
const { userOperations } = require('../database-simple');
const { generateToken } = require('../middleware/auth');

const router = express.Router();

// 用户注册
router.post('/register', async (req, res) => {
  try {
    const { account, password, nickname } = req.body;

    // 验证输入
    if (!account || !password) {
      return res.status(400).json({
        success: false,
        message: '账号和密码不能为空'
      });
    }

    if (account.length < 3 || account.length > 20) {
      return res.status(400).json({
        success: false,
        message: '账号长度应在3-20个字符之间'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: '密码长度不能少于6个字符'
      });
    }

    // 检查账号是否已存在
    const existingUser = await userOperations.findByAccount(account);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: '账号已存在'
      });
    }

    // 创建用户
    const result = await userOperations.createUser(account, password, nickname);
    const token = generateToken(result.lastInsertRowid, account);

    res.json({
      success: true,
      message: '注册成功',
      data: {
        userId: result.lastInsertRowid,
        account,
        nickname: nickname || account,
        token
      }
    });
  } catch (error) {
    console.error('注册错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误'
    });
  }
});

// 用户登录
router.post('/login', async (req, res) => {
  try {
    const { account, password } = req.body;

    // 验证输入
    if (!account || !password) {
      return res.status(400).json({
        success: false,
        message: '账号和密码不能为空'
      });
    }

    // 查找用户
    const user = await userOperations.findByAccount(account);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: '账号或密码错误'
      });
    }

    // 验证密码
    const isValidPassword = await userOperations.verifyPassword(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: '账号或密码错误'
      });
    }

    // 生成 token
    const token = generateToken(user.id, user.account);

    res.json({
      success: true,
      message: '登录成功',
      data: {
        userId: user.id,
        account: user.account,
        nickname: user.nickname,
        token
      }
    });
  } catch (error) {
    console.error('登录错误:', error);
    res.status(500).json({
      success: false,
      message: '服务器内部错误'
    });
  }
});

module.exports = router;