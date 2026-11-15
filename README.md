# 依见（Yijian）

**依见 Widegts for Tianyi** —— 一款开源的 HarmonyOS NEXT（纯血鸿蒙）服务卡片（小组件）应用。

帮助用户将喜欢的图片、文字与信息，以简单而自由的方式呈现在桌面上：选择一张图片作为小组件背景，添加任意文字并自由调整位置，点击卡片即可跳转回应用。

- 包名：`com.m1ku.a12.wft`
- 技术栈：ArkTS + ArkUI（纯鸿蒙原生组件，无任何第三方 UI 库）
- 目标系统：HarmonyOS NEXT（API 26，即 26.0.0）
- 卡片尺寸：`2*4`（八宫格）与 `4*4`（十六宫格）

---

## 一、功能特性

| 功能 | 说明 |
| --- | --- |
| 图片背景 | 通过系统相册选择任意图片作为卡片背景 |
| 添加文字 | 自由输入文字，支持颜色、字号设置 |
| 位置自由调整 | 拖拽预览区文字，或使用横/纵滑块微调 |
| 底部自动遮罩 | 文字位于图片底部时，自动叠加半透明渐变遮罩保证可读性 |
| 点击跳转 | 点击卡片跳转到应用主页面（`postCardAction` router 事件） |
| 双尺寸 | 支持 `2*4` 与 `4*4` 两种尺寸 |
| 本地处理 | 无网络依赖，无定时刷新（`updateEnabled = false`），所有内容本地处理 |

---

## 二、目录结构

```
Widgets-for-Tianyi-OHOS/   （仓库根目录）
├── AppScope/
│   ├── app.json5                          # 应用级配置（bundleName 等）
│   └── resources/
│       └── base/
│           ├── element/string.json        # app_name = 依见
│           └── media/app_icon.png         # 应用图标（logo.png）
├── build-profile.json5                    # 工程级构建配置（SDK 26.0.0）
├── hvigorfile.ts                          # 工程级 hvigor 入口
├── hvigor/hvigor-config.json5             # hvigor 配置（modelVersion 26.0.0）
├── oh-package.json5                       # 工程包描述
└── entry/
    ├── build-profile.json5                # 模块构建配置（stageMode，关闭混淆）
    ├── hvigorfile.ts                      # 模块级 hvigor 入口
    ├── oh-package.json5                   # 模块包描述
    ├── obfuscation-rules.txt              # 混淆规则（保持关闭）
    └── src/main/
        ├── module.json5                   # 模块配置（Ability + Form Extension）
        ├── ets/
        │   ├── common/
        │   │   └── WidgetConfig.ets       # 配置持久化 + 卡片数据构建工具
        │   ├── entryability/
        │   │   └── EntryAbility.ets       # 应用入口，处理卡片点击跳转
        │   ├── entryformability/
        │   │   └── EntryFormAbility.ets   # 服务卡片生命周期管理
        │   ├── pages/
        │   │   ├── Index.ets              # 主页（卡片编辑页）
        │   │   └── AboutPage.ets          # 关于页
        │   └── widget/pages/
        │       └── WidgetCard.ets         # 服务卡片 UI
        └── resources/
            ├── base/
            │   ├── element/{string,color}.json
            │   ├── media/                 # icon.png + 11 个官方 SVG 图标
            │   └── profile/
            │       ├── main_pages.json    # 页面路由
            │       └── form_config.json   # 服务卡片配置（核心）
            └── zh_CN/element/string.json
```

---

## 三、如何构建并安装 HAP

> 本仓库交付的是完整 DevEco Studio 工程源码。需使用华为官方 IDE **DevEco Studio（HarmonyOS NEXT，API 26）** 构建。

### 3.1 前置条件

1. 安装 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)（支持 API 26 的版本）。
2. 安装 HarmonyOS NEXT SDK（DevEco Studio 首次启动会引导下载）。
3. 准备一台 HarmonyOS NEXT 真机（或使用模拟器），并完成开发者模式与调试授权。

### 3.2 导入工程

1. 打开 DevEco Studio → `File → Open`，选择本 `yijian` 目录。
2. 等待 IDE 自动同步 hvigor 与 SDK（首次可能较慢）。

### 3.3 配置签名

