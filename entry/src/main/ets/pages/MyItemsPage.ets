import dbUtils, { ItemRow } from '../common/utils/DBUtils';
import commonUtils from '../common/utils/CommonUtils';
import { EditItemDialog } from '../components/EditItemDialog';
import { ItemActionsDialog } from '../components/ItemActionsDialog';
import { EditItemData } from '../model/EditItemData';
import { BuildControls, BuildEmpty, BuildItemCard, ItemMenuBuilder } from '../components/MyItemsView';
import { ArcList,ArcListItem,ArcListAttribute,ArcListItemAttribute,ComponentContent,LengthMetrics } from '@kit.ArkUI';

@Builder
export function MyItemsPageBuilder(name?: string, param?: Object) {
  MyItemsPage();
}

@Builder
function myItemsHeader(): void {
  Column() {
    Text('My Items')
      .fontSize(22)
      .fontWeight(FontWeight.Bold)
  }
  .margin(0)
}

@Entry
@Component
export struct MyItemsPage {
  private stack: NavPathStack | null = null;
  @State items: ItemRow[] = [];
  @State loading: boolean = false;
  @State onlyCritical: boolean = false;
  private editingId: number | null = null;
  private editDialog: CustomDialogController | null = null;
  private itemActionsDialog: CustomDialogController | null = null;
  private readonly watchSize: string = '466px';
  private readonly listSize: string = '414px';
  private ctx?: UIContext;
  private headerCc?: ComponentContent<object>;

  aboutToAppear(): void {
    this.ctx = this.getUIContext();
    this.headerCc = new ComponentContent<object>(this.ctx as UIContext, wrapBuilder(myItemsHeader));
    void this.loadItems();
  }

  @Builder
  LocalItemMenu(row: ItemRow) {
    ItemMenuBuilder(
      row,
      (r: ItemRow) => this.openEditDialog(r),
      (r: ItemRow) => {
        void this.onDelete(r.id)
      }
    )
  }

  private async loadItems(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    try {
      const rows: ItemRow[] = await dbUtils.queryAll();
      const filtered: ItemRow[] = this.onlyCritical ?
      rows.filter((r: ItemRow) => r.isCritical === 1) :
        rows;

      const fresh: ItemRow[] = [];
      for (let i = 0; i < filtered.length; i++) {
        fresh.push(this.cloneRow(filtered[i]));
      }
      this.items = fresh;
    } catch (e) {
      const msg: string = e instanceof Error ? e.message : String(e);
      console.error(`[MyItemsPage.loadItems] ${msg}`);
      commonUtils.showToast('Load error');
    } finally {
      this.loading = false;
    }
  }

  private cloneRow(src: ItemRow): ItemRow {
    const row: ItemRow = {
      id: src.id,
      name: src.name,
      category: (src as ItemRow).category !== undefined ? src.category : null,
      note: (src as ItemRow).note !== undefined ? src.note : null,
      isCritical: src.isCritical
    };
    return row;
  }

  private getSectionKeys(): string[] {
    const base: string[] = ['controls'];
    if (this.items.length === 0 && !this.loading) {
      base.push('empty');
      return base;
    }
    for (let i = 0; i < this.items.length; i++) {
      const r: ItemRow = this.items[i];
      base.push(this.keyFor(r));
    }
    return base;
  }

  private keyFor(r: ItemRow): string {
    const n = (r.name || '').split(' ').join('_');
    const c = (r.category ? r.category : '').split(' ').join('_');
    const no = (r.note ? r.note : '').split(' ').join('_');
    return `item-${r.id}-${r.isCritical}-${n}-${c}-${no}`;
  }

  private getRowFromKey(key: string): ItemRow | undefined {
    if (!key.startsWith('item-')) {
      return undefined;
    }
    let i: number = 5;
    let idStr: string = '';
    while (i < key.length) {
      const ch: string = key.charAt(i);
      if (ch >= '0' && ch <= '9') {
        idStr += ch;
        i++;
      } else {
        break;
      }
    }
    const idNum: number = Number(idStr);
    if (Number.isNaN(idNum)) {
      return undefined;
    }
    for (let k = 0; k < this.items.length; k++) {
      if (this.items[k].id === idNum) {
        return this.items[k];
      }
    }
    return undefined;
  }

  private showItemActions(row: ItemRow): void {
    this.itemActionsDialog = new CustomDialogController({
      builder: ItemActionsDialog({
        itemName: row.name,
        itemId: row.id,
        onEdit: () => this.openEditDialog(row),
        onDelete: (id: number) => {
          void this.onDelete(id);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      onWillDismiss: (a: DismissDialogAction): void => {
        if (a.reason === DismissReason.PRESS_BACK || a.reason === DismissReason.TOUCH_OUTSIDE) {
          a.dismiss();
        }
      }
    });
    this.itemActionsDialog.open();
  }

  openEditDialog(row: ItemRow): void {
    this.editingId = row.id;
    this.editDialog = new CustomDialogController({
      builder: EditItemDialog({
        name: row.name,
        category: (row.category ?? '') as string,
        note: (row.note ?? '') as string,
        isCritical: row.isCritical === 1,
        cancel: (): void => {
        },
        confirm: (data: EditItemData): void => {
          void this.applyEdit(row.id, data)
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      onWillDismiss: (a: DismissDialogAction): void => {
        if (a.reason === DismissReason.PRESS_BACK || a.reason === DismissReason.TOUCH_OUTSIDE) {
          a.dismiss();
        }
      }
    });
    this.editDialog.open();
  }

  private async applyEdit(id: number, data: EditItemData): Promise<void> {
    const ok: boolean = await dbUtils.updateItem(id, {
      name: data.name,
      category: data.category || null,
      note: data.note || null,
      isCritical: data.isCritical ? 1 : 0
    });

    if (ok) {
      const updatedList: ItemRow[] = [];
      for (let i = 0; i < this.items.length; i++) {
        const r: ItemRow = this.items[i];
        if (r.id === id) {
          updatedList.push(this.mergeRowUpdate(r, data));
        } else {
          updatedList.push(r);
        }
      }
      this.items = updatedList;
      commonUtils.showToast('Item updated ✅');
    } else {
      commonUtils.showToast('Update failed ❌');
    }
  }

  private mergeRowUpdate(oldRow: ItemRow, data: EditItemData): ItemRow {
    const updated: ItemRow = {
      id: oldRow.id,
      name: data.name,
      category: data.category ? data.category : null,
      note: data.note ? data.note : null,
      isCritical: data.isCritical ? 1 : 0
    };
    return updated;
  }

  private async onDelete(id: number): Promise<void> {
    const ok: boolean = await dbUtils.deleteItem(id);
    if (ok) {
      commonUtils.showToast('Deleted ✅');
      void this.loadItems();
    } else {
      commonUtils.showToast('Delete failed ❌');
    }
  }

  build(): void {
    NavDestination() {
      Stack() {
        Column() {
        }
        .justifyContent(FlexAlign.Center)
        .width(this.watchSize)
        .height(this.watchSize)
        .clipShape(new Circle({ width: '100%', height: '100%' }))
        .backgroundColor(Color.White)

        if (this.headerCc) {
          ArcList({ initialIndex: 0, header: this.headerCc as ComponentContent<object> }) {
            ForEach(this.getSectionKeys(),
              (key: string, idx: number): void => {
                ArcListItem() {
                  Column() {
                    if (key === 'controls') {
                      BuildControls(
                        this.loading,
                        this.onlyCritical,
                        () => {
                          void this.loadItems()
                        },
                        (v: boolean) => {
                          this.onlyCritical = v;
                          void this.loadItems();
                        }
                      )
                    } else if (key === 'empty') {
                      BuildEmpty()
                    } else if (this.getRowFromKey(key) !== undefined) {
                      BuildItemCard(
                        this.getRowFromKey(key) as ItemRow,
                        (r: ItemRow) => this.showItemActions(r),
                        (): void => {
                          this.LocalItemMenu(this.getRowFromKey(key) as ItemRow)
                        }
                      )
                    } else {
                      BuildEmpty()
                    }
                  }
                  .width(this.listSize)
                }
                .align(Alignment.Center)
              },
              (key: string, idx: number): string => key
            )
          }
          .space(LengthMetrics.px(10))
          .borderRadius(this.watchSize)
          .focusable(true)
          .focusOnTouch(true)
          .defaultFocus(true)
        } else {
          Column() {
            Text('Loading…').fontSize(16)
          }
          .alignItems(HorizontalAlign.Center)
        }
      }
      .align(Alignment.Center)
      .width(this.watchSize)
      .height(this.watchSize)
      .border({ color: Color.Black, width: 1 })
      .borderRadius(this.watchSize)
      .backgroundColor('#F5F6F8')
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.stack = ctx.pathStack;
    })
  }
}