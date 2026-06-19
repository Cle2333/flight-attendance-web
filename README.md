# 航班打卡

一个有趣的生活记录应用，用"起飞"来记录你的每一次重要时刻。

## 功能特性

- **双击起飞** - 双击屏幕即可打卡，带粒子特效
- **起飞记录** - 日历视图查看历史记录，支持周/月切换
- **起飞感受** - 打卡后可选择感受或自定义填写
- **排行榜** - 查看自己和朋友的起飞次数
- **个人设置** - 自定义昵称、头像、计时精度、起飞特效、机长语录
- **云端同步** - 登录账号后数据自动同步到服务器
- **本地模式** - 无需登录，数据保存在浏览器本地
- **后台管理** - 管理员可查看统计数据和管理用户

## 技术栈

- **前端**: 纯 HTML/CSS/JavaScript（无框架依赖）
- **后端**: Node.js + Express
- **数据库**: JSON 文件存储
- **认证**: JWT Token

## 快速开始

### 1. 安装依赖

```bash
cd server
npm install
```

### 2. 启动服务器

```bash
node index.js
```

服务器默认运行在 `http://localhost:8080`

### 3. 访问应用

- **前台**: http://localhost:8080
- **后台管理**: http://localhost:8080/admin.html（默认密码: admin123）

## 部署到服务器

### 方案一：云服务器部署

#### 1. 购买云服务器

推荐阿里云、腾讯云等平台，1核2G配置即可。

#### 2. 安装 Node.js

```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs
```

#### 3. 上传项目

```bash
# 在本地打包
cd attendance-web
tar -czf attendance-web.tar.gz --exclude=node_modules --exclude=server/data .

# 上传到服务器
scp attendance-web.tar.gz root@your-server-ip:/var/www/

# 在服务器上解压
ssh root@your-server-ip
cd /var/www
tar -xzf attendance-web.tar.gz
```

#### 4. 安装依赖并启动

```bash
cd /var/www/server
npm install

# 使用 PM2 管理进程
npm install -g pm2
pm2 start index.js --name attendance-web
pm2 save
pm2 startup
```

#### 5. 配置域名（可选）

购买域名后，在域名管理后台添加 A 记录指向服务器 IP。

### 方案二：宝塔面板部署

1. 安装宝塔面板：https://www.bt.cn/
2. 通过宝塔安装 Node.js 环境
3. 上传项目文件
4. 使用 PM2 启动应用
5. 配置反向代理（如需域名访问）

### 方案三：Docker 部署

```bash
# 构建镜像
docker build -t attendance-web .

# 运行容器
docker run -d -p 8080:8080 --name attendance-web attendance-web
```

## 环境变量

可以在 `server/index.js` 中修改以下配置：

```javascript
const PORT = 8080;           // 服务器端口
const JWT_SECRET = 'your-secret-key';  // JWT 密钥（建议修改）
const ADMIN_PASSWORD = 'admin123';     // 管理员密码（建议修改）
```

## 项目结构

```
attendance-web/
├── index.html          # 前端主页面
├── admin.html          # 后台管理页面
├── server/
│   ├── index.js        # 服务器入口
│   ├── database-simple.js  # 数据库操作
│   ├── routes/
│   │   ├── auth.js     # 认证路由
│   │   ├── api.js      # API 路由
│   │   └── admin.js    # 管理员路由
│   └── middleware/
│       └── auth.js     # 认证中间件
└── package.json
```

## 注意事项

- 首次运行会自动创建数据目录
- 生产环境建议修改 JWT 密钥和管理员密码
- 建议使用 HTTPS（可通过 Nginx 反向代理配置）
- 定期备份 `server/data/` 目录

## License

MIT
