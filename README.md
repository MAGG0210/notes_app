# 云笔记 (notes_app)

一个基于 **Flutter + Supabase** 的跨端云笔记应用：邮箱登录、云端备份、多端实时同步。

- 🖥️ 支持平台：Android / Web / Windows
- ☁️ 后端：Supabase（PostgreSQL + Auth + Realtime + RLS 行级安全）
- 🔒 数据隔离：每个用户只能读写自己的笔记（行级安全策略）

## 功能特性

- 邮箱 + 密码注册 / 登录（Supabase Auth）
- 笔记的增、删、改、查，云端存储
- **Realtime 实时同步**：任何一端增删改笔记，其他端自动刷新（带防抖合并）
- **搜索**：按标题 / 内容实时搜索过滤
- **标签系统**：笔记可添加多个标签，按标签筛选
- **置顶笔记**：重要笔记置顶显示
- **Markdown 支持**：编辑时实时预览 Markdown 渲染效果
- **回收站**：删除进回收站，可恢复或永久清除
- **账户管理**：修改密码、忘记密码（邮件重置）
- **暗色 / 亮色模式**：跟随系统或手动切换，本地持久化
- **复制 / 导出**：一键复制笔记、分享导出纯文本
- 下拉刷新 / 手动刷新
- 相对时间显示（刚刚 / N 分钟前 / N 小时前 / 日期）
- 登录态全局监听，登出即时生效

## 技术栈

| 层 | 技术 |
|---|---|
| 客户端 | Flutter (Dart SDK ^3.12.2), Material 3 |
| 后端 | Supabase (PostgreSQL, Auth, Realtime) |
| 依赖 | supabase_flutter ^2.8.4, intl, shared_preferences, share_plus, flutter_markdown |

## 项目结构

```
lib/
├── main.dart            应用入口 + 登录态路由（StreamBuilder 监听 Auth 状态）
├── config.dart          Supabase URL / anon key 配置
├── note_service.dart    服务层：认证、笔记 CRUD、回收站、Realtime 订阅封装
├── theme_store.dart     主题模式存储（亮色 / 暗色 / 跟随系统）
├── auth_page.dart       登录 / 注册页（含忘记密码）
├── notes_page.dart      笔记列表页（搜索 / 标签筛选 / Realtime 实时刷新）
├── note_edit_page.dart  新建 / 编辑 / 删除笔记页（标签 / 置顶 / Markdown 预览）
├── trash_page.dart      回收站（恢复 / 永久删除）
└── account_page.dart    账户管理（修改密码）
supabase_schema.sql      Supabase 建表 + RLS 策略 + Realtime + 触发器 SQL
```

## 快速开始

### 1. 搭建 Supabase 后端

1. 在 [Supabase](https://supabase.com) 创建项目。
2. 打开 **SQL Editor**，执行根目录的 [`supabase_schema.sql`](supabase_schema.sql)（建表、索引、RLS 策略、Realtime、`updated_at` 触发器）。
3. 在 **Authentication → Providers** 确认 Email 登录已开启。

### 2. 配置客户端

修改 `lib/config.dart`：

```dart
class SupabaseConfig {
  static const String url = 'https://你的项目.supabase.co';      // Project URL
  static const String anonKey = '你的anon/public key';           // Project API Keys → anon
}
```

### 3. 运行

```bash
flutter pub get
flutter run          # 选择目标设备（Android / Web / Windows）
```

## 安全说明

- 客户端仅使用 Supabase **anon（public）key**，配合数据库 **RLS（行级安全）** 实现数据隔离。
- **切勿**在客户端或仓库中提交 `service_role`（secret）key——该 key 拥有绕过 RLS 的权限。
- 若修改了 `notes` 表结构，请同步更新 RLS 策略，确保所有操作仍受 `auth.uid() = user_id` 约束。

## License

MIT
