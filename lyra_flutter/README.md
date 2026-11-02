# Lyra（暂名）· Flutter 移动端

按 `deliverables/lyra-mobile-ui-v4.zip` 里的高保真原型与 `DESIGN.md` 实现的完整前端，全部使用 mock 数据，接口后续对接。

- 零第三方依赖（只用 Flutter SDK），避免版本冲突。
- 状态集中在 `lib/core/state.dart`（`AppState`，`ChangeNotifier`）；UI 通过 `context.app` 读写。
- 主题、主题色、底栏样式、皮肤、字体等设置实时生效。

## 运行

```bash
cd lyra_flutter
flutter create . --platforms=android,ios,web --project-name lyra --org app.lyra   # 第一次：生成平台目录，不会覆盖 lib/
flutter pub get
flutter run                 # 真机 / 模拟器
flutter run -d chrome       # Web
```

Web 端可以用 `?shot=<状态>` 直接打开某个页面（用于截图和走查），例如：

| URL 参数 | 打开 |
|---|---|
| `?shot=login` / `forgot` / `disclaimer` | 登录流程 |
| `?shot=discover` · `discover.nologin` · `discover.qq` · `discover.light` | 发现页（已登录 / 未登录 / QQ / 浅色） |
| `?shot=search` · `daily` · `library.pl` · `library.local` · `me` · `me.clip` | 各 Tab（`me.clip` 带剪贴板口令横幅） |
| `?shot=player.<皮肤>` | 播放器，皮肤 id 见 `lib/data/mock.dart` 的 `skins` |
| `?shot=sheet.<名称>` | more / import / platlogin / eq / skins / bars / icons / queue / home / quality |
| 修饰符 | `.light` 浅色、`.acc2` 第 3 个主题色、`.bar-island` 底栏样式、`.paused` 暂停 |

CI（`.github/workflows/lyra-flutter.yml`）每次推送会跑 `flutter analyze`、`flutter test`、Web 构建 + 54 个状态截图、Android APK，产物在 Actions 页面的 Artifacts 里下载（`shots`、`apk`）。

## 目录

```
lib/
  main.dart                 入口：AppScope → MaterialApp → 鉴权 / 主界面
  core/
    tokens.dart             设计令牌（深浅色、6 种主题色、动效曲线、设置图标色）
    state.dart              AppState：播放、设置、平台登录、队列、歌单……（对应原型 core.js 的 S / ACT）
    shots.dart              ?shot= 演示入口
  data/
    models.dart             Song / Playlist / LyricLine / Platform / Script / Skin …
    mock.dart               全部 mock 数据（与原型 data.js / v4.js 一致）
  ui/
    kit.dart                通用组件：Press 按压、Btn、LChip、Seg、LSwitch、LSlider、Group/Item、SongRow（左滑操作）、
                            HeartBtn、Marquee、Glass、Rise 浮现、CountUp、Shimmer 骨架屏、Toast、showLSheet、showLDialog
    cover.dart              按色相生成的渐变封面（接入真实封面后作为占位 / 兜底）
    brand.dart              App 图标 8 款（竖琴 + 织女星）、环境光背景
    icons.dart              图标名 → Material Rounded
  shell/
    shell.dart              外壳：嵌套 Navigator（二级页推入 + 左缘返回）、迷你播放条、底栏、滚动收起
    nav.dart                9 种底栏：液态玻璃 / 浮岛 / 胶囊 / 磨砂一体 / 经典 / 凹槽 / 程序坞 / 气泡 / 纯文字
    mini.dart               迷你播放条（左右滑切歌、上滑打开播放器）
    clip_banner.dart        剪贴板口令横幅
  pages/
    discover.dart           发现（源条、未登录登录卡、Banner、为你定制、我的歌单、精选/榜单/歌单、平台推荐区）
    search.dart             搜索（底部输入栏 + 唱片圆钮、联想、结果页：类型 Tab + 平台筛选 + 相关搜索）
    daily.dart / library.dart / me.dart
    detail.dart             歌单详情（多选）、歌手、听歌统计
    settings.dart           外观与界面、歌词、系统歌词、播放与音质、智能换源、平台与解析脚本（导入音源）
    misc.dart               公告、平台账号、下载、账号中心、登录设备、备份与同步、音乐云盘（WebDAV）、关于
    scan.dart               扫一扫 + 听歌识曲
    common.dart             TabPage（大标题折叠、回到顶部、下拉刷新）/ SubPage（视差头图）
  widgets/
    picker.dart             音源选择器（平台 → 解析脚本，从源条展开）
    sheets.dart             全部 Sheet：歌曲更多、加入/新建/导入歌单、平台登录、分享口令、定时、均衡器、音质、倍速、
                            投放、歌词卡、播放链路、队列（拖动排序）、底栏样式、App 图标、字体；LField 输入框
  auth/auth.dart            使用须知、登录 / 注册（通用人机验证：图形字符 / 滑块拼图 / 文字点选）、找回密码、版本停用
  player/
    player.dart             播放器路由（升起 / 下拉关闭）、背景层、顶栏 / 信息 / 进度 / 主控 / 辅助行、歌词快调
    lyrics.dart             歌词引擎：瀑布弹簧、逐字填充 + 辉光、距离模糊、点按跳转、手动拖动 + 4s 回弹、波浪漂浮
    skins.dart              15 套皮肤 + 缩略图
    particles.dart          粒子舞台（星系 / 事件视界 / 全息地球 / 陀螺核心，可拖动旋转）
```

## 对接接口

UI 不直接读 mock：所有数据都经过 `AppState` 或 `mock.dart` 的常量。建议的替换顺序：

1. 新建 `lib/data/repo.dart`，定义 `abstract class Repo { Future<List<Song>> daily(); Future<SearchResult> search(String q, {String type, String platform}); … }`，先写一个 `MockRepo` 返回现在的常量。
2. 在 `AppState` 里注入 `Repo`，把 `listOf()`、`switchPlatform()`、`reload()`、`login()` 等方法改成调用 `Repo`（它们已经是异步 / 带 loading 状态的写法）。
3. 播放：`AppState._tick()` 现在用计时器模拟进度。接入 `just_audio` / `audio_service` 后，把 `pos`、`playing`、`next()`、`seek()` 改成驱动播放器即可，歌词、进度条、皮肤都只监听 `pos`。
4. 封面：`Cover` 组件保留为占位；有图片 URL 后包一层 `Image.network`，加载失败时回退到渐变封面。
5. 设置持久化：`Settings` 是普通字段，接 `shared_preferences` 时在 `AppState.update()` 里统一保存。

## 已知限制

- 播放为计时模拟，没有声音；均衡器、投放、识曲、扫码都是界面与流程演示。
- 粒子皮肤用 Canvas 画 2600 点，正式版建议改为 `FragmentProgram` 复用桌面端 GLSL。
- 字体「圆润 / 书卷 / 楷意 / 等宽」依赖设备上已有的字体；需要统一效果时把字体文件放进 `assets/fonts` 并在 `pubspec.yaml` 声明。
- 平板双栏布局未实现（DESIGN.md 第 10 节只给了规则）。
