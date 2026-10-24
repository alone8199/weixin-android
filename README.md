# 味信（WeChat 风格）安卓客户端

基于 Flutter 的 Material Design 3 客户端，连接你自己的局域网 Flask + Socket.IO 后端
（网页版同一个服务器）。默认服务器地址为 `http://192.168.1.5:5000`，可在 App 内「我的」页面修改。

## 功能一览
- 聊天：大厅群聊、文件传输助手、与好友的私聊；文字 / 图片 / 文件 / 红包气泡
- 实时：Socket.IO 推送消息、撤回、删除、置顶、正在输入提示、未读红点
- 通讯录：添加 / 删除好友，查看在线状态，一键发起私聊
- 朋友圈：发动态（文字 + 渐变图片）、点赞、评论
- 设置：修改服务器地址、深色模式开关、退出登录
- 视觉：MD3（`useMaterial3: true`、ColorScheme.fromSeed 绿色主题、NavigationBar、FilledButton）

## 目录结构
```
lib/
  constants.dart       # 默认服务器地址、APP 名称、主题色
  socket_service.dart  # AppState 单例：Socket.IO 连接 + 全局状态 + 所有协议方法
  models.dart          # 数据模型（与服务器 JSON 对齐的参考定义）
  utils.dart           # 渐变头像、生成渐变图片 data URL、时间格式化
  main.dart            # MaterialApp + MD3 主题 + 登录/主页路由切换
  screens/
    login.dart        # 登录页（昵称 + 服务器地址，预填 192.168.1.5:5000）
    home.dart         # 底部 NavigationBar（聊天/通讯录/朋友圈/我）
    chat_list.dart    # 会话列表
    chat_detail.dart  # 聊天详情（气泡/发送栏/红包/撤回删除）
    contacts.dart     # 通讯录
    moments.dart      # 朋友圈 + 发表弹窗
    profile.dart      # 我的（服务器地址、深色模式、退出）
android/               # 原生配置（已含 INTERNET 权限 + 明文流量放行）
```

## 构建与运行

### 1. 前置要求
- Flutter SDK（3.16+，已配置 `flutter doctor` 无红叉）
- Android SDK（API 34 平台 + 构建工具）
- 一台安卓设备或模拟器

### 2. 生成 Gradle 包装器（仅需一次）
本工程已经写好了 `android/` 下的原生源码，但 Gradle 包装器的二进制
`android/gradle/wrapper/gradle-wrapper.jar` 无法随文本一起分发。请用下面任意一种方式补齐：

- 方式 A（推荐，不会改动你的代码）：从你电脑上任意一个已有的 Flutter 项目里，
  把它的 `android/gradle/wrapper/gradle-wrapper.jar` 复制过来。
- 方式 B：在空白处执行 `flutter create tmp_app`，然后把 `tmp_app/android/gradle/wrapper/gradle-wrapper.jar`
  复制进本工程的 `android/gradle/wrapper/`。
- 方式 C：直接在本目录执行 `flutter create .`。这会用官方模板重新生成原生文件
  （保留 `lib/`），但会覆盖我们定制过的 `AndroidManifest.xml`。覆盖后请把下面
  「AndroidManifest 关键改动」里的两段内容补回 `android/app/src/main/AndroidManifest.xml`。

> 提示：`flutter create .` 之后如果提示缺少 `local.properties`，正常，
> 执行下一步的 `flutter pub get` / `flutter build apk` 时 Flutter 会自动生成它。

### 3. 安装依赖并打包
```bash
cd weixin-android
flutter pub get
flutter build apk --release      # 产物：build/app/outputs/flutter-apk/app-release.apk
```
装到手机：
```bash
flutter install        # 或手动把 apk 传到手机安装
```

### 4. AndroidManifest 关键改动（已默认写好）
为了让 App 能访问 `http://192.168.1.5:5000` 这种明文局域网地址，manifest 已包含：
```xml
<uses-permission android:name="android.permission.INTERNET" />
...
<application
    ...
    android:usesCleartextTraffic="true">
```
如果 `flutter create .` 覆盖了 manifest，请确认以上两处仍在。

## 连接服务器（局域网）
1. 在电脑上启动你的 Flask + Socket.IO 后端（监听 `0.0.0.0:5000`）。
2. 确认电脑的防火墙放行 5000 端口（入站规则允许 TCP 5000）。
3. 手机与电脑连接到**同一个 Wi-Fi / 同一网段**。
4. 打开 App，默认服务器已是 `http://192.168.1.5:5000`；若你的电脑局域网 IP 不同，
   在「我的 → 服务器地址」里改成实际 IP（如 `http://192.168.0.10:5000`）后保存。
5. 输入昵称，点「进入味信」即可。

## 与后端的协议对齐
客户端 `socket_service.dart` 已按以下事件 / 方法对接（与网页版同源后端一致）：
- 监听事件：`ready / message / message_update / message_deleted / chat_pinned /
  chat_removed / typing / users / moments / contacts / add_result / friend_removed`
- 发送方法：`login / send / open_redpacket / add_friend / remove_friend /
  publish_moment / like_moment / comment_moment / recall / delete_message /
  pin_chat / delete_chat / set_typing`
- 会话 id 规则：`lobby`（大厅）、`self:<昵称>`（文件助手）、`dm:<A>|<B>`（私聊，昵称排序生成稳定 id）

## 自定义
- 改服务器默认值：编辑 `lib/constants.dart` 的 `DEFAULT_SERVER`。
- 改应用包名 / applicationId：同时修改 `pubspec.yaml` 的 `name`、
  `android/app/build.gradle` 的 `applicationId` 与
  `android/app/src/main/kotlin/com/example/weixin_android/MainActivity.kt` 的 `package`。
- 换主题色：修改 `lib/constants.dart` 的 `GREEN_SEED`（当前微信绿 `0xFF07C160`）。
