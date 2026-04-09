import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/display_settings.dart';

class DisplaySettingsStorage {
  Database? _db;

  Future<DisplaySettings?> load() async {
    try {
      final db = await _database();

      final rows = await db.query(
        'display_settings',
        where: 'id = ?',
        whereArgs: const [1],
        limit: 1,
      );
      if (rows.isEmpty) return DisplaySettings.initial();

      final stockRows = await db.query(
        'market_stock_symbols',
        orderBy: 'position ASC',
      );
      final newsRows = await db.query(
        'market_news_sources',
        orderBy: 'position ASC',
      );

      final data = rows.first;
      final stockSymbols = stockRows
          .map((item) => item['symbol'].toString().trim().toUpperCase())
          .where((item) => item.isNotEmpty)
          .take(maxMarketStockSymbols)
          .toList();
      final newsSources = newsRows
          .map((item) => item['source'].toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();

      return DisplaySettings(
        decimalDigits: (data['decimal_digits'] as int?) ?? 2,
        useGrouping: ((data['use_grouping'] as int?) ?? 1) == 1,
        tapeKeySoundEnabled:
            ((data['tape_key_sound_enabled'] as int?) ?? 1) == 1,
        vatRatePercent: (data['vat_rate_percent'] as int?) ?? 18,
        tapeSaveModeEnabled:
            ((data['tape_save_mode_enabled'] as int?) ?? 0) == 1,
        tapeKeyHeight: ((data['tape_key_height'] as int?) ?? 47).clamp(44, 58),
        tapeAuxLeft: _auxFrom(data['tape_aux_left'] as String?),
        tapeAuxRight: _auxFrom(data['tape_aux_right'] as String?),
        marketPriceDigits:
            ((data['market_price_digits'] as int?) ?? 2).clamp(0, 4),
        marketStockSymbols: stockSymbols,
        marketNewsSources:
            newsSources.isEmpty
                ? DisplaySettings.initial().marketNewsSources
                : newsSources,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DisplaySettings settings) async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.insert(
        'display_settings',
        {
          'id': 1,
          'decimal_digits': settings.decimalDigits,
          'use_grouping': settings.useGrouping ? 1 : 0,
          'tape_key_sound_enabled': settings.tapeKeySoundEnabled ? 1 : 0,
          'vat_rate_percent': settings.vatRatePercent,
          'tape_save_mode_enabled': settings.tapeSaveModeEnabled ? 1 : 0,
          'tape_key_height': settings.tapeKeyHeight,
          'tape_aux_left': settings.tapeAuxLeft.name,
          'tape_aux_right': settings.tapeAuxRight.name,
          'market_price_digits': settings.marketPriceDigits,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('market_stock_symbols');
      for (var index = 0; index < settings.marketStockSymbols.length; index++) {
        await txn.insert('market_stock_symbols', {
          'position': index,
          'symbol': settings.marketStockSymbols[index],
        });
      }

      await txn.delete('market_news_sources');
      for (var index = 0; index < settings.marketNewsSources.length; index++) {
        await txn.insert('market_news_sources', {
          'position': index,
          'source': settings.marketNewsSources[index],
        });
      }
    });
  }

  TapeAuxKeyOption _auxFrom(String? name) {
    if (name == null) return TapeAuxKeyOption.dollar;
    return TapeAuxKeyOption.values.firstWhere(
      (item) => item.name == name,
      orElse: () => TapeAuxKeyOption.dollar,
    );
  }

  Future<Database> _database() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'display_settings.sqlite');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedInitialData(db);
      },
      onOpen: (db) async {
        await _createSchema(db);
        final existing = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM display_settings'),
        );
        if ((existing ?? 0) == 0) {
          await _seedInitialData(db);
        }
      },
    );
    return _db!;
  }

  Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS display_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        decimal_digits INTEGER NOT NULL,
        use_grouping INTEGER NOT NULL,
        tape_key_sound_enabled INTEGER NOT NULL,
        vat_rate_percent INTEGER NOT NULL,
        tape_save_mode_enabled INTEGER NOT NULL,
        tape_key_height INTEGER NOT NULL,
        tape_aux_left TEXT NOT NULL,
        tape_aux_right TEXT NOT NULL,
        market_price_digits INTEGER NOT NULL
      )
      ''',
    );
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS market_stock_symbols (
        position INTEGER PRIMARY KEY,
        symbol TEXT NOT NULL
      )
      ''',
    );
    await db.execute(
      '''
      CREATE TABLE IF NOT EXISTS market_news_sources (
        position INTEGER PRIMARY KEY,
        source TEXT NOT NULL
      )
      ''',
    );
  }

  Future<void> _seedInitialData(DatabaseExecutor db) async {
    final initial = DisplaySettings.initial();
    await db.insert(
      'display_settings',
      {
        'id': 1,
        'decimal_digits': initial.decimalDigits,
        'use_grouping': initial.useGrouping ? 1 : 0,
        'tape_key_sound_enabled': initial.tapeKeySoundEnabled ? 1 : 0,
        'vat_rate_percent': initial.vatRatePercent,
        'tape_save_mode_enabled': initial.tapeSaveModeEnabled ? 1 : 0,
        'tape_key_height': initial.tapeKeyHeight,
        'tape_aux_left': initial.tapeAuxLeft.name,
        'tape_aux_right': initial.tapeAuxRight.name,
        'market_price_digits': initial.marketPriceDigits,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    for (var index = 0; index < initial.marketStockSymbols.length; index++) {
      await db.insert('market_stock_symbols', {
        'position': index,
        'symbol': initial.marketStockSymbols[index],
      });
    }
    for (var index = 0; index < initial.marketNewsSources.length; index++) {
      await db.insert('market_news_sources', {
        'position': index,
        'source': initial.marketNewsSources[index],
      });
    }
  }
}
