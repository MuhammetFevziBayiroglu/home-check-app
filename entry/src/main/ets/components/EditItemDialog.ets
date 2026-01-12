import { EditItemData } from '../model/EditItemData';

@CustomDialog
export struct EditItemDialog {
  controller?: CustomDialogController;

  name: string = '';
  category: string = '';
  note: string = '';
  isCritical: boolean = false;

  cancel: () => void = () => {};
  confirm: (data: EditItemData) => void = () => {};
  @State private touched: boolean = false;

  // 1. İsim Alanı Builder'ı
  @Builder NameInputSection() {
    Column({ space: 6 }) {
      Text('Name').fontSize(14).fontColor('#111827')

      TextInput({ text: this.name, placeholder: 'e.g., Windows, Iron…' })
        .height(40)
        .maxLines(1)
        .fontColor(Color.Black)
        .onChange((v: string): void => {
          this.name = v;
          this.touched = true;
        })
        .border({
          width: 1,
          color: (this.touched && (this.name.trim().length === 0)) ? '#EF4444'
            : (this.name.trim().length > 0 ? '#10B981' : '#E5E7EB')
        })
        .borderRadius(10)
        .padding({ left: 10, right: 10 })

      if (this.touched && this.name.trim().length === 0) {
        Text('Name is required.').fontSize(12).fontColor('#DC2626')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder OptionalInputsSection() {
    Column({ space: 16 }) {
      // Category
      Column({ space: 6 }) {
        Text('Category').fontSize(14).fontColor('#111827')
        TextInput({ text: this.category, placeholder: 'Optional (e.g., Kitchen)' })
          .height(40)
          .maxLines(1)
          .fontColor(Color.Black)
          .onChange((v: string) => { this.category = v; })
          .border({ width: 1, color: '#E5E7EB' })
          .borderRadius(10)
          .padding({ left: 10, right: 10 })
      }.alignItems(HorizontalAlign.Start).width('100%')

      Column({ space: 6 }) {
        Text('Note').fontSize(14).fontColor('#111827')
        TextInput({ text: this.note, placeholder: 'Optional note' })
          .height(96)
          .maxLines(4)
          .fontColor(Color.Black)
          .onChange((v: string) => { this.note = v; })
          .border({ width: 1, color: '#E5E7EB' })
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
  }

  // 3. Toggle/Switch Alanı
  @Builder CriticalSwitchSection() {
    Column() {
      Row({ space: 8 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.isCritical })
          .onChange((val: boolean) => { this.isCritical = val; })
        Text(this.isCritical ? 'Marked as critical' : 'Mark as critical')
          .fontSize(14).fontColor('#111827')
      }.alignItems(VerticalAlign.Center)

      Text('Changes will be saved for this item.')
        .fontSize(12).fontColor('#6B7280').margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder ActionButtons() {
    Row({ space: 10 }) {
      Button('Cancel')
        .type(ButtonType.Capsule)
        .backgroundColor('#F3F4F6')
        .fontColor('#111827')
        .onClick(() => {
          this.cancel();
          this.controller?.close();
        })

      Button('Save')
        .type(ButtonType.Capsule)
        .backgroundColor(this.name.trim().length > 0 ? '#2563EB' : '#9CA3AF')
        .fontColor(Color.White)
        .enabled(this.name.trim().length > 0)
        .onClick(() => {
          const trimmed: string = (this.name ?? '').trim();
          if (!trimmed) {
            this.touched = true;
            return;
          }
          this.confirm({
            name: trimmed,
            category: (this.category ?? '').trim(),
            note: (this.note ?? '').trim(),
            isCritical: this.isCritical
          });
          this.controller?.close();
        })
    }
    .justifyContent(FlexAlign.End)
    .padding({ left: 16, right: 16, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .width('100%')
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {

          this.NameInputSection()

          this.OptionalInputsSection()

          this.CriticalSwitchSection()

        }
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      this.ActionButtons()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }}