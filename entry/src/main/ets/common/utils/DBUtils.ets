import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { CommonConstants } from '../constants/CommonConstants';
import Logger from './Logger';

export interface ItemRow {
  id: number;
  name: string;
  category?: string | null;
  note?: string | null;
  isCritical: number;
}

export interface ItemInsertInput {
  name: string;
  category?: string;
  note?: string;
  isCritical?: boolean;
}

export interface ItemUpdatePatch {
  name?: string;
  category?: string | null;
  note?: string | null;
  isCritical?: number;
}

let store: relationalStore.RdbStore | undefined = undefined;
let readyPromise: Promise<void> | undefined;

function getAbilityContext(): common.UIAbilityContext | undefined {
  return AppStorage.get('AppContext') as common.UIAbilityContext | undefined;
}

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: CommonConstants.DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

export class DBUtils {
  createDB(): Promise<void> {
    const abilityCtx = getAbilityContext();
    if (!abilityCtx) {
      const err: string = 'createDB: AppContext not set yet';
      Logger.error(err);
      return Promise.reject(new Error(err));
    }
    if (store) {
      return Promise.resolve();
    }
    if (readyPromise) {
      return readyPromise;
    }

    readyPromise = new Promise<void>((resolve, reject) => {
      relationalStore.getRdbStore(
        abilityCtx,
        STORE_CONFIG,
        async (err: BusinessError, rdbStore: relationalStore.RdbStore) => {
          if (err) {
            Logger.error(`getRdbStore failed, code=${err.code}, message=${err.message}`);
            reject(new Error('getRdbStore failed'));
            return;
          }
          store = rdbStore;

          try {
            await store.executeSql(CommonConstants.SQL_CREATE_ITEMS_TABLE);
            await store.executeSql(CommonConstants.SQL_CREATE_INDEX_CRITICAL);
            Logger.info('items table ready.');
            resolve();
          } catch (e) {
            Logger.error(`DDL failed: ${String(e)}`);
            reject(new Error('DDL failed'));
          }
        }
      );
    });

    return readyPromise;
  }

  private async ensureReady(): Promise<void> {
    if (store) {
      return;
    }
    await this.createDB();
  }

  async insertItem(input: ItemInsertInput): Promise<boolean> {
    await this.ensureReady();
    if (!store) {
      Logger.error('DB not initialized');
      return false;
    }

    const sql =
      `INSERT INTO ${CommonConstants.T_ITEMS}
       (${CommonConstants.C_NAME}, ${CommonConstants.C_CATEGORY}, ${CommonConstants.C_NOTE},
        ${CommonConstants.C_IS_CRITICAL})
       VALUES (?, ?, ?, ?)`;

    const args: (string | number | null)[] = [
      (input.name || '').trim(),
      input.category ? input.category.trim() : null,
      input.note ? input.note.trim() : null,
      input.isCritical ? 1 : 0
    ];

    try {
      await store.executeSql(sql, args);
      Logger.info('insert done.');
      return true;
    } catch (e) {
      Logger.error(`insert failed: ${String(e)}`);
      return false;
    }
  }

  async queryAll(): Promise<ItemRow[]> {
    await this.ensureReady();
    const rows: ItemRow[] = [];
    if (!store) {
      Logger.error('DB not initialized');
      return rows;
    }

    try {
      const resultSet = await store.querySql(CommonConstants.SQL_QUERY_ALL_ITEMS);
      while (resultSet.goToNextRow()) {
        const idIdx = resultSet.getColumnIndex(CommonConstants.C_ID);
        const nameIdx = resultSet.getColumnIndex(CommonConstants.C_NAME);
        const catIdx = resultSet.getColumnIndex(CommonConstants.C_CATEGORY);
        const noteIdx = resultSet.getColumnIndex(CommonConstants.C_NOTE);
        const critIdx = resultSet.getColumnIndex(CommonConstants.C_IS_CRITICAL);

        rows.push({
          id: Number(resultSet.getLong(idIdx)),
          name: resultSet.getString(nameIdx),
          category: resultSet.isColumnNull(catIdx) ? null : resultSet.getString(catIdx),
          note: resultSet.isColumnNull(noteIdx) ? null : resultSet.getString(noteIdx),
          isCritical: Number(resultSet.getLong(critIdx))
        });
      }
      resultSet.close();
    } catch (e) {
      Logger.error(`queryAll failed: ${String(e)}`);
    }

    return rows;
  }

  async updateItem(id: number, patch: ItemUpdatePatch): Promise<boolean> {
    await this.ensureReady();
    if (!store) {
      Logger.error('DB not initialized');
      return false;
    }

    const sets: string[] = [];
    const args: (string | number | null)[] = [];

    if (patch.name !== undefined) {
      sets.push(`${CommonConstants.C_NAME} = ?`);
      args.push(patch.name);
    }
    if (patch.category !== undefined) {
      sets.push(`${CommonConstants.C_CATEGORY} = ?`);
      args.push(patch.category);
    }
    if (patch.note !== undefined) {
      sets.push(`${CommonConstants.C_NOTE} = ?`);
      args.push(patch.note);
    }
    if (patch.isCritical !== undefined) {
      sets.push(`${CommonConstants.C_IS_CRITICAL} = ?`);
      args.push(patch.isCritical);
    }

    if (sets.length === 0) {
      return true;
    }

    const sql = `UPDATE ${CommonConstants.T_ITEMS} SET ${sets.join(', ')} WHERE ${CommonConstants.C_ID} = ?`;
    args.push(id);

    try {
      await store.executeSql(sql, args);
      Logger.info('update done.');
      return true;
    } catch (e) {
      Logger.error(`update failed: ${String(e)}`);
      return false;
    }
  }

  async deleteItem(id: number): Promise<boolean> {
    await this.ensureReady();
    if (!store) {
      Logger.error('DB not initialized');
      return false;
    }
    const sql = `DELETE FROM ${CommonConstants.T_ITEMS} WHERE ${CommonConstants.C_ID} = ?`;

    try {
      await store.executeSql(sql, [id]);
      Logger.info('delete done.');
      return true;
    } catch (e) {
      Logger.error(`delete failed: ${String(e)}`);
      return false;
    }
  }

  begin() { store?.beginTransaction(); }
  rollback() { store?.rollBack(); }
  commit() { store?.commit(); }

  async backup(callback: () => void) {
    await this.ensureReady();
    if (!store) {
      Logger.error('DB not initialized');
      return;
    }
    store.backup('homecheck_backup.db', (err) => {
      if (err) {
        Logger.error(`backup failed, code=${err.code}, message=${err.message}`);
        return;
      }
      Logger.info('backup ok.');
      callback();
    });
  }

  async restore(callback: () => void) {
    await this.ensureReady();
    if (!store) {
      Logger.error('DB not initialized');
      return;
    }
    store.restore('homecheck_backup.db', (err) => {
      if (err) {
        Logger.error(`restore failed, code=${err.code}, message=${err.message}`);
        return;
      }
      Logger.info('restore ok.');
      callback();
    });
  }
}

let dbUtils = new DBUtils();
export default dbUtils as DBUtils;
