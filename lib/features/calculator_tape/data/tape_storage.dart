import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:sqlite3/sqlite3.dart';

import '../../../core/types/decimal_value.dart';
import '../domain/tape_models.dart';

final tapeStorageProvider = Provider<TapeStorage>((ref) {
  final storage = TapeStorage();
  ref.onDispose(storage.close);
  return storage;
});

class TapeSnapshotInfo {
  const TapeSnapshotInfo({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String name;
  final DateTime createdAt;
}

class TapeStorage {
  Database? _db;
  Future<Database>? _opening;

  Future<void> close() async {
    _db?.dispose();
    _db = null;
    _opening = null;
  }

  Future<void> saveLatest(TapeSessionState state) async {
    final db = await _database();
    final now = DateTime.now().toIso8601String();
    final payload = _encode(state);
    db.execute(
      '''
      INSERT INTO tape_latest_state (id, payload, updated_at)
      VALUES (1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET payload=excluded.payload, updated_at=excluded.updated_at
      ''',
      [payload, now],
    );
  }

  Future<TapeSessionState?> loadLatest() async {
    final db = await _database();
    final rs = db.select(
      'SELECT payload FROM tape_latest_state WHERE id = 1 LIMIT 1',
    );
    if (rs.isEmpty) return null;
    return _decode(rs.first['payload'] as String);
  }

  Future<String> saveSnapshot(TapeSessionState state) async {
    final db = await _database();
    final name = DateFormat('yyyyMMddHHmm').format(DateTime.now());
    final createdAt = DateTime.now().toIso8601String();
    db.execute(
      'INSERT INTO tape_snapshots(name, payload, created_at) VALUES(?, ?, ?)',
      [name, _encode(state), createdAt],
    );
    return name;
  }

  Future<List<TapeSnapshotInfo>> listSnapshots() async {
    final db = await _database();
    final rs = db.select(
      'SELECT id, name, created_at FROM tape_snapshots ORDER BY created_at DESC',
    );
    return rs
        .map(
          (r) => TapeSnapshotInfo(
            id: r['id'] as int,
            name: r['name'] as String,
            createdAt: DateTime.parse(r['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<TapeSessionState?> loadSnapshot(int id) async {
    final db = await _database();
    final rs = db.select(
      'SELECT payload FROM tape_snapshots WHERE id = ? LIMIT 1',
      [id],
    );
    if (rs.isEmpty) return null;
    return _decode(rs.first['payload'] as String);
  }

  Future<Database> _database() async {
    final existing = _db;
    if (existing != null) return existing;

    if (_opening != null) {
      return _opening!;
    }

    _opening = _openAndPrepare();
    final opened = await _opening!;
    _db = opened;
    _opening = null;
    return opened;
  }

  Future<Database> _openAndPrepare() async {
    final db = await _openDb();
    db.execute('''
      CREATE TABLE IF NOT EXISTS tape_latest_state(
        id INTEGER PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
      ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS tape_snapshots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
      ''');
    return db;
  }

  Future<Database> _openDb() async {
    if (kIsWeb) {
      return sqlite3.openInMemory();
    }
    final dbDir = await getDatabasesPath();
    await Directory(dbDir).create(recursive: true);
    final dbPath = p.join(dbDir, 'tape_sessions.sqlite');
    return sqlite3.open(dbPath);
  }

  String _encode(TapeSessionState state) {
    final json = {
      'inputBuffer': state.inputBuffer,
      'expressionBuffer': state.expressionBuffer,
      'equalsCount': state.equalsCount,
      'cycle': state.cycle,
      'lastInterimResult': state.lastInterimResult?.toString(),
      'pendingOperation': state.pendingOperation?.name,
      'pendingLeftOperand': state.pendingLeftOperand?.toString(),
      'pendingExpression': state.pendingExpression,
      'memories': {
        for (final e in state.memories.entries) e.key.name: e.value?.toString(),
      },
      'lines': state.lines
          .map(
            (line) => {
              'index': line.index,
              'sign': line.sign.name,
              'amount': line.amount.toString(),
              'kind': line.kind.name,
              'expression': line.expression,
              'createdAt': line.createdAt.toIso8601String(),
            },
          )
          .toList(),
    };
    return jsonEncode(json);
  }

  TapeSessionState _decode(String payload) {
    final raw = jsonDecode(payload) as Map<String, dynamic>;
    final linesRaw = (raw['lines'] as List<dynamic>? ?? <dynamic>[]);
    final memoriesRaw = (raw['memories'] as Map<String, dynamic>? ?? {});

    final lines = linesRaw
        .map((e) => e as Map<String, dynamic>)
        .map(
          (e) => TapeLine(
            index: e['index'] as int,
            sign: _signByName(e['sign'] as String),
            amount: DecimalValue.parse(e['amount'] as String),
            kind: _kindByName(e['kind'] as String),
            expression: e['expression'] as String?,
            createdAt: DateTime.parse(e['createdAt'] as String),
          ),
        )
        .toList();

    return TapeSessionState(
      lines: lines,
      inputBuffer: (raw['inputBuffer'] as String?) ?? '0',
      expressionBuffer: (raw['expressionBuffer'] as String?) ?? '',
      equalsCount: (raw['equalsCount'] as int?) ?? 0,
      cycle: (raw['cycle'] as int?) ?? 1,
      lastInterimResult: raw['lastInterimResult'] == null
          ? null
          : DecimalValue.parse(raw['lastInterimResult'] as String),
      pendingOperation: raw['pendingOperation'] == null
          ? null
          : _pendingByName(raw['pendingOperation'] as String),
      pendingLeftOperand: raw['pendingLeftOperand'] == null
          ? null
          : DecimalValue.parse(raw['pendingLeftOperand'] as String),
      pendingExpression: raw['pendingExpression'] as String?,
      memories: {
        for (final slot in TapeMemorySlot.values)
          slot: memoriesRaw[slot.name] == null
              ? null
              : DecimalValue.parse(memoriesRaw[slot.name] as String),
      },
    );
  }

  TapeLineSign _signByName(String name) {
    return TapeLineSign.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TapeLineSign.plus,
    );
  }

  TapeLineKind _kindByName(String name) {
    return TapeLineKind.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TapeLineKind.normal,
    );
  }

  TapePendingOperation _pendingByName(String name) {
    return TapePendingOperation.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TapePendingOperation.multiply,
    );
  }
}
