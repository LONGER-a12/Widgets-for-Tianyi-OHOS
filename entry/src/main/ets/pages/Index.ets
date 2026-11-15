// 主页面：服务卡片（小组件）编辑页面
// 功能：选择背景图片、添加/调整文字、预览效果、应用到桌面卡片
import { router, promptAction } from '@kit.ArkUI';
import { picker, fileUri, fileIo } from '@kit.CoreFileKit';
import { formProvider } from '@kit.FormKit';
import { WidgetConfigData, WidgetStore } from '../common/WidgetConfig';

@Entry
@Component
struct Index {
  // ===== 编辑状态（与 WidgetConfigData 字段一一对应）=====
  @State text: string = '';           // 文字内容
  @State textPosX: number = 0.5;      // 文字左上角横向归一化坐标 [0,1]
  @State textPosY: number = 0.5;      // 文字左上角纵向归一化坐标 [0,1]
  @State textColor: string = '#FFFFFF'; // 文字颜色
  @State textSize: number = 24;       // 文字字号
  @State hasImage: boolean = false;   // 是否已有背景图片
  @State bgUri: string = '';          // 预览用的 file:// URI

  // 预览区域固定尺寸（与 2*4 卡片 2:1 宽高比一致：2 行 × 4 列，横向卡片，用于拖拽换算）
  private readonly previewW: number = 320;
  private readonly previewH: number = 160;

  // 拖拽起始位置（PanGesture onActionStart 记录）
  private dragStartX: number = 0.5;
  private dragStartY: number = 0.5;

  // 预设颜色色板
  private presetColors: string[] = ['#FFFFFF', '#000000', '#FF5252', '#FFC107', '#4CAF50', '#3D8BFF', '#FF6EC7'];

  aboutToAppear(): void {
    // 读取已保存的配置，恢复编辑状态
    const ctx = getContext(this);
    const cfg = WidgetStore.readConfig(ctx);
    this.text = cfg.text;
    this.textPosX = cfg.textPosX;
    this.textPosY = cfg.textPosY;
    this.textColor = cfg.textColor;
    this.textSize = cfg.textSize;
    this.hasImage = cfg.hasImage;
    if (cfg.hasImage) {
      this.bgUri = fileUri.getUriFromPath(WidgetStore.getBgPath(ctx));
    }
  }

  // 选择背景图片
  private async selectImage(): Promise<void> {
    const options = new picker.PhotoSelectOptions();
    options.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    const photoPicker = new picker.PhotoViewPicker();
    try {
      const result = await photoPicker.select(options);
      if (result.photoUris && result.photoUris.length > 0) {
        const ok = WidgetStore.copyBgImage(getContext(this), result.photoUris[0]);
        if (ok) {
          this.hasImage = true;
          this.bgUri = fileUri.getUriFromPath(WidgetStore.getBgPath(getContext(this)));
          this.showToast('背景图片已选择');
        } else {
          this.showToast('图片读取失败，请重试');
        }
      }
    } catch (e) {
      // 用户取消选择，忽略
    }
  }

  // 清除背景图片
  private clearImage(): void {
    this.hasImage = false;
    this.bgUri = '';
    this.showToast('已清除背景图片');
  }

  // 将当前编辑内容应用到桌面卡片
  private async applyToCard(): Promise<void> {
    const ctx = getContext(this);
    // 1. 保存配置到本地
    const cfg = new WidgetConfigData();
    cfg.text = this.text;
    cfg.textPosX = this.textPosX;
    cfg.textPosY = this.textPosY;
    cfg.textColor = this.textColor;
    cfg.textSize = this.textSize;
    cfg.hasImage = this.hasImage;
    WidgetStore.writeConfig(ctx, cfg);

    // 2. 获取已添加到桌面的卡片 formId 列表
    const ids = WidgetStore.readFormIds(ctx);
    if (ids.length === 0) {
      this.showToast('请先在桌面添加「依见」卡片');
      return;
    }

    // 3. 逐个刷新卡片
    let ok = 0;
    for (const id of ids) {
      const pack = WidgetStore.buildFormData(ctx);
      try {
        await formProvider.updateForm(id, pack.data);
        ok++;
      } catch (e) {
        // 单个卡片更新失败不阻断整体流程
      }
      // 更新完成后关闭本次打开的 fd（每次 update 都用全新 fd，因 fd 有读偏移）
      for (const f of pack.files) {
        fileIo.closeSync(f);
      }
    }
    this.showToast('已应用到 ' + ok + ' 个卡片');
  }

  private showToast(msg: string): void {
    promptAction.showToast({ message: msg, duration: 2000 });
  }

  // ===== 顶部标题栏 =====
  @Builder
  buildTitleBar() {
    Row() {
      Text('依见 Widegts for Tianyi')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .layoutWeight(1)
      Text('2×4 / 4×4')
        .fontSize(12)
        .fontColor('#888888')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  // ===== 预览区 =====
  @Builder
  buildPreview() {
    Column() {
      Text('预览（2×4 卡片）')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 10 })
      Stack() {
        // 背景：图片或默认渐变
        if (this.hasImage && this.bgUri !== '') {
          Image(this.bgUri)
            .objectFit(ImageFit.Cover)
            .width('100%')
            .height('100%')
        } else {
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({ angle: 135, colors: [['#667eea', 0.0], ['#764ba2', 1.0]] })
        }
        // 底部半透明遮罩（文字位于底部时保证可读性）
        if (this.hasImage && this.textPosY >= 0.55) {
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 180,
              colors: [['#00000000', 0.0], ['#00000000', 0.35], ['#99000000', 1.0]]
            })
        }
        // 文字（可拖拽）
        Text(this.text.length > 0 ? this.text : '预览文字')
          .fontSize(this.textSize)
          .fontColor(this.textColor)
          .fontWeight(FontWeight.Medium)
          .opacity(this.text.length > 0 ? 1.0 : 0.6)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 300 })
          .position({ x: this.textPosX * this.previewW, y: this.textPosY * this.previewH })
          .gesture(
            PanGesture({ fingers: 1 })
              .onActionStart((event: GestureEvent) => {
                this.dragStartX = this.textPosX;
                this.dragStartY = this.textPosY;
              })
              .onActionUpdate((event: GestureEvent) => {
                const dx = event.offsetX / this.previewW;
                const dy = event.offsetY / this.previewH;
                let nx = this.dragStartX + dx;
                let ny = this.dragStartY + dy;
                nx = Math.min(Math.max(nx, 0), 0.95);
                ny = Math.min(Math.max(ny, 0), 0.9);
                this.textPosX = nx;
                this.textPosY = ny;
              })
          )
      }
      .width(320)
      .height(160)
      .borderRadius(16)
      .clip(true)
      .shadow({ radius: 12, color: '#22000000', offsetX: 0, offsetY: 4 })
      Text('拖动文字可自由调整位置')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 10 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 20 })
  }

  // ===== 区块标题 =====
  @Builder
  buildSectionTitle(title: string) {
    Text(title)
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .fontColor('#1A1A1A')
      .width('100%')
      .margin({ bottom: 12 })
  }

  // ===== 背景图片区 =====
  @Builder
  buildImageSection() {
    Column() {
      this.buildSectionTitle('背景图片')
      Row({ space: 12 }) {
        Button('选择图片')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#0A59F7')
          .height(40)
          .layoutWeight(1)
          .onClick(() => { this.selectImage(); })
        if (this.hasImage) {
          Button('清除背景')
            .fontSize(14)
            .fontColor('#E84026')
            .backgroundColor('#FFEBE6')
            .height(40)
            .layoutWeight(1)
            .onClick(() => { this.clearImage(); })
        }
      }
      .width('100%')
      Text('未选择图片时使用默认渐变色背景')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  // ===== 文字内容区 =====
  @Builder
  buildTextSection() {
    Column() {
      this.buildSectionTitle('文字内容')
      TextInput({ text: this.text, placeholder: '请输入要显示在卡片上的文字' })
        .fontSize(15)
        .height(44)
        .maxLength(60)
        .onChange((value: string) => { this.text = value; })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  // ===== 样式区（颜色/字号）=====
  @Builder
  buildStyleSection() {
    Column() {
      this.buildSectionTitle('文字样式')
      // 颜色
      Text('颜色').fontSize(14).fontColor('#666666').width('100%').margin({ bottom: 8 })
      Row({ space: 10 }) {
        ForEach(this.presetColors, (color: string) => {
          Stack() {
            Circle()
              .width(34)
              .height(34)
              .fill(color)
              .stroke(this.textColor === color ? '#0A59F7' : '#DDDDDD')
              .strokeWidth(this.textColor === color ? 3 : 1)
          }
          .width(40)
          .height(40)
          .alignContent(Alignment.Center)
          .onClick(() => { this.textColor = color; })
        }, (color: string) => color)
      }
      .width('100%')
      .margin({ bottom: 16 })
      // 字号
      Row() {
        Text('字号').fontSize(14).fontColor('#666666').width(40)
        Slider({ value: this.textSize, min: 12, max: 48, step: 1 })
          .layoutWeight(1)
          .onChange((value: number) => { this.textSize = value; })
        Text(this.textSize.toFixed(0)).fontSize(14).fontColor('#1A1A1A').width(32).textAlign(TextAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  // ===== 位置区（微调滑块）=====
  @Builder
  buildPositionSection() {
    Column() {
      this.buildSectionTitle('文字位置')
      // 横向微调
      Row() {
        Text('横向').fontSize(14).fontColor('#666666').width(40)
        Slider({ value: this.textPosX * 100, min: 0, max: 100, step: 1 })
          .layoutWeight(1)
          .onChange((value: number) => { this.textPosX = value / 100; })
        Text((this.textPosX * 100).toFixed(0) + '%').fontSize(13).fontColor('#1A1A1A').width(44).textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ bottom: 8 })
      // 纵向微调
      Row() {
        Text('纵向').fontSize(14).fontColor('#666666').width(40)
        Slider({ value: this.textPosY * 100, min: 0, max: 100, step: 1 })
          .layoutWeight(1)
          .onChange((value: number) => { this.textPosY = value / 100; })
        Text((this.textPosY * 100).toFixed(0) + '%').fontSize(13).fontColor('#1A1A1A').width(44).textAlign(TextAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
  }

  // ===== 底部 Dock 栏 =====
  @Builder
  buildDock() {
    Row() {
      // 主页（当前激活）
      Column() {
        Image($r('app.media.ic_public_home'))
          .width(26)
          .height(26)
          .fillColor('#0A59F7')
        Text('主页').fontSize(12).fontColor('#0A59F7')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .height(64)
      .onClick(() => { /* 已在主页 */ })
      // 关于
      Column() {
        Image($r('app.media.ic_public_contacts'))
          .width(26)
          .height(26)
          .fillColor('#999999')
        Text('关于').fontSize(12).fontColor('#999999')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .height(64)
      .onClick(() => { router.pushUrl({ url: 'pages/AboutPage' }); })
    }
    .width('100%')
    .height(64)
    .backgroundColor('#FFFFFF')
  }

  build() {
    Column() {
      this.buildTitleBar()
      Scroll() {
        Column() {
          this.buildPreview()
          this.buildImageSection()
          this.buildTextSection()
          this.buildStyleSection()
          this.buildPositionSection()
          Button('应用到卡片')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor('#0A59F7')
            .borderRadius(24)
            .onClick(() => { this.applyToCard(); })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      this.buildDock()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
