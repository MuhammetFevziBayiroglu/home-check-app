export class CommonConstants {
  static readonly DB_NAME = 'homecheck.db';

  static readonly T_ITEMS = 'items';
  static readonly C_ID = 'id';
  static readonly C_NAME = 'name';
  static readonly C_CATEGORY = 'category';
  static readonly C_NOTE = 'note';
  static readonly C_IS_CRITICAL = 'is_critical';

  static readonly SQL_CREATE_ITEMS_TABLE =
    `CREATE TABLE IF NOT EXISTS ${CommonConstants.T_ITEMS} (
      ${CommonConstants.C_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${CommonConstants.C_NAME} TEXT NOT NULL,
      ${CommonConstants.C_CATEGORY} TEXT,
      ${CommonConstants.C_NOTE} TEXT,
      ${CommonConstants.C_IS_CRITICAL} INTEGER DEFAULT 0
    );`;


  static readonly SQL_CREATE_INDEX_CRITICAL =
    `CREATE INDEX IF NOT EXISTS idx_items_is_critical
     ON ${CommonConstants.T_ITEMS}(${CommonConstants.C_IS_CRITICAL});`;

  static readonly SQL_QUERY_ALL_ITEMS = `
  SELECT
    ${CommonConstants.C_ID} AS ${CommonConstants.C_ID},
    ${CommonConstants.C_NAME} AS ${CommonConstants.C_NAME},
    ${CommonConstants.C_CATEGORY} AS ${CommonConstants.C_CATEGORY},
    ${CommonConstants.C_NOTE} AS ${CommonConstants.C_NOTE},
    ${CommonConstants.C_IS_CRITICAL} AS ${CommonConstants.C_IS_CRITICAL}
  FROM ${CommonConstants.T_ITEMS}
  ORDER BY
    ${CommonConstants.C_CATEGORY} COLLATE NOCASE,
    ${CommonConstants.C_NAME} COLLATE NOCASE,
    ${CommonConstants.C_ID} ASC;
`;


  static readonly EMPTY_STRING = '';
  static readonly PROGRESS_MAX = 100;
  static readonly PROGRESS_STEP = 20;
  static readonly PERCENT_WIDTH = '100%';
  static readonly PERCENT_NINETY_WIDTH = '90%';
  static readonly NUMBER_100 = 100;
  static readonly NUMBER_400 = 400;
  static readonly NUMBER_500 = 500;

  static readonly INIT_NAME = 'New item';

  static readonly BUILTIN_ITEMS = ['keys', 'wallet', 'phone', 'charger', 'stove', 'lights'];
}
