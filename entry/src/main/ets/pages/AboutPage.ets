// 关于页面：应用介绍、免责声明、联系方式
import { router, promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';

@Entry
@Component
struct AboutPage {
  // 联系我们内容（点击复制）
  private contactText: string = 'Telegram: t.me/+enkDGOI0mc9kMjU1\n邮箱: LONGER_WFT@163.com';

  // 复制联系方式到剪贴板
  private async copyContact(): Promise<void> {
    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.contactText);
      await systemPasteboard.setData(pasteData);
      promptAction.showToast({ message: '联系方式已复制', duration: 2000 });
    } catch (e) {
      promptAction.showToast({ message: '复制失败', duration: 2000 });
    }
  }

  // 顶部栏（左上角返回按钮）
  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.ic_public_back'))
        .width(26)
        .height(26)
        .fillColor('#1A1A1A')
        .onClick(() => { router.back(); })
      Text('关于')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ left: 12 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  // 标题区
  @Builder
  buildTitle() {
    Column() {
      Text('依见 Widegts for Tianyi')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .textAlign(TextAlign.Center)
      Text('Harmony OS_1.0_ver')
        .fontSize(14)
        .fontColor('#888888')
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 24, bottom: 20 })
    .alignItems(HorizontalAlign.Center)
  }

  // 信息容器（图标 + 标题 + 内容）
  @Builder
  buildInfoCard(title: string, content: string, icon: Resource) {
    Column() {
      Row({ space: 8 }) {
        Image(icon)
          .width(20)
          .height(20)
          .fillColor('#0A59F7')
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .margin({ bottom: 10 })
      Text(content)
        .fontSize(14)
        .fontColor('#555555')
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      this.buildHeader()
      Scroll() {
        Column() {
          this.buildTitle()

          // 容器一：关于依见
          this.buildInfoCard(
            '关于依见',
            '依见是一款开源的Harmony OS小组件（服务卡片）应用它旨在帮助用户将喜欢的图片、文字与信息，以简单而自由的方式呈现在桌面上。无论是喜欢的角色、珍藏的照片，都可以成为桌面的一部分。',
            $r('app.media.ic_public_detail')
          )

          // 容器二：免责声明
          this.buildInfoCard(
            '免责声明',
            '依见不提供或内置任何受版权保护素材，用户上传的内容由用户自行负责，洛天依相关权利归其权利方所有，不正确使用本软件产生的直接或间接责任，由使用者承担，创建小组件（服务卡片）即代表你已同意',
            $r('app.media.ic_public_security')
          )

          // 容器三：联系我们（点击复制）
          Column() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_public_contacts'))
                .width(20)
                .height(20)
                .fillColor('#0A59F7')
              Text('联系我们')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
            }
            .width('100%')
            .margin({ bottom: 10 })
            Text('Telegram: t.me/+enkDGOI0mc9kMjU1')
              .fontSize(14)
              .fontColor('#555555')
              .lineHeight(22)
              .width('100%')
            Text('邮箱: LONGER_WFT@163.com')
              .fontSize(14)
              .fontColor('#555555')
              .lineHeight(22)
              .width('100%')
            Text('（点击复制联系方式）')
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
              .margin({ top: 8 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 16 })
          .alignItems(HorizontalAlign.Start)
          .onClick(() => { this.copyContact(); })

          // 右下角署名
          Row() {
            Text('By m1ku_a12')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#888888')
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .padding({ right: 4, bottom: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
