import { ItemRow } from '../common/utils/DBUtils';

@CustomDialog
export struct ItemActionsDialog {
  controller?: CustomDialogController;
  row!: ItemRow;
  onEdit: (row: ItemRow) => void = () => {};
  onDelete: (id: number) => void = () => {};

  build() {
    Column({ space: 12 }) {
      Text('Item actions')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')
        .margin({ bottom: 4 })

      Text(this.row.name)
        .fontSize(12)
        .fontColor('#6B7280')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Button('Edit')
        .width('80%')
        .height(36)
        .fontSize(13)
        .backgroundColor('#2563EB')
        .fontColor(Color.White)
        .onClick(() => {
          this.onEdit(this.row);
          this.controller?.close();
        })

      Button('Delete')
        .width('80%')
        .height(36)
        .fontSize(13)
        .backgroundColor('#EF4444')
        .fontColor(Color.White)
        .onClick(() => {
          this.onDelete(this.row.id);
          this.controller?.close();
        })

      Button('Cancel')
        .width('80%')
        .height(36)
        .fontSize(13)
        .backgroundColor('#F3F4F6')
        .fontColor('#111827')
        .onClick(() => {
          this.controller?.close();
        })
    }
    .padding(16)
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
