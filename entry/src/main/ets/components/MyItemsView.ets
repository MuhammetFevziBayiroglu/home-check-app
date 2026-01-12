import { ItemRow } from '../common/utils/DBUtils';

@Builder
export function BuildControls(
  loading: boolean,
  onlyCritical: boolean,
  onRefresh: () => void,
  onToggleCritical: (isOn: boolean) => void
) {
  Row({ space: 8 }) {
    Image($r('app.media.refresh_ic'))
      .opacity(loading ? 0.6 : 1)
      .width(25).height(25)
      .onClick((): void => {
        if (!loading) {
          onRefresh();
        }
      })

    Row({ space: 6 }) {
      Toggle({ type: ToggleType.Switch, isOn: onlyCritical })
        .onChange((v: boolean): void => {
          onToggleCritical(v);
        })
      Text('Critical only').fontSize(13).fontColor('#666666')
    }
  }
  .width('100%')
  .padding(12)
  .backgroundColor('#FFFFFF')
  .borderRadius(16)
  .shadow({
    radius: 8,
    color: '#11000000',
    offsetX: 0,
    offsetY: 2
  })
}

@Builder
export function BuildEmpty() {
  Column({ space: 8 }) {
    Text('No items yet').fontSize(16).fontColor('#666')
    Text('Add a new item and come back.').fontSize(13).fontColor('#999')
  }
  .width('100%')
  .padding(24)
  .alignItems(HorizontalAlign.Center)
  .backgroundColor('#FFFFFF')
  .borderRadius(16)
  .shadow({
    radius: 8,
    color: '#11000000',
    offsetX: 0,
    offsetY: 2
  })
}

@Builder
export function BuildItemCard(
  row: ItemRow,
  onActionClick: (row: ItemRow) => void,
  menuBuilder: CustomBuilder
) {
  Column({ space: 8 }) {
    Row() {
      Text(row.name || 'Unnamed')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111827')
      Blank()
      if (row.isCritical === 1) {
        Row() {
          Text('CRITICAL')
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#B91C1C')
        }
        .padding({
          left: 10,
          right: 10,
          top: 4,
          bottom: 4
        })
        .backgroundColor('#FEE2E2')
        .borderRadius(999)
        .border({ color: '#FCA5A5', width: 0.6 })
        .margin({ right: 8 })
      }
      Button('•••')
        .type(ButtonType.Circle)
        .height(32)
        .width(32)
        .fontSize(16)
        .backgroundColor('#F3F4F6')
        .fontColor('#111827')
        .onClick((): void => onActionClick(row))
        .bindMenu(menuBuilder)
    }
    .width('100%')

    if (row.category) {
      Row() {
        Text(row.category as string)
          .fontSize(12)
          .fontColor('#374151')
      }
      .padding({
        left: 10,
        right: 10,
        top: 4,
        bottom: 4
      })
      .backgroundColor('#E5E7EB')
      .borderRadius(999)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
    }

    if (row.note) {
      Text(row.note as string)
        .fontSize(13).fontColor('#374151').maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
  }
  .width('100%')
  .padding({
    left: 14,
    right: 14,
    top: 12,
    bottom: 12
  })
  .backgroundColor('#FFFFFF')
  .borderRadius(14)
  .border({ color: '#F3F4F6', width: 1 })
  .shadow({
    radius: 10,
    color: '#16000000',
    offsetX: 0,
    offsetY: 3
  })
}

@Builder
export function ItemMenuBuilder(
  row: ItemRow,
  onEdit: (row: ItemRow) => void,
  onDelete: (row: ItemRow) => void
) {
  Menu() {
    MenuItem({ content: 'Edit' })
      .onClick((): void => onEdit(row))

    MenuItem({ content: 'Delete' })
      .onClick((): void => onDelete(row))
  }
}