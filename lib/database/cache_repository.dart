import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class CacheRepository {
  static final CacheRepository instance = CacheRepository._init();
  static Database? _database;
  final Map<String, _MemEntry> _memory = {};

  CacheRepository._init();

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _initDB('dx5ve_cache.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cache_entries (
        key TEXT PRIMARY KEY,
        json_blob TEXT NOT NULL,
        fetched_at INTEGER NOT NULL
      )
    ''');
  }

  Future<dynamic> getJson(String key, Duration ttl) async {
    final now = DateTime.now();

    final mem = _memory[key];
    if (mem != null && now.difference(mem.fetchedAt) <= ttl) {
      return mem.data;
    }

    final db = await _db;
    final rows = await db.query(
      'cache_entries',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final fetchedAt =
        DateTime.fromMillisecondsSinceEpoch(row['fetched_at'] as int);
    if (now.difference(fetchedAt) > ttl) return null;

    try {
      final data = jsonDecode(row['json_blob'] as String);
      _memory[key] = _MemEntry(data: data, fetchedAt: fetchedAt);
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> putJson(String key, dynamic data) async {
    final now = DateTime.now();
    _memory[key] = _MemEntry(data: data, fetchedAt: now);
    final db = await _db;
    await db.insert(
      'cache_entries',
      {
        'key': key,
        'json_blob': jsonEncode(data),
        'fetched_at': now.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> invalidate(String key) async {
    _memory.remove(key);
    final db = await _db;
    await db.delete('cache_entries', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> invalidatePrefix(String prefix) async {
    _memory.removeWhere((k, _) => k.startsWith(prefix));
    final db = await _db;
    await db.delete(
      'cache_entries',
      where: 'key LIKE ?',
      whereArgs: ['$prefix%'],
    );
  }

  Future<void> clearAll() async {
    _memory.clear();
    final db = await _db;
    await db.delete('cache_entries');
  }
}

class _MemEntry {
  final dynamic data;
  final DateTime fetchedAt;
  _MemEntry({required this.data, required this.fetchedAt});
}