1. 菜单 `File → Project Structure → Signing Configs`。
2. 勾选 `Automatically generate signature`，登录华为账号后自动生成调试签名。
   - 若需发布上架，请在 AppGallery Connect 创建应用并配置正式签名证书。

### 3.4 构建与安装

1. 连接真机（或启动模拟器）。
2. 点击工具栏 `Run`（▶）按钮，IDE 会自动编译并安装到设备。
3. 手动出包：菜单 `Build → Build Hap(s)/App(s) → Build Hap(s)`，产物位于
   `yijian/entry/build/default/outputs/default/entry-default-signed.hap`。

### 3.5 使用步骤

1. 打开「依见」应用，在主页编辑卡片内容（选图、加文字、调位置）。
2. 点击「应用到卡片」保存配置。
3. 回到桌面，长按空白处 → 添加服务卡片 → 找到「依见」，选择 `2*4` 或 `4*4` 尺寸添加。
4. 若卡片已添加后再修改内容，再次点击「应用到卡片」即可主动刷新所有已添加的卡片。

---

## 四、关键技术实现说明

### 4.1 卡片配置（form_config.json）

`entry/src/main/resources/base/profile/form_config.json` 定义了一个卡片 `widget_card`：

- `src` 指向卡片 UI `./ets/widget/pages/WidgetCard.ets`（ArkTS 动态卡片）。
- `isDynamic: true` 表示动态卡片，支持 `postCardAction` 点击跳转。
- `updateEnabled: false` 关闭定时刷新（本应用由用户主动刷新）。
- `supportDimensions: ["2*4", "4*4"]` 支持两种尺寸。

### 4.2 数据传递链路（主页 → 卡片）

```
主页「应用到卡片」
  → WidgetStore.writeConfig()           写配置到 filesDir/widget_config.json
  → WidgetStore.buildFormData()         读配置 + 打开背景图 fd
  → formProvider.updateForm(formId, data)  主动刷新卡片
  → 卡片 @LocalStorageProp 接收字段     渲染 UI
```

### 4.3 图片进卡片（核心机制）

HarmonyOS NEXT 服务卡片内不能直接使用应用沙箱的 `file://` 路径加载图片，正确做法是**通过文件描述符（fd）传递**：

1. `FormExtensionAbility`（或主页）用 `fileIo.openSync(path)` 打开背景图拿到 `fd`。
2. 数据对象必须包含两个固定字段：
   - `imgName: string` —— 与 `formImages` 的 key 同名；
   - `formImages: Record<string, number>` —— key 为 `imgName`，value 为 `fd`。
3. 卡片页面用 `Image('memory://' + imgName)` 显示图片。
4. **注意**：`imgName` 每次刷新必须不同，否则图片不会更新（本项目每次生成 `bg_时间戳_随机数`）。

### 4.4 formId 追踪

普通应用无法调用 `formHost.getRunningFormInfos()`（系统 API）。本项目在 `onAddForm(want)` 中通过
`want.parameters[formInfo.FormParam.IDENTITY_KEY]` 获取 formId 并持久化到 `filesDir/form_ids.json`，
主页「应用到卡片」时遍历该列表逐个 `updateForm` 刷新。

### 4.5 文字自由定位

`textPosX / textPosY` 表示文字左上角锚点的归一化坐标（0~1），卡片与预览均用
`.position({ x: textPosX * 100 + '%', y: textPosY * 100 + '%' })` 渲染，保证预览与卡片效果一致。

### 4.6 底部自动遮罩

当 `textPosY >= 0.55`（文字位于图片下方区域）时，卡片底部叠加一条透明→半透明黑的
`linearGradient` 遮罩，保证浅色文字在任意背景图上都可读。

---

## 五、权限与能力声明

本应用**无需申请任何系统权限**：

- 图片选择使用系统 `PhotoViewPicker`（`@kit.CoreFileKit`），系统会临时授权所选图片的读取权限，无需 `ohos.permission.READ_MEDIA`。
- 无网络访问（无 `ohos.permission.INTERNET`）。
- 服务卡片通过 `extensionAbilities` 声明 `type: "form"`，无需额外权限。

---

## 六、版本信息

- 应用版本：`1.0.0`（versionCode 1000000）
- 关于页展示版本号：`Harmony OS_1.0_ver`
- 作者：`m1ku_a12`
