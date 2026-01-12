import { ArcButtonComponent } from '../components/ArcButtonComponent';
import { ArcButtonPosition } from '@kit.ArkUI';

@Entry
@Component
export struct IndexNavHost {
  @Provide('navStack') navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    if (this.navStack.size() === 0) {
      this.navStack.pushPath({ name: 'IndexHome' });
    }
  }

  build() {
    Navigation(this.navStack) {
    }
    .hideNavBar(true)
    .width('100%')
    .height('100%');
  }
}

@Builder
export function IndexHomeBuilder() {
  IndexHome();
}

@Component
export struct IndexHome {
  @Consume('navStack') navStack: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        ArcButtonComponent({
          label: 'Add Item',
          arcPosition: ArcButtonPosition.TOP_EDGE,
          fontSize: 15,
          shadowEnabled: true,
          routeName: 'AddItemPage'
        })

        Blank()

        Button('Check Home')
          .width('120%')
          .onClick(() => {
            this.navStack.pushPathByName('CheckHome', null);
          })

        Blank()

        ArcButtonComponent({
          label: 'My Items',
          arcPosition: ArcButtonPosition.BOTTOM_EDGE,
          fontSize: 15,
          shadowEnabled: true,
          routeName: 'MyItemsPage'
        })
      }
      .backgroundColor('#F5F6F8')
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
  }
}
