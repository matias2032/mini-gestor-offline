import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Handles low-level access to the local SQLite database.
///
/// This class is pure infrastructure: it knows how to open the database,
/// run the schema, and manage migrations. It must never contain business
/// logic (e.g. no knowledge of what "credit sale" or "outstanding" means).
/// Business rules belong in the repositories layer.
class LocalDatabase {
  LocalDatabase._internal();

  static final LocalDatabase instance = LocalDatabase._internal();

  static const String _databaseName = 'business_manager.db';

  // v2: introduces Matriz & Unidades de Negócio (BusinessUnit).
  // v3: business_category.name is no longer globally UNIQUE — uniqueness
  // is now enforced by BusinessCategoryRepository, scoped per business
  // unit (a global name is still checked against every unit, since a
  // global category is visible everywhere). See _onUpgrade / _migrateToV3.
  static const int _databaseVersion = 3;

  Database? _database;

  /// Returns the open database, opening it on first access.
  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // SQLite ignores foreign keys by default — must be enabled per connection.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final statement in _schemaStatements) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
  }
  /// Runs [action] inside a single SQLite transaction.
  ///
  /// Use this from repositories whenever an operation touches more than
  /// one table and must be all-or-nothing (e.g. registering a payment that
  /// updates `sale`, `sale_installment` and inserts into `sale_payment`).
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return db.transaction<T>(action);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Deletes the entire database file, as if the app had just been
  /// installed for the first time. Debug/testing utility only — see
  /// `_debugResetDatabaseOnStart` in main.dart for the on/off switch.
  Future<void> resetDatabase() async {
    await close();
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await deleteDatabase(path);
  }

  // ============================================================
  // MIGRATION v1 -> v2
  //
  // Introduces `business_unit` (Sede/Loja/Departamento sob a mesma conta).
  //
  //  - `sale` and `expense` become strictly scoped to a unit
  //    (business_unit_id NOT NULL). SQLite has no ALTER COLUMN, so both
  //    tables are rebuilt following SQLite's documented "twelve steps"
  //    table-recreation procedure.
  //  - `customer`, `supplier`, `business_category` and `financial_statement`
  //    get a NULLABLE business_unit_id. Existing rows are left as NULL
  //    (= Global), which preserves their current "visible everywhere"
  //    behaviour exactly as it was before the migration.
  //  - A default business unit ("Sede") is created from the existing
  //    `user.business_name` and used to backfill every `sale`/`expense` row.
  // ============================================================
  Future<void> _migrateToV2(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');

    // 1. business_unit table itself.
    await db.execute(_createBusinessUnitTable);
    await db.execute(_createBusinessUnitUpdatedTrigger);

    // 2. Seed the default unit from the existing holding name.
    final userRows = await db.query(
      'user',
      columns: ['business_name'],
      limit: 1,
    );
    final holdingName =
        (userRows.isNotEmpty ? userRows.first['business_name'] as String? : null) ??
            'Minha Loja';

    final defaultUnitId = await db.insert('business_unit', {
      'name': holdingName,
      'is_default': 1,
      'deleted': 0,
    });

    // 3. Hybrid-scope tables: add nullable column + index, no backfill
    //    (NULL = Global keeps today's behaviour unchanged).
    await db.execute(
      'ALTER TABLE customer ADD COLUMN business_unit_id INTEGER '
      'REFERENCES business_unit(id_business_unit)',
    );
    await db.execute(
      'ALTER TABLE supplier ADD COLUMN business_unit_id INTEGER '
      'REFERENCES business_unit(id_business_unit)',
    );
    await db.execute(
      'ALTER TABLE business_category ADD COLUMN business_unit_id INTEGER '
      'REFERENCES business_unit(id_business_unit)',
    );
    await db.execute(
      'ALTER TABLE financial_statement ADD COLUMN business_unit_id INTEGER '
      'REFERENCES business_unit(id_business_unit)',
    );
    await db.execute(
      'CREATE INDEX idx_customer_business_unit ON customer(business_unit_id)',
    );
    await db.execute(
      'CREATE INDEX idx_supplier_business_unit ON supplier(business_unit_id)',
    );
    await db.execute(
      'CREATE INDEX idx_business_category_business_unit '
      'ON business_category(business_unit_id)',
    );
    await db.execute(
      'CREATE INDEX idx_financial_statement_business_unit '
      'ON financial_statement(business_unit_id)',
    );

    // 4. Strict-scope tables: rebuild with business_unit_id NOT NULL,
    //    backfilled to the default unit.
    await _rebuildSaleTable(db, defaultUnitId);
    await _rebuildExpenseTable(db, defaultUnitId);

    final fkViolations = await db.rawQuery('PRAGMA foreign_key_check');
    if (fkViolations.isNotEmpty) {
      throw StateError(
        'Migração para v2 falhou na verificação de integridade '
        'referencial: $fkViolations',
      );
    }

    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _rebuildSaleTable(Database db, int defaultUnitId) async {
    await db.execute('ALTER TABLE sale RENAME TO sale_old');
    await db.execute(_createSaleTableV2);

    await db.execute(
      '''
      INSERT INTO sale (
        id_sale, reference, sale_category_id, description, total_amount_cents,
        sale_type, credit_modality, sale_status, payment_status, paid_amount_cents,
        customer_id, walk_in_customer_name, sale_date, credit_due_date, completed_at,
        notes, cancellation_reason, deleted, created_at, updated_at, business_unit_id
      )
      SELECT
        id_sale, reference, sale_category_id, description, total_amount_cents,
        sale_type, credit_modality, sale_status, payment_status, paid_amount_cents,
        customer_id, walk_in_customer_name, sale_date, credit_due_date, completed_at,
        notes, cancellation_reason, deleted, created_at, updated_at, ?
      FROM sale_old
      ''',
      [defaultUnitId],
    );

    await db.execute('DROP TABLE sale_old');

    await db.execute('CREATE INDEX idx_sale_status ON sale(sale_status)');
    await db.execute('CREATE INDEX idx_sale_category ON sale(sale_category_id)');
    await db.execute('CREATE INDEX idx_sale_customer ON sale(customer_id)');
    await db.execute('CREATE INDEX idx_sale_date ON sale(sale_date)');
    await db.execute('CREATE INDEX idx_sale_type ON sale(sale_type)');
    await db.execute(
      'CREATE INDEX idx_sale_business_unit ON sale(business_unit_id)',
    );
    await db.execute(_createSaleUpdatedTrigger);
  }

  Future<void> _rebuildExpenseTable(Database db, int defaultUnitId) async {
    await db.execute('ALTER TABLE expense RENAME TO expense_old');
    await db.execute(_createExpenseTableV2);

    await db.execute(
      '''
      INSERT INTO expense (
        id_expense, supplier_id, description, amount_cents, expense_date,
        deletion_reason, deleted, created_at, updated_at, business_unit_id
      )
      SELECT
        id_expense, supplier_id, description, amount_cents, expense_date,
        deletion_reason, deleted, created_at, updated_at, ?
      FROM expense_old
      ''',
      [defaultUnitId],
    );

    await db.execute('DROP TABLE expense_old');

    await db.execute('CREATE INDEX idx_expense_supplier ON expense(supplier_id)');
    await db.execute('CREATE INDEX idx_expense_date ON expense(expense_date)');
    await db.execute(
      'CREATE INDEX idx_expense_business_unit ON expense(business_unit_id)',
    );
    await db.execute(_createExpenseUpdatedTrigger);
  }

  // ============================================================
  // MIGRATION v2 -> v3
  //
  // Drops the global UNIQUE(name) on business_category. It made sense
  // when there was only one store; with hybrid business-unit scoping it
  // wrongly stopped two different lojas from having a category with the
  // same name. SQLite can't drop an inline UNIQUE via ALTER TABLE, so the
  // table is rebuilt without it, keeping every other column/FK unchanged.
  // Uniqueness is now enforced by BusinessCategoryRepository instead.
  // ============================================================
  Future<void> _migrateToV3(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');

    await _rebuildBusinessCategoryTable(db);

    final fkViolations = await db.rawQuery('PRAGMA foreign_key_check');
    if (fkViolations.isNotEmpty) {
      throw StateError(
        'Migração para v3 falhou na verificação de integridade '
        'referencial: $fkViolations',
      );
    }

    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _rebuildBusinessCategoryTable(Database db) async {
    await db.execute('ALTER TABLE business_category RENAME TO business_category_old');
    await db.execute(_createBusinessCategoryTableV3);

    await db.execute(
      '''
      INSERT INTO business_category (
        id_business_category, name, description, business_unit_id,
        deleted, created_at, updated_at
      )
      SELECT
        id_business_category, name, description, business_unit_id,
        deleted, created_at, updated_at
      FROM business_category_old
      ''',
    );

    await db.execute('DROP TABLE business_category_old');

    await db.execute(
      'CREATE INDEX idx_business_category_business_unit '
      'ON business_category(business_unit_id)',
    );
    await db.execute(_createBusinessCategoryUpdatedTrigger);
  }

  // ---------- business_unit (shared by onCreate and the v1->v2 migration) ----------
  static const String _createBusinessUnitTable = '''
    CREATE TABLE business_unit (
        id_business_unit INTEGER PRIMARY KEY AUTOINCREMENT,
        name              TEXT NOT NULL,
        is_default        INTEGER NOT NULL DEFAULT 0,
        deleted           INTEGER NOT NULL DEFAULT 0,
        created_at        TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at        TEXT
    )
  ''';

  static const String _createBusinessUnitUpdatedTrigger = '''
    CREATE TRIGGER trg_business_unit_updated
    AFTER UPDATE ON business_unit
    BEGIN
        UPDATE business_unit SET updated_at = datetime('now')
        WHERE id_business_unit = NEW.id_business_unit;
    END
  ''';

  // ---------- sale (v2 shape, with business_unit_id NOT NULL) ----------
  static const String _createSaleTableV2 = '''
    CREATE TABLE sale (
        id_sale                INTEGER PRIMARY KEY AUTOINCREMENT,
        reference               TEXT NOT NULL UNIQUE,
        sale_category_id        INTEGER NOT NULL
            REFERENCES business_category(id_business_category),
        description              TEXT NOT NULL,
        total_amount_cents        INTEGER NOT NULL CHECK (total_amount_cents >= 0),

        sale_type                 TEXT NOT NULL DEFAULT 'NORMAL'
            CHECK (sale_type IN ('NORMAL','CREDIT')),
        credit_modality            TEXT
            CHECK (credit_modality IN ('SINGLE_PAYMENT','INSTALLMENTS')),

        sale_status                 TEXT NOT NULL DEFAULT 'COMPLETED'
            CHECK (sale_status IN ('OPEN','OUTSTANDING','COMPLETED','CANCELLED')),
        payment_status               TEXT NOT NULL DEFAULT 'PAID'
            CHECK (payment_status IN ('PENDING','PARTIAL','PAID')),
        paid_amount_cents             INTEGER NOT NULL DEFAULT 0,

        customer_id                    INTEGER REFERENCES customer(id_customer),
        walk_in_customer_name           TEXT,

        sale_date                        TEXT NOT NULL DEFAULT (datetime('now')),
        credit_due_date                   TEXT,
        completed_at                        TEXT,

        notes                                 TEXT,
        cancellation_reason                    TEXT,

        deleted                                 INTEGER NOT NULL DEFAULT 0,
        created_at                                TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at                                 TEXT,

        business_unit_id                            INTEGER NOT NULL
            REFERENCES business_unit(id_business_unit),

        CHECK (
            sale_type != 'CREDIT'
            OR customer_id IS NOT NULL
            OR walk_in_customer_name IS NOT NULL
        )
    )
  ''';

  static const String _createSaleUpdatedTrigger = '''
    CREATE TRIGGER trg_sale_updated
    AFTER UPDATE ON sale
    BEGIN
        UPDATE sale SET updated_at = datetime('now') WHERE id_sale = NEW.id_sale;
    END
  ''';

  // ---------- expense (v2 shape, with business_unit_id NOT NULL) ----------
  static const String _createExpenseTableV2 = '''
    CREATE TABLE expense (
        id_expense             INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id               INTEGER
            REFERENCES supplier(id_supplier),
        description                 TEXT NOT NULL,
        amount_cents                 INTEGER NOT NULL CHECK (amount_cents >= 0),
        expense_date                   TEXT NOT NULL DEFAULT (datetime('now')),
        deletion_reason                  TEXT,
        deleted                            INTEGER NOT NULL DEFAULT 0,
        created_at                           TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at                             TEXT,
        business_unit_id                         INTEGER NOT NULL
            REFERENCES business_unit(id_business_unit)
    )
  ''';

  static const String _createExpenseUpdatedTrigger = '''
    CREATE TRIGGER trg_expense_updated
    AFTER UPDATE ON expense
    BEGIN
        UPDATE expense SET updated_at = datetime('now') WHERE id_expense = NEW.id_expense;
    END
  ''';

  // ---------- business_category (v3 shape — name no longer globally UNIQUE) ----------
  static const String _createBusinessCategoryTableV3 = '''
    CREATE TABLE business_category (
        id_business_category INTEGER PRIMARY KEY AUTOINCREMENT,
        name                  TEXT NOT NULL,
        description           TEXT,
        business_unit_id      INTEGER
            REFERENCES business_unit(id_business_unit),
        deleted               INTEGER NOT NULL DEFAULT 0,
        created_at            TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at            TEXT
    )
  ''';

  static const String _createBusinessCategoryUpdatedTrigger = '''
    CREATE TRIGGER trg_business_category_updated
    AFTER UPDATE ON business_category
    BEGIN
        UPDATE business_category SET updated_at = datetime('now')
        WHERE id_business_category = NEW.id_business_category;
    END
  ''';

  // ============================================================
  // SCHEMA (fresh installs) — kept as a plain list of statements executed
  // in order. Table order matters: a table must exist before another
  // references it as a foreign key. This already reflects the v2 shape,
  // since a brand-new install never goes through _onUpgrade.
  // ============================================================
  static final List<String> _schemaStatements = [
    // ---------- user ----------
    '''
    CREATE TABLE user (
        id_user               INTEGER PRIMARY KEY CHECK (id_user = 1),
        name                  TEXT NOT NULL,
        last_name             TEXT,
        phone                 TEXT,
        email                 TEXT,
        password_hash         TEXT NOT NULL,
        business_name         TEXT,
        currency              TEXT NOT NULL DEFAULT 'MZN',
        onboarding_completed  INTEGER NOT NULL DEFAULT 0,
        created_at            TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at            TEXT
    )
    ''',
    '''
    CREATE TRIGGER trg_user_updated
    AFTER UPDATE ON user
    BEGIN
        UPDATE user SET updated_at = datetime('now') WHERE id_user = NEW.id_user;
    END
    ''',

    // ---------- business_unit ----------
    // Represents each loja/departamento under the same account (matriz).
    // Created before any table that references it.
    _createBusinessUnitTable,
    _createBusinessUnitUpdatedTrigger,

    // ---------- business_category ----------
    // Unified category, shared by sales and expenses. Replaces the old
    // independent sale_category / expense_category tables so that a
    // "ramo de negócio" means the same thing on both sides, which is
    // what makes it possible to break down a financial statement
    // (extracto) by category and not just by grand total.
    // business_unit_id NULL = Global (visible to every loja); otherwise the
    // category belongs exclusively to that business unit.
    _createBusinessCategoryTableV3,
    'CREATE INDEX idx_business_category_business_unit '
        'ON business_category(business_unit_id)',
    _createBusinessCategoryUpdatedTrigger,

    // ---------- customer ----------
    // business_unit_id NULL = Global; otherwise exclusive to that unit.
    '''
    CREATE TABLE customer (
        id_customer       INTEGER PRIMARY KEY AUTOINCREMENT,
        name              TEXT NOT NULL,
        last_name         TEXT,
        phone             TEXT,
        notes             TEXT,
        business_unit_id  INTEGER
            REFERENCES business_unit(id_business_unit),
        deleted           INTEGER NOT NULL DEFAULT 0,
        created_at        TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at        TEXT
    )
    ''',
    'CREATE INDEX idx_customer_name ON customer(name)',
    'CREATE INDEX idx_customer_business_unit ON customer(business_unit_id)',

    // ---------- sale ----------
    _createSaleTableV2,
    'CREATE INDEX idx_sale_status ON sale(sale_status)',
    'CREATE INDEX idx_sale_category ON sale(sale_category_id)',
    'CREATE INDEX idx_sale_customer ON sale(customer_id)',
    'CREATE INDEX idx_sale_date ON sale(sale_date)',
    'CREATE INDEX idx_sale_type ON sale(sale_type)',
    'CREATE INDEX idx_sale_business_unit ON sale(business_unit_id)',
    _createSaleUpdatedTrigger,

    // ---------- sale_installment ----------
    '''
    CREATE TABLE sale_installment (
        id_sale_installment       INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id                    INTEGER NOT NULL
            REFERENCES sale(id_sale) ON DELETE CASCADE,
        installment_number          INTEGER NOT NULL,
        installment_amount_cents     INTEGER NOT NULL CHECK (installment_amount_cents > 0),
        paid_amount_cents             INTEGER NOT NULL DEFAULT 0,
        due_date                       TEXT NOT NULL,
        paid_at                         TEXT,
        installment_status               TEXT NOT NULL DEFAULT 'PENDING'
            CHECK (installment_status IN ('PENDING','PARTIAL','PAID','OVERDUE','CANCELLED')),
        cancelled_by_sale_cancellation    INTEGER NOT NULL DEFAULT 0,
        notes                              TEXT,
        UNIQUE (sale_id, installment_number)
    )
    ''',
    'CREATE INDEX idx_installment_sale ON sale_installment(sale_id)',

    // ---------- sale_payment ----------
    '''
    CREATE TABLE sale_payment (
        id_sale_payment    INTEGER PRIMARY KEY AUTOINCREMENT,
        reference           TEXT NOT NULL UNIQUE,
        sale_id              INTEGER NOT NULL
            REFERENCES sale(id_sale) ON DELETE CASCADE,
        installment_id        INTEGER
            REFERENCES sale_installment(id_sale_installment),
        paid_amount_cents      INTEGER NOT NULL CHECK (paid_amount_cents > 0),
        payment_method           TEXT NOT NULL DEFAULT 'CASH'
            CHECK (payment_method IN ('CASH','BANK_TRANSFER','MPESA','EMOLA','OTHER')),
        paid_at                    TEXT NOT NULL DEFAULT (datetime('now')),
        notes                        TEXT
    )
    ''',
    'CREATE INDEX idx_payment_sale ON sale_payment(sale_id)',

    // ---------- supplier ----------
    // business_unit_id NULL = Global; otherwise exclusive to that unit.
    '''
    CREATE TABLE supplier (
        id_supplier       INTEGER PRIMARY KEY AUTOINCREMENT,
        name              TEXT NOT NULL,
        phone             TEXT,
        address           TEXT,
        business_unit_id  INTEGER
            REFERENCES business_unit(id_business_unit),
        deleted           INTEGER NOT NULL DEFAULT 0,
        created_at        TEXT NOT NULL DEFAULT (datetime('now'))
    )
    ''',
    'CREATE INDEX idx_supplier_business_unit ON supplier(business_unit_id)',

    // ---------- expense ----------
    _createExpenseTableV2,
    'CREATE INDEX idx_expense_supplier ON expense(supplier_id)',
    'CREATE INDEX idx_expense_date ON expense(expense_date)',
    'CREATE INDEX idx_expense_business_unit ON expense(business_unit_id)',
    _createExpenseUpdatedTrigger,

    // ---------- expense_category_split ----------
    // A single expense can be shared across more than one business_category
    // (e.g. one internet bill funding both "digital marketing" and "web
    // development"). Instead of duplicating the expense row per category
    // (which would double-count it), the expense is recorded once and its
    // amount_cents is allocated across categories here. The sum of a given
    // expense's splits must always equal that expense's amount_cents — this
    // is enforced by ExpenseRepository inside a transaction, not by SQLite,
    // the same way paid_amount_cents vs sale_payment totals already are.
    '''
    CREATE TABLE expense_category_split (
        id_expense_category_split INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id                 INTEGER NOT NULL
            REFERENCES expense(id_expense) ON DELETE CASCADE,
        business_category_id        INTEGER NOT NULL
            REFERENCES business_category(id_business_category),
        amount_cents                  INTEGER NOT NULL CHECK (amount_cents > 0),
        UNIQUE (expense_id, business_category_id)
    )
    ''',
    'CREATE INDEX idx_expense_split_expense ON expense_category_split(expense_id)',
    'CREATE INDEX idx_expense_split_category ON expense_category_split(business_category_id)',

    // ============================================================
    // FINANCIAL STATEMENT ("extracto")
    //
    // Statements are snapshotted at generation time into the two child
    // tables below, so a statement's numbers never change even if the
    // underlying sale/expense rows are later edited or cancelled.
    //
    // Each item also snapshots the business_category (id + name), which
    // is what allows the extracto to be broken down by category —
    // grouping financial_statement_sale_item / financial_statement_expense_item
    // by business_category_id gives ganho/gasto/saldo por ramo, in
    // addition to the general totals on financial_statement itself.
    //
    // business_unit_id NULL = extracto consolidado da matriz/grupo;
    // otherwise, extracto de uma loja específica.
    // ============================================================

    // ---------- financial_statement ----------
    '''
    CREATE TABLE financial_statement (
        id_financial_statement INTEGER PRIMARY KEY AUTOINCREMENT,
        reference               TEXT NOT NULL UNIQUE,
        period_type              TEXT NOT NULL
            CHECK (period_type IN (
                'TODAY','LAST_24_HOURS','ONE_WEEK','ONE_MONTH',
                'THREE_MONTHS','SIX_MONTHS','ONE_YEAR','CUSTOM'
            )),
        start_date                 TEXT NOT NULL,
        end_date                    TEXT NOT NULL,
        business_unit_id             INTEGER
            REFERENCES business_unit(id_business_unit),
        total_sales_cents            INTEGER NOT NULL DEFAULT 0,
        total_expenses_cents          INTEGER NOT NULL DEFAULT 0,
        balance_cents                  INTEGER NOT NULL DEFAULT 0,
        sales_count                      INTEGER NOT NULL DEFAULT 0,
        expenses_count                    INTEGER NOT NULL DEFAULT 0,
        notes                               TEXT,
        deleted                              INTEGER NOT NULL DEFAULT 0,
        generated_at                          TEXT NOT NULL DEFAULT (datetime('now')),
        created_at                             TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at                              TEXT
    )
    ''',
    'CREATE INDEX idx_statement_period ON financial_statement(start_date, end_date)',
    'CREATE INDEX idx_statement_generated_at ON financial_statement(generated_at)',
    'CREATE INDEX idx_financial_statement_business_unit '
        'ON financial_statement(business_unit_id)',
    '''
    CREATE TRIGGER trg_financial_statement_updated
    AFTER UPDATE ON financial_statement
    BEGIN
        UPDATE financial_statement SET updated_at = datetime('now')
        WHERE id_financial_statement = NEW.id_financial_statement;
    END
    ''',

    // ---------- financial_statement_sale_item ----------
    '''
    CREATE TABLE financial_statement_sale_item (
        id_financial_statement_sale_item INTEGER PRIMARY KEY AUTOINCREMENT,
        financial_statement_id            INTEGER NOT NULL
            REFERENCES financial_statement(id_financial_statement) ON DELETE CASCADE,
        sale_id                             INTEGER NOT NULL
            REFERENCES sale(id_sale),
        sale_reference                        TEXT NOT NULL,
        sale_description                       TEXT NOT NULL,
        sale_date                               TEXT NOT NULL,
        business_category_id                     INTEGER
            REFERENCES business_category(id_business_category),
        business_category_name                    TEXT NOT NULL DEFAULT '',
        amount_cents                             INTEGER NOT NULL CHECK (amount_cents >= 0)
    )
    ''',
    'CREATE INDEX idx_statement_sale_item_statement '
        'ON financial_statement_sale_item(financial_statement_id)',
    'CREATE INDEX idx_statement_sale_item_category '
        'ON financial_statement_sale_item(business_category_id)',

    // ---------- financial_statement_expense_item ----------
    '''
    CREATE TABLE financial_statement_expense_item (
        id_financial_statement_expense_item INTEGER PRIMARY KEY AUTOINCREMENT,
        financial_statement_id               INTEGER NOT NULL
            REFERENCES financial_statement(id_financial_statement) ON DELETE CASCADE,
        expense_id                             INTEGER NOT NULL
            REFERENCES expense(id_expense),
        expense_description                     TEXT NOT NULL,
        expense_date                             TEXT NOT NULL,
        business_category_id                      INTEGER
            REFERENCES business_category(id_business_category),
        business_category_name                     TEXT NOT NULL DEFAULT '',
        amount_cents                              INTEGER NOT NULL CHECK (amount_cents >= 0)
    )
    ''',
    'CREATE INDEX idx_statement_expense_item_statement '
        'ON financial_statement_expense_item(financial_statement_id)',
    'CREATE INDEX idx_statement_expense_item_category '
        'ON financial_statement_expense_item(business_category_id)',
  ];
}