import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ScannedContact {
  final int? id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String company;
  final String role;
  final int ownerID;
  final DateTime scannedAt;
  final String note;

  ScannedContact({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.company,
    required this.role,
    required this.ownerID,
    required this.scannedAt,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'company': company,
      'role': role,
      'ownerID': ownerID,
      'scannedAt': scannedAt.toIso8601String(),
      'note': note,
    };
  }

  factory ScannedContact.fromMap(Map<String, dynamic> map) {
    return ScannedContact(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      phone: map['phone'],
      email: map['email'],
      company: map['company'],
      role: map['role'],
      ownerID: map['ownerID'],
      scannedAt: DateTime.parse(map['scannedAt']),
      note: (map['note'] as String?) ?? '',
    );
  }
}

class ScannedContactsDatabase {
  static final ScannedContactsDatabase instance = ScannedContactsDatabase._init();
  static Database? _database;

  ScannedContactsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scanned_contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE scanned_contacts (
      id $idType,
      firstName $textType,
      lastName $textType,
      phone $textType,
      email $textType,
      company $textType,
      role $textType,
      ownerID $intType,
      scannedAt $textType,
      note TEXT NOT NULL DEFAULT ''
    )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE scanned_contacts ADD COLUMN note TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  // Returns the matching existing contact for this owner if one exists,
  // matching on email (when present) or otherwise on phone. Used to prevent
  // duplicate saves of the same scanned contact.
  Future<ScannedContact?> findExistingContact({
    required int ownerID,
    required String email,
    required String phone,
  }) async {
    final db = await instance.database;
    final hasEmail = email.trim().isNotEmpty;
    final hasPhone = phone.trim().isNotEmpty;
    if (!hasEmail && !hasPhone) return null;

    final whereParts = <String>['ownerID = ?'];
    final whereArgs = <dynamic>[ownerID];
    final orParts = <String>[];
    if (hasEmail) {
      orParts.add('email = ?');
      whereArgs.add(email.trim());
    }
    if (hasPhone) {
      orParts.add('phone = ?');
      whereArgs.add(phone.trim());
    }
    whereParts.add('(${orParts.join(' OR ')})');

    final result = await db.query(
      'scanned_contacts',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ScannedContact.fromMap(result.first);
  }

  Future<ScannedContact> create(ScannedContact contact) async {
    final db = await instance.database;
    final id = await db.insert('scanned_contacts', contact.toMap());
    return contact.copyWith(id: id);
  }

  Future<int> updateNote({required int id, required String note}) async {
    final db = await instance.database;
    return await db.update(
      'scanned_contacts',
      {'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ScannedContact>> getAllContacts(int ownerID) async {
    final db = await instance.database;
    final result = await db.query(
      'scanned_contacts',
      where: 'ownerID = ?',
      whereArgs: [ownerID],
      orderBy: 'scannedAt DESC',
    );

    return result.map((map) => ScannedContact.fromMap(map)).toList();
  }

  Future<List<ScannedContact>> searchContacts(int ownerID, String query) async {
    final db = await instance.database;
    final result = await db.query(
      'scanned_contacts',
      where: 'ownerID = ? AND (firstName LIKE ? OR lastName LIKE ? OR company LIKE ?)',
      whereArgs: [ownerID, '%$query%', '%$query%', '%$query%'],
      orderBy: 'scannedAt DESC',
    );

    return result.map((map) => ScannedContact.fromMap(map)).toList();
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'scanned_contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

extension ScannedContactCopy on ScannedContact {
  ScannedContact copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? company,
    String? role,
    int? ownerID,
    DateTime? scannedAt,
    String? note,
  }) {
    return ScannedContact(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      company: company ?? this.company,
      role: role ?? this.role,
      ownerID: ownerID ?? this.ownerID,
      scannedAt: scannedAt ?? this.scannedAt,
      note: note ?? this.note,
    );
  }
}
