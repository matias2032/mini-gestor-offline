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

  /// Bump this and add a branch in [_onUpgrade] whenever the schema changes.
  static const int _databaseVersion = 1;

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

  /// Migration entry point for future schema versions.
  ///
  /// Add one `if (oldVersion < N)` block per version bump, each applying
  /// only the incremental change (ALTER TABLE, new CREATE TABLE, data
  /// backfill, etc.). Never rewrite older blocks — that breaks upgrades
  /// for users stuck on older versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example for the future:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE sale ADD COLUMN discount_cents INTEGER NOT NULL DEFAULT 0');
    // }
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
  // SCHEMA — kept as a plain list of statements executed in order.
  // Table order matters: a table must exist before another references it
  // as a foreign key.
  // ============================================================
  static const List<String> _schemaStatements = [
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

    // ---------- sale_category ----------
    '''
    CREATE TABLE sale_category (
        id_sale_category INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT NOT NULL UNIQUE,
        description      TEXT,
        deleted          INTEGER NOT NULL DEFAULT 0,
        created_at       TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at       TEXT
    )
    ''',

    // ---------- customer ----------
    '''
    CREATE TABLE customer (
        id_customer INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        last_name   TEXT,
        phone       TEXT,
        notes       TEXT,
        deleted     INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at  TEXT
    )
    ''',
    'CREATE INDEX idx_customer_name ON customer(name)',

    // ---------- sale ----------
    '''
    CREATE TABLE sale (
        id_sale                INTEGER PRIMARY KEY AUTOINCREMENT,
        reference               TEXT NOT NULL UNIQUE,
        sale_category_id        INTEGER NOT NULL
            REFERENCES sale_category(id_sale_category),
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

        CHECK (
            sale_type != 'CREDIT'
            OR customer_id IS NOT NULL
            OR walk_in_customer_name IS NOT NULL
        )
    )
    ''',
    'CREATE INDEX idx_sale_status ON sale(sale_status)',
    'CREATE INDEX idx_sale_category ON sale(sale_category_id)',
    'CREATE INDEX idx_sale_customer ON sale(customer_id)',
    'CREATE INDEX idx_sale_date ON sale(sale_date)',
    'CREATE INDEX idx_sale_type ON sale(sale_type)',
    '''
    CREATE TRIGGER trg_sale_updated
    AFTER UPDATE ON sale
    BEGIN
        UPDATE sale SET updated_at = datetime('now') WHERE id_sale = NEW.id_sale;
    END
    ''',

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
    '''
    CREATE TABLE supplier (
        id_supplier INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        phone       TEXT,
        address     TEXT,
        deleted     INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT NOT NULL DEFAULT (datetime('now'))
    )
    ''',

    // ---------- expense_category ----------
    '''
    CREATE TABLE expense_category (
        id_expense_category INTEGER PRIMARY KEY AUTOINCREMENT,
        name                 TEXT NOT NULL UNIQUE,
        description          TEXT,
        deleted              INTEGER NOT NULL DEFAULT 0
    )
    ''',

    // ---------- expense ----------
    '''
    CREATE TABLE expense (
        id_expense             INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_category_id     INTEGER NOT NULL
            REFERENCES expense_category(id_expense_category),
        supplier_id               INTEGER
            REFERENCES supplier(id_supplier),
        description                 TEXT NOT NULL,
        amount_cents                 INTEGER NOT NULL CHECK (amount_cents >= 0),
        expense_date                   TEXT NOT NULL DEFAULT (datetime('now')),
        deletion_reason                  TEXT,
        deleted                            INTEGER NOT NULL DEFAULT 0,
        created_at                           TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at                             TEXT
    )
    ''',
    'CREATE INDEX idx_expense_category ON expense(expense_category_id)',
    'CREATE INDEX idx_expense_supplier ON expense(supplier_id)',
    'CREATE INDEX idx_expense_date ON expense(expense_date)',
    '''
    CREATE TRIGGER trg_expense_updated
    AFTER UPDATE ON expense
    BEGIN
        UPDATE expense SET updated_at = datetime('now') WHERE id_expense = NEW.id_expense;
    END
    ''',
  ];
}