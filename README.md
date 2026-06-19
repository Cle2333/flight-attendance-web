# 航班打卡

一个有趣的生活记录应用，用"起飞"来记录你的每一次重要时刻。

> **状态：前端已迁移至 Flutter**（`app/`），后端已迁移至 **Spring Boot + MariaDB**（`server/`）。
>
> 旧的 `index.html` / `admin.html` 仍然存在于仓库根目录，仅作历史参考 —— 它们**已不再维护**。Spring Boot 同时会把它们作为静态资源 serve 出去（用同一个端口），所以 `admin.html` 仍然可用。Flutter App 不再使用它们。

## 功能特性

- **双击起飞** — 双击屏幕即可打卡，带粒子特效
- **起飞记录** — 日历视图查看历史记录，支持周/月切换
- **起飞感受** — 打卡后可选择感受或自定义填写
- **排行榜** — 查看自己和朋友的起飞次数
- **个人设置** — 自定义昵称、头像、计时精度、起飞特效、机长语录
- **云端同步** — 登录账号后数据自动同步到服务器
- **本地模式** — 无需登录，数据保存在设备本地
- **后台管理（web）** — 管理员可查看统计数据和管理用户（沿用旧 `admin.html`）

## 技术栈

- **前端（App）**：Flutter 3.44+，GetX 状态管理 + 路由
- **后端**：Spring Boot 3.3 + Java 17 + Spring Data JPA + Spring Security（仅 BCrypt + JWT 过滤器）
- **数据库**：MariaDB 10.5+（本地开发可用 docker compose 一键起）
- **迁移**：Flyway
- **认证**：JWT (jjwt 0.12)
- **CI**：GitHub Actions（同时构建 Spring Boot JAR 和 Flutter APK）

## 目录结构

```
flight-attendance-web/
├── app/                  # Flutter 前端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── api/          # HTTP 客户端
│   │   ├── models/
│   │   ├── screens/      # 登录 / 首页 / 记录 / 排行 / 我的
│   │   ├── state/        # AppState (GetxController)
│   │   ├── storage/      # SharedPreferences 封装
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/      # 粒子 / 日历 / 起飞遮罩 / 选择器
│   ├── android/
│   ├── pubspec.yaml
│   └── ...
├── server/               # Spring Boot 后端
│   ├── pom.xml
│   ├── Dockerfile
│   ├── docker-compose.yml # 本地起 MariaDB
│   ├── src/main/java/com/cle2333/flightattendance/
│   │   ├── FlightAttendanceApplication.java
│   │   ├── config/        # SecurityConfig, StaticResourceConfig
│   │   ├── controller/    # Auth/User/Record/Settings/Admin/Test
│   │   ├── dto/
│   │   ├── entity/        # User, Record, Settings
│   │   ├── exception/
│   │   ├── repository/
│   │   ├── security/      # JwtTokenProvider, JwtAuthenticationFilter
│   │   └── service/
│   ├── src/main/resources/
│   │   ├── application.yml        # 公共配置
│   │   ├── application-dev.yml    # 默认 profile，连 MariaDB
│   │   ├── application-prod.yml   # 生产 profile
│   │   ├── application-test.yml   # H2，集成测试用
│   │   └── db/migration/V1__init.sql
│   └── src/test/java/...
├── .github/workflows/
│   └── build.yml          # CI: server JAR + app APK
├── admin.html             # ⚠️ 旧 web 后台（Spring Boot 仍会 serve）
├── index.html             # ⚠️ 旧 web 前端（仅参考）
└── README.md
```

## 快速开始

### 1. 启动 MariaDB

最方便是用项目自带的 `docker-compose.yml`：

```bash
cd server
docker compose up -d
# 等待 healthcheck 通过（约 5-10 秒）
```

手动安装的 MariaDB 也可以，创建一个 `flight_attendance` 库即可。

### 2. 启动后端

```bash
cd server
./mvnw spring-boot:run
# 或
./mvnw -DskipTests package && java -jar target/flight-attendance-server.jar
```

默认监听 `http://localhost:8080`：

- API 根：`http://localhost:8080/api/`
- 测试：`curl http://localhost:8080/api/test`
- 旧 web 前台：`http://localhost:8080/index.html`（已废弃）
- 旧 web 后台：`http://localhost:8080/admin.html`（默认密码 `admin123`）

第一次启动会自动跑 Flyway 迁移（`V1__init.sql`），建好三张表。

### 3. 运行 Flutter 前端

```bash
cd app
flutter pub get
flutter run
```

### 4. 在 App 内配置后端地址

App 启动后：

- 登录页右上角 ⚙️ 打开"服务器设置"
- Android **模拟器**：填 `http://10.0.2.2:8080`
- Android **真机**：填运行后端的机器的局域网 IP，例如 `http://192.168.1.100:8080`

也可用 `--dart-define` 在启动时设置：

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8080
```

## API 接口

后端 API 与原 Node.js 版**完全一致**，Flutter 前端无需改动：

- `POST /api/auth/register` — 注册
- `POST /api/auth/login` — 登录
- `GET  /api/user/profile` — 获取用户信息（需鉴权）
- `PUT  /api/user/profile` — 更新用户信息（需鉴权）
- `GET  /api/records` — 列出所有打卡记录（需鉴权）
- `POST /api/records` — 新增打卡记录（需鉴权）
- `PUT  /api/records/:id` — 更新打卡记录（需鉴权）
- `DELETE /api/records/:id` — 删除打卡记录（需鉴权）
- `POST /api/records/sync` — 同步本地记录到云端（需鉴权）
- `GET  /api/settings` — 获取用户设置（需鉴权）
- `PUT  /api/settings` — 更新用户设置（需鉴权）
- `GET  /api/admin/leaderboard?type=week|all` — 排行榜
- `GET  /api/admin/stats` — 管理员统计

统一响应包络：
```json
{ "success": true,  "data": { ... } }
{ "success": false, "message": "错误说明" }
```

## ⚠️ 安全说明

**`/api/admin/**` 当前没有任何鉴权**。这是为了和原 Node.js 后端行为完全一致（`admin.html` 里的"登录"是纯前端校验，admin 路由在 Node 端也没有鉴权）。

生产环境**必须**在 `AdminController` 加鉴权，可选方案：
- HTTP Basic Auth（最简单）
- 单独的 admin JWT（`/api/auth/admin-login` 返回带 `role: admin` 的 token）
- 内网白名单（`SecurityConfig` 里按 IP 放行 `/api/admin/**`）

> 相关的 issue / PR 跟踪中。

## 配置项

| 配置项 | 默认值 | 说明 |
|---|---|---|
| `SERVER_PORT` | 8080 | HTTP 端口 |
| `DB_URL` | `jdbc:mariadb://localhost:3306/flight_attendance?...` | JDBC URL |
| `DB_USER` | `flight` | 数据库用户 |
| `DB_PASSWORD` | `flight` | 数据库密码 |
| `JWT_SECRET` | 占位（dev 提示） | JWT 签名密钥，**生产必改 ≥32 字符随机** |
| `JWT_EXPIRATION_HOURS` | 168 | token 有效期（小时） |
| `ADMIN_PASSWORD` | `admin123` | 旧 `admin.html` 前端校验使用 |
| `STATIC_DIR` | `..` | 静态资源根目录（serve 旧 `index.html` / `admin.html`） |
| `SPRING_PROFILES_ACTIVE` | `dev` | 当前 profile：dev / prod / test |

全部都可用环境变量注入，遵循 Spring Boot 标准 relaxed binding（`SPRING_DATASOURCE_URL` 或 `DB_URL` 都行）。

## 构建 / CI

### 本地构建

```bash
# 后端
cd server
./mvnw -DskipTests package
# 产物：target/flight-attendance-server.jar （fat jar，约 55MB）

# 前端 APK —— 见 app/README
```

### Docker

```bash
cd server
docker build -t flight-attendance-server .
docker run --rm -p 8080:8080 \
  -e DB_URL=jdbc:mariadb://host.docker.internal:3306/flight_attendance \
  -e DB_USER=flight -e DB_PASSWORD=flight \
  -e JWT_SECRET=$(openssl rand -hex 32) \
  flight-attendance-server
```

### GitHub Actions

`.github/workflows/build.yml` 会：

1. **Server job**：Maven 跑 `verify` + `package`，上传 `server-jar` artifact
2. **App job**（依赖 server 成功）：Flutter `analyze` + `test` + `build apk --release`，上传 `app-release` + `app-mapping` artifacts

触发条件：push 到 `master`/`main`、打 `v*` tag、PR、手动触发。

## 部署建议

- **数据库**：阿里云 RDS for MariaDB、腾讯云 TencentDB for MariaDB、自建都行
- **后端**：直接 `java -jar` 或用项目里的 `Dockerfile` 打镜像
- **App**：通过 GitHub Actions 拿 `app-release` artifact 分发（TestFlight / 蒲公英 / 直接 adb install）

## License

MIT
