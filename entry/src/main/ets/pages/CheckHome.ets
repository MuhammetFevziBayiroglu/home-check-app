import dbUtils, { ItemRow } from '../common/utils/DBUtils';
import commonUtils from '../common/utils/CommonUtils';
import { CommonConstants } from '../common/constants/CommonConstants';
import { LoadingCard, DoneCard } from '../components/ItemBuilders';
import { ItemCardView } from '../components/ItemCardView';
import { PageItem } from '../model/PageItem';
import { promptAction } from '@kit.ArkUI';

type LogArg = string | number | boolean;

@Builder
export function CheckHomeBuilder(name?: string, param?: Object) {
  CheckHome();
}

@Component
export struct CheckHome {
  private stack!: NavPathStack;
  @StorageLink('holdTime') holdTime: number = 5000;
  private static readonly TIMEOUT_MS: number = 5000;
  private readonly watchSize: string = '466px';
  private readonly DEBUG: boolean = true;

  private dbg(...args: LogArg[]): void {
    if (!this.DEBUG) {
      return;
    }
    const out: string[] = [];
    for (let i = 0; i < args.length; i++) {
      out.push(String(args[i]));
    }
    console.info('[CheckHome]', ...out);
  }

  @State private loading: boolean = false;
  @State private pages: PageItem[] = [];
  @State private pageIndex: number = 0;
  @State private holdProgress: number = 0;
  @State private holding: boolean = false;
  private holdTimerId: number = -1;
  private isFetching: boolean = false;
  private lastLoadStamp: number = 0;
  private dbReady: boolean = false;
  private dbInitInProgress: boolean = false;
  private holdStartIndex: number = -1;
  private holdFinishedByTimer: boolean = false;

  aboutToAppear(): void {
    void this.loadItems(true);
  }

  onPageShow?(): void {
    if (!this.isFetching && !this.loading && this.pages.length === 0) {
      void this.loadItems(true);
    }
  }

  private withTimeout<T>(p: Promise<T>, ms: number, tag: string): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      let settled = false;
      const timer = setTimeout(() => {
        if (!settled) {
          console.error(`[CheckHome] ${tag} timed out after ${ms}ms`);
          reject(new Error('TIMEOUT'));
        }
      }, ms);
      p.then(v => {
        settled = true;
        clearTimeout(timer);
        resolve(v);
      })
        .catch((e: Error) => {
          settled = true;
          clearTimeout(timer);
          reject(e);
        });
      ;


    });
  }

  private async initDBOnce(): Promise<void> {
    if (this.dbReady || this.dbInitInProgress) {
      return;
    }
    this.dbInitInProgress = true;
    try {
      await this.withTimeout(dbUtils.createDB(), CheckHome.TIMEOUT_MS, 'createDB');
      this.dbReady = true;
      this.dbg('DB initialized:', CommonConstants.DB_NAME);
    } finally {
      this.dbInitInProgress = false;
    }
  }

  private buildPagesFrom(rows: ItemRow[]): PageItem[] {
    const pages: PageItem[] = [];
    for (let i = 0; i < rows.length; i++) {
      const r: ItemRow = rows[i];
      const cat: string =
        r.category && r.category.trim().length > 0 ? r.category : 'Uncategorized';
      const item: ItemRow = {
        id: Number(r.id),
        name: String(r.name ?? ''),
        category: r.category ? String(r.category) : null,
        note: r.note ? String(r.note) : null,
        isCritical: Number(r.isCritical) === 1 ? 1 : 0
      };
      pages.push({ cat, item });
    }
    return pages;
  }

  private async loadItems(allowRetry: boolean = false): Promise<void> {
    if (this.isFetching) {
      return;
    }
    this.loading = true;
    this.isFetching = true;
    const stamp: number = ++this.lastLoadStamp;

    try {
      await this.initDBOnce();

      this.dbg(
        'SQL_QUERY_ALL_ITEMS =',
        CommonConstants.SQL_QUERY_ALL_ITEMS.replace(/\s+/g, ' ').trim()
      );

      let rows: ItemRow[] = await this.withTimeout(
        dbUtils.queryAll(),
        CheckHome.TIMEOUT_MS,
        'queryAll'
      );

      this.dbg('DB rows count =', rows.length);
      for (let i = 0; i < rows.length; i++) {
        const r: ItemRow = rows[i];
        this.dbg(
          `row[${i}] id=${r.id} name=${r.name} cat=${r.category} crit=${Number(r.isCritical)}`
        );


      }

      if (allowRetry && rows.length === 0) {
        this.dbg('rows empty, retrying once…');
        await this.withTimeout(
          new Promise<void>((res) => {
            setTimeout(res, 150);
          }),
          500,
          'retryDelay'
        );
        rows = await this.withTimeout(
          dbUtils.queryAll(),
          CheckHome.TIMEOUT_MS,
          'queryAll#retry'
        );
        this.dbg('retry rows count =', rows.length);
      }

      this.pages = this.buildPagesFrom(rows);

      this.dbg('pages count =', this.pages.length);
      for (let i = 0; i < this.pages.length; i++) {
        const p: PageItem = this.pages[i];
        this.dbg(
          `page[${i}] cat=${p.cat} name=${p.item.name} id=${p.item.id} crit=${Number(p.item.isCritical)}`
        );

      }

      this.pageIndex = 0;
      this.dbg('AFTER load -> pageIndex =', this.pageIndex);
    } catch (e) {
      const msg: string = e instanceof Error ? e.message : String(e);
      console.error(`[CheckHome.loadItems] ERROR #${stamp}: ${msg}`);
      commonUtils.showToast(msg === 'TIMEOUT' ? 'Load timeout' : 'Load error');
      this.pages = [];
      this.pageIndex = 0;
    } finally {
      this.loading = false;
      this.isFetching = false;
    }
  }

  private goNext(): void {
    if (this.pages.length === 0) {
      this.dbg('goNext: pages empty, ignoring');
      return;
    }

    const oldIndex: number = this.pageIndex;
    const next: number = this.pageIndex + 1;

    if (next < this.pages.length) {
      const oldItem: PageItem = this.pages[oldIndex];
      const nextItem: PageItem = this.pages[next];

      this.dbg(
        'goNext BEFORE -> oldIndex=', oldIndex,
        ' oldName=', oldItem.item.name,
        ' oldCrit=', Number(oldItem.item.isCritical),
        ' nextIndex=', next,
        ' nextName=', nextItem.item.name,
        ' nextCrit=', Number(nextItem.item.isCritical)
      );

      this.pageIndex = next;

      this.dbg(
        'goNext AFTER  -> pageIndex=', this.pageIndex,
        ' nowName=', this.pages[this.pageIndex].item.name,
        ' nowCrit=', Number(this.pages[this.pageIndex].item.isCritical)
      );

      commonUtils.showToast(`Item ${this.pageIndex + 1}/${this.pages.length}`);
    } else {
      this.dbg('goNext -> reached end, clearing pages');
      this.pages = [];
      this.pageIndex = 0;
      commonUtils.showToast('All checked');
    }
  }

  private startHold(): void {
    if (this.holding) {
      return;
    }
    this.holding = true;
    this.holdProgress = 0;
    this.holdStartIndex = this.pageIndex;
    this.holdFinishedByTimer = false;
    const start: number = Date.now();
    const total: number = this.holdTime;

    this.dbg('startHold DOWN at index', this.pageIndex, 'total ms=', total);

    this.holdTimerId = setInterval((): void => {
      const elapsed: number = Date.now() - start;
      const newProgress: number = Math.min(100, Math.floor((elapsed / total) * 100));

      if (newProgress !== this.holdProgress && newProgress % 10 === 0) {
        this.dbg(
          'hold progress =',
          newProgress,
          '% | at index',
          this.pageIndex,
          '| startIndex',
          this.holdStartIndex
        );
      }

      this.holdProgress = newProgress;

      if (elapsed >= total) {
        this.finishHold();
      }
    }, 50);
  }

  private finishHold(): void {
    if (!this.holding) {
      this.dbg('finishHold ignored (not holding)');
      return;
    }
    const cur = this.getCur();
    this.dbg('finishHold at index', this.pageIndex, '| startedAt=', this.holdStartIndex,
      '| name=', cur ? cur.item.name : 'none');

    this.clearHoldTimer();
    this.holdProgress = 100;
    this.holding = false;
    this.holdFinishedByTimer = true;

    if (this.pageIndex === this.holdStartIndex) {
      const before = this.getCur();
      this.goNext();
      const after = this.getCur();
      this.dbg('finishHold advanced ->', before ? before.item.name : 'none', '→',
        after ? after.item.name : 'none');
    } else {
      this.dbg('finishHold ignored: index changed during hold (pageIndex=',
        this.pageIndex, ', startIndex=', this.holdStartIndex, ')');
    }

    this.holdProgress = 0;
    this.holdStartIndex = -1;
  }

  private cancelHold(): void {
    if (this.holdFinishedByTimer) {
      this.dbg('cancelHold ignored: already finished by timer');
      return;
    }
    this.dbg('cancelHold (UP/CANCEL) at index', this.pageIndex, 'holding=', this.holding);
    this.clearHoldTimer();
    this.holding = false;
    this.holdProgress = 0;
    this.holdStartIndex = -1;
  }

  private clearHoldTimer(): void {
    if (this.holdTimerId !== -1) {
      clearInterval(this.holdTimerId);
      this.holdTimerId = -1;
    }
  }

  private getCur(): PageItem | undefined {
    if (this.pages.length === 0) {
      return undefined;
    }
    if (this.pageIndex < 0 || this.pageIndex >= this.pages.length) {
      return undefined;
    }
    return this.pages[this.pageIndex];
  }

  private isCurCritical(): boolean {
    const cur = this.getCur();
    return !!(cur && Number(cur.item.isCritical) === 1);
  }

  private showHoldTimeSettings(): void {
    const options: string[] = ['1s', '2s', '3s', '5s', '10s'];
    const values: number[] = [1000, 2000, 3000, 5000, 10000];

    const menuOptions: promptAction.ActionMenuOptions = {
      title: 'Hold time',
      buttons: [
        { text: '1s', color: '#2563EB' },
        { text: '2s', color: '#2563EB' },
        { text: '3s', color: '#2563EB' },
        { text: '5s', color: '#2563EB' },
        { text: '10s', color: '#2563EB' }
      ]
    };

    this.getUIContext().getPromptAction().showActionMenu(menuOptions).then(res => {
      if (res.index >= 0 && res.index < values.length) {
        this.holdTime = values[res.index];
        commonUtils.showToast(`Hold time set to ${options[res.index]}`);
      }
    });
  }

  build(): void {
    NavDestination() {
      Stack() {
        Column() {
          if (this.loading) {
            LoadingCard()
          } else if (!this.getCur()) {
            DoneCard(this.stack)
          } else {
            Column() {
              ItemCardView({
                cat: this.getCur()!.cat,
                it: this.getCur()!.item,
                isCritical: this.isCurCritical()
              })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
        }
        .justifyContent(FlexAlign.Center)
        .width(this.watchSize)
        .height(this.watchSize)
        .clipShape(Circle({ width: '100%', height: '100%' }))
        .backgroundColor(this.isCurCritical() ? '#DD0303' : '#FFFFFF')
        .onTouch((event: TouchEvent) => {
          const cur = this.getCur();
          if (!cur) {
            this.dbg('onTouch ignored: no current item (pages empty)');
            return;
          }
          if (event.type === TouchType.Down) {
            this.startHold();
          } else if (event.type === TouchType.Up) {
            this.cancelHold();
          } else if (event.type === TouchType.Cancel) {
            this.cancelHold();
          }
        })

        Column() {
          Progress({ value: this.holdProgress, total: 100, type: ProgressType.Ring })
            .width('99%')
            .style({ strokeWidth: 12, shadow: true })
            .color(new LinearGradient([
              { color: 0xFFEAB308, offset: 0.0 },
              { color: 0xFFF59E0B, offset: 1.0 }
            ]))
        }
        .width(this.watchSize)
        .height(this.watchSize)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .visibility(this.holding ? Visibility.Visible : Visibility.Hidden)
        .hitTestBehavior(HitTestMode.None)

        Image($r('app.media.settings_ic'))
          .width(28)
          .height(28)
          .position({ x: '50%', y: 40 })
          .translate({ x: '-50%' })
          .onClick(() => this.showHoldTimeSettings())
      }
      .align(Alignment.Center)
      .width(this.watchSize)
      .height(this.watchSize)
      .border({ color: Color.Black, width: 1 })
      .borderRadius(this.watchSize)
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.stack = ctx.pathStack;
    })
  }
}