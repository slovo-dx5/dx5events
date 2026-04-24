import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class PendingActivity {
  final int? id;
  final String clientEventId;
  final int? userId;
  final String? eventId;
  final String action;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic>? metadata;
  final String? clientVersion;
  final String platform;
  final DateTime occurredAt;

  PendingActivity({
    this.id,
    required this.clientEventId,
    this.userId,
    this.eventId,
    required this.action,
    this.targetType,
    this.targetId,
    this.metadata,
    this.clientVersion,
    required this.platform,
    required this.occurredAt,
  });

  Map<String, dynamic> toRow() => {
        'id': id,
        'client_event_id': clientEventId,
        'user_id': userId,
        'event_id': eventId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'metadata': metadata == null ? null : jsonEncode(metadata),
        'client_version': clientVersion,
        'platform': platform,
        'occurred_at': occurredAt.toUtc().millisecondsSinceEpoch,
      };

  factory PendingActivity.fromRow(Map<String, dynamic> row) {
    final rawMetadata = row['metadata'];
    Map<String, dynamic>? metadata;
    if (rawMetadata is String && rawMetadata.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map) metadata = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return PendingActivity(
      id: row['id'] as int?,
      clientEventId: row['client_event_id'] as String,
      userId: row['user_id'] as int?,
      eventId: row['event_id'] as String?,
      action: row['action'] as String,
      targetType: row['target_type'] as String?,
      targetId: row['target_id'] as String?,
      metadata: metadata,
      clientVersion: row['client_version'] as String?,
      platform: row['platform'] as String,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row['occurred_at'] as int,
        isUtc: true,
      ),
    );
  }

  /// Directus payload shape (snake_case field names, ISO-8601 timestamp).
  Map<String, dynamic> toDirectusPayload() => {
        'client_event_id': clientEventId,
        'user_id': userId,
        'event_id': eventId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'metadata': metadata,
        'client_version': clientVersion,
        'platform': platform,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
      };
}

class ActivityQueueDatabase {
  static final ActivityQueueDatabase instance =
      ActivityQueueDatabase._init();
  static Database? _database;

  ActivityQueueDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dx5ve_activity.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_activity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_event_id TEXT NOT NULL UNIQUE,
        user_id INTEGER,
        event_id TEXT,
        action TEXT NOT NULL,
        target_type TEXT,
        target_id TEXT,
        metadata TEXT,
        client_version TEXT,
        platform TEXT NOT NULL,
        occurred_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_pending_activity_occurred_at ON pending_activity(occurred_at)',
    );
  }

  Future<void> insert(PendingActivity entry) async {
    final db = await database;
    final row = entry.toRow()..remove('id');
    await db.insert(
      'pending_activity',
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<PendingActivity>> takeBatch(int limit) async {
    final db = await database;
    final rows = await db.query(
      'pending_activity',
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map((r) => PendingActivity.fromRow(r)).toList();
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      'pending_activity',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<int> pendingCount() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM pending_activity',
    );
    return (rows.first['n'] as int?) ?? 0;
  }
}
