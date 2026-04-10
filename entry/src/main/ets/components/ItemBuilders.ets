@Builder
export function LoadingCard() {
  Column({ space: 8 }) {
    Text('Loading…').fontSize(16).fontColor('#666666');
  }
  .alignItems(HorizontalAlign.Center)
  .justifyContent(FlexAlign.Center)
  .padding(16)
  .width('82%')
  .backgroundColor('#FFFFFF')
  .borderRadius(16)
  .shadow({
    radius: 8,
    color: '#11000000',
    offsetX: 0,
    offsetY: 2
  });
}

@Builder
export function DoneCard(stack: NavPathStack) {
  Column({ space: 12 }) {
    Text('You Can Checked All Items!')
      .fontSize(20).fontWeight(FontWeight.Medium).fontColor('#111827');

    Button('Done')
      .type(ButtonType.Capsule).backgroundColor('#2563EB').fontColor(Color.White)
      .onClick(() => stack.pop({ created: true }));
  }
  .alignItems(HorizontalAlign.Center)
  .justifyContent(FlexAlign.Center)
  .padding(16)
  .width('82%')
  .backgroundColor('#FFFFFF')
  .borderRadius(16)
  .shadow({
    radius: 8,
    color: '#11000000',
    offsetX: 0,
    offsetY: 2
  });
}
