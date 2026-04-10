import { ItemRow } from '../common/utils/DBUtils';

@Component
export struct ItemCardView {
  @Prop cat: string;
  @Prop it: ItemRow;
  @Prop isCritical: boolean;
  @StorageProp('holdTime') holdTime: number = 5000;

  build(): void {
    Column({ space: 10 }) {
      Text(this.cat)
        .fontSize(13)
        .fontColor('#6B7280')
        .textAlign(TextAlign.Center)

      Text(this.it.name || 'Unnamed')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')
        .textAlign(TextAlign.Center)

      if (this.it.note && this.it.note.trim().length > 0) {
        Text(this.it.note)
          .fontSize(13)
          .fontColor('#374151')
          .textAlign(TextAlign.Center)
          .maxLines(3)
      }

      Text(`Press & hold ${this.holdTime / 1000}s to Check`)
        .fontSize(12)
        .fontColor('#6B7280')
        .margin({ top: 6 })

    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .padding(16)
    .width('82%')
    .backgroundColor(Color.Transparent)
    .borderRadius(this.isCritical ? 0 : 16)
  }
}
