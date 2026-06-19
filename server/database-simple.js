const fs = require('fs').promises;
const path = require('path');
const bcrypt = require('bcryptjs');

const DB_PATH = path.join(__dirname, 'data');

// 文件锁机制，防止并发读写冲突
const fileLocks = new Map();

async function acquireLock(filePath) {
  while (fileLocks.has(filePath)) {
    await new Promise(resolve => setTimeout(resolve, 10));
  }
  fileLocks.set(filePath, true);
}

function releaseLock(filePath) {
  fileLocks.delete(filePath);
}

// 确保数据目录存在
async function ensureDir(dirPath) {
  try {
    await fs.access(dirPath);
  } catch (error) {
    await fs.mkdir(dirPath, { recursive: true });
  }
}

// 数据文件路径
const USERS_FILE = path.join(DB_PATH, 'users.json');
const RECORDS_DIR = path.join(DB_PATH, 'records');
const SETTINGS_DIR = path.join(DB_PATH, 'settings');

// 初始化目录
async function initDirs() {
  await ensureDir(DB_PATH);
  await ensureDir(RECORDS_DIR);
  await ensureDir(SETTINGS_DIR);
}

// 读取JSON文件（异步）
async function readJSON(filePath) {
  await acquireLock(filePath);
  try {
    try {
      await fs.access(filePath);
      const data = await fs.readFile(filePath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      // 文件不存在返回 null
      return null;
    }
  } catch (error) {
    console.error(`读取文件失败 ${filePath}:`, error);
    return null;
  } finally {
    releaseLock(filePath);
  }
}

// 写入JSON文件（异步）
async function writeJSON(filePath, data) {
  await acquireLock(filePath);
  try {
    // 先写入临时文件，再重命名，确保原子性
    const tempPath = filePath + '.tmp';
    await fs.writeFile(tempPath, JSON.stringify(data, null, 2), 'utf8');
    await fs.rename(tempPath, filePath);
    return true;
  } catch (error) {
    console.error(`写入文件失败 ${filePath}:`, error);
    return false;
  } finally {
    releaseLock(filePath);
  }
}

// 获取用户记录文件路径
function getRecordsFile(userId) {
  return path.join(RECORDS_DIR, `user_${userId}.json`);
}

// 获取用户设置文件路径
function getSettingsFile(userId) {
  return path.join(SETTINGS_DIR, `user_${userId}.json`);
}

// 初始化数据文件
async function initDatabase() {
  await initDirs();
  const users = await readJSON(USERS_FILE);
  if (!users) {
    await writeJSON(USERS_FILE, []);
  }
  console.log('数据库初始化完成');
}

// 用户相关操作
const userOperations = {
  // 创建用户
  createUser: async (account, password, nickname) => {
    const users = await readJSON(USERS_FILE) || [];

    // 检查账号是否已存在
    if (users.find(u => u.account === account)) {
      throw new Error('账号已存在');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = {
      id: users.length > 0 ? Math.max(...users.map(u => u.id)) + 1 : 1,
      account,
      nickname: nickname || account,
      password: hashedPassword,
      created_at: new Date().toISOString()
    };

    users.push(newUser);
    await writeJSON(USERS_FILE, users);

    // 创建用户默认设置文件
    const settingsFile = getSettingsFile(newUser.id);
    const defaultSettings = {
      user_id: newUser.id,
      precision_setting: 'second',
      effect: 'plane',
      effectEmoji: '✈️',
      quotes: ['飞行是对天空的诗意探索。', '天空是飞行员的画布。', '每一次起飞都是一次冒险。']
    };
    await writeJSON(settingsFile, defaultSettings);

    // 创建用户空记录文件
    const recordsFile = getRecordsFile(newUser.id);
    await writeJSON(recordsFile, []);

    return { lastInsertRowid: newUser.id };
  },

  // 查找用户（通过账号）
  findByAccount: async (account) => {
    const users = await readJSON(USERS_FILE) || [];
    return users.find(u => u.account === account);
  },

  // 获取所有用户
  getAll: async () => {
    const users = await readJSON(USERS_FILE) || [];
    return users.map(u => ({ id: u.id, account: u.account, nickname: u.nickname, avatar: u.avatar, created_at: u.created_at }));
  },

  // 获取用户信息
  getById: async (userId) => {
    const users = await readJSON(USERS_FILE) || [];
    const user = users.find(u => u.id === parseInt(userId));
    if (!user) return null;
    return { id: user.id, account: user.account, nickname: user.nickname, avatar: user.avatar, created_at: user.created_at };
  },

  // 更新用户信息
  updateUser: async (userId, updates) => {
    const users = await readJSON(USERS_FILE) || [];
    const index = users.findIndex(u => u.id === parseInt(userId));
    if (index === -1) {
      throw new Error('用户不存在');
    }
    if (updates.nickname) users[index].nickname = updates.nickname;
    if (updates.avatar !== undefined) users[index].avatar = updates.avatar;
    await writeJSON(USERS_FILE, users);
    return { id: users[index].id, account: users[index].account, nickname: users[index].nickname, avatar: users[index].avatar };
  },

  // 删除用户
  delete: async (userId) => {
    const users = await readJSON(USERS_FILE) || [];
    const index = users.findIndex(u => u.id === parseInt(userId));
    if (index === -1) {
      return { changes: 0 };
    }
    users.splice(index, 1);
    await writeJSON(USERS_FILE, users);
    return { changes: 1 };
  },

  // 验证密码
  verifyPassword: async (password, hashedPassword) => {
    return await bcrypt.compare(password, hashedPassword);
  }
};

// 打卡记录相关操作
const recordOperations = {
  // 获取用户所有记录
  getByUserId: async (userId) => {
    const recordsFile = getRecordsFile(userId);
    const records = await readJSON(recordsFile) || [];
    return records.sort((a, b) => new Date(a.time) - new Date(b.time));
  },

  // 添加记录
  add: async (userId, time, note) => {
    const recordsFile = getRecordsFile(userId);
    const records = await readJSON(recordsFile) || [];
    
    const newRecord = {
      id: records.length > 0 ? Math.max(...records.map(r => r.id)) + 1 : 1,
      user_id: userId,
      time,
      note: note || '',
      created_at: new Date().toISOString()
    };
    
    records.push(newRecord);
    await writeJSON(recordsFile, records);
    return { lastInsertRowid: newRecord.id };
  },

  // 更新记录
  update: async (recordId, userId, time, note) => {
    const recordsFile = getRecordsFile(userId);
    const records = await readJSON(recordsFile) || [];

    const index = records.findIndex(r => r.id === parseInt(recordId));

    if (index === -1) {
      return { changes: 0 };
    }

    records[index].time = time;
    records[index].note = note;
    await writeJSON(recordsFile, records);
    return { changes: 1 };
  },

  // 删除记录
  delete: async (recordId, userId) => {
    const recordsFile = getRecordsFile(userId);
    const records = await readJSON(recordsFile) || [];

    const index = records.findIndex(r => r.id === parseInt(recordId));

    if (index === -1) {
      return { changes: 0 };
    }

    records.splice(index, 1);
    await writeJSON(recordsFile, records);
    return { changes: 1 };
  },

  // 批量同步记录（替换式）
  syncAll: async (userId, newRecords) => {
    const recordsFile = getRecordsFile(userId);
    
    // 直接用新记录替换旧记录
    const records = newRecords.map((record, index) => ({
      id: index + 1,
      user_id: userId,
      time: record.time,
      note: record.note || '打卡成功',
      created_at: new Date().toISOString()
    }));
    
    await writeJSON(recordsFile, records);
    return { changes: records.length };
  }
};

// 设置相关操作
const settingsOperations = {
  // 获取用户设置
  getByUserId: async (userId) => {
    const settingsFile = getSettingsFile(userId);
    const userSettings = await readJSON(settingsFile);
    
    if (userSettings) {
      // 确保quotes是数组
      if (typeof userSettings.quotes === 'string') {
        userSettings.quotes = userSettings.quotes.split('\\n').filter(Boolean);
      }
      return userSettings;
    }
    
    return null;
  },

  // 更新设置
  update: async (userId, precision, effect, theme, quotes) => {
    const settingsFile = getSettingsFile(userId);
    const settings = await readJSON(settingsFile);
    
    if (!settings) {
      return { changes: 0 };
    }
    
    settings.precision_setting = precision;
    settings.effect = effect;
    settings.theme = theme || 'dark';
    settings.quotes = Array.isArray(quotes) ? quotes.join('\\n') : quotes;
    
    await writeJSON(settingsFile, settings);
    return { changes: 1 };
  }
};

module.exports = {
  initDatabase,
  userOperations,
  recordOperations,
  settingsOperations
};