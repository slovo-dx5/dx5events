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
      version: 1,
      onCreate: _createDB,
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
      scannedAt $textType
    )
    ''');
  }

  Future<ScannedContact> create(ScannedContact contact) async {
    final db = await instance.database;
    final id = await db.insert('scanned_contacts', contact.toMap());
    return contact.copyWith(id: id);
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
    );
  }
}
