// widget/pages/WidgetCard.ets
// 服务卡片 UI：显示背景图（或默认渐变）+ 自由定位的文字
// 说明：卡片数据通过 FormBindingData 注入 LocalStorage，字段名即 @LocalStorageProp 的键。

@Entry
@Component
struct WidgetCard {
  // 文字内容
  @LocalStorageProp('text') text: string = '';
  // 文字左上角锚点（0~1 归一化坐标）
  @LocalStorageProp('textPosX') textPosX: number = 0.5;
  @LocalStorageProp('textPosY') textPosY: number = 0.5;
  // 文字颜色与字号
  @LocalStorageProp('textColor') textColor: string = '#FFFFFF';
  @LocalStorageProp('textSize') textSize: number = 24;
  // 是否显示背景图
  @LocalStorageProp('hasImage') hasImage: boolean = false;
  // 背景图对应的 fd 键（配合 formImages 使用）
  @LocalStorageProp('imgName') imgName: string = '';

  build() {
    Stack() {
      // 背景层：有背景图显示图，无背景图显示默认渐变
      if (this.hasImage) {
        Image('memory://' + this.imgName)
          .objectFit(ImageFit.Cover)
          .width('100%')
          .height('100%')
      } else {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 135,
            colors: [['#667eea', 0.0], ['#764ba2', 1.0]]
          })
      }

      // 底部半透明遮罩：当文字位于图片底部时，保证文字可读性
      if (this.hasImage && this.textPosY >= 0.55) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 180,
            colors: [['#00000000', 0.0], ['#00000000', 0.35], ['#99000000', 1.0]]
          })
      }

      // 文字层：自由定位（归一化坐标 → 百分比位置）
      Text(this.text)
        .fontSize(this.textSize)
        .fontColor(this.textColor)
        .fontWeight(FontWeight.Medium)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .position({
          x: this.textPosX * 100 + '%',
          y: this.textPosY * 100 + '%'
        })
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      // 点击卡片跳转到应用主页
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetPage: 'Index' }
      });
    })
  }
}
