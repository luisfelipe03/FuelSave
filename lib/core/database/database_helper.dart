import 'dart:async';
import 'package:fuelsave/core/models/car_model.dart';
import 'package:fuelsave/core/models/price_record_model.dart';
import 'package:fuelsave/core/models/refuel_record_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _carsTable = 'cars';
  static const String _colCarId = 'id';
  static const String _colCarName = 'name';
  static const String _colCarGasConsumption = 'gasConsumption';
  static const String _colCarEthanolConsumption = 'ethanolConsumption';

  static const String _priceHistoryTable = 'price_history';
  static const String _colPriceId = 'id';
  static const String _colPriceDate = 'date';
  static const String _colPriceGasoline = 'gasolinePrice';
  static const String _colPriceEthanol = 'ethanolPrice';

  static const String _refuelHistoryTable = 'refuel_history';
  static const String _colRefuelId = 'id';
  static const String _colRefuelCarId = 'carId';
  static const String _colRefuelDate = 'date';
  static const String _colRefuelFuelType = 'fuelType';
  static const String _colRefuelAmountPaid = 'amountPaid';
  static const String _colRefuelPricePerLiter = 'pricePerLiter';

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance ??= DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'fuelsave.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE $_carsTable (
        $_colCarId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_colCarName TEXT NOT NULL,
        $_colCarGasConsumption REAL NOT NULL,
        $_colCarEthanolConsumption REAL NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $_priceHistoryTable (
        $_colPriceId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_colPriceDate TEXT NOT NULL,
        $_colPriceGasoline REAL NOT NULL,
        $_colPriceEthanol REAL NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $_refuelHistoryTable (
        $_colRefuelId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_colRefuelCarId INTEGER NOT NULL,
        $_colRefuelDate TEXT NOT NULL,
        $_colRefuelFuelType TEXT NOT NULL CHECK ($_colRefuelFuelType IN ('gasoline', 'ethanol')),
        $_colRefuelAmountPaid REAL NOT NULL,
        $_colRefuelPricePerLiter REAL NOT NULL,
        FOREIGN KEY ($_colRefuelCarId) REFERENCES $_carsTable ($_colCarId) ON DELETE CASCADE
      )
    ''');

    await batch.commit(noResult: true);
    print("Database tables created!");
  }

  Future<int> insertCar(CarModel car) async {
    final db = await database;
    final id = await db.insert(
      _carsTable,
      car.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Car inserted with id: $id');
    return id;
  }

  Future<List<CarModel>> getCars() async {
    final db = await database;
    final maps = await db.query(_carsTable, orderBy: '$_colCarName ASC');
    return maps.isEmpty ? [] : maps.map((e) => CarModel.fromMap(e)).toList();
  }

  Future<CarModel?> getCarById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _carsTable,
      where: '$_colCarId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CarModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateCar(CarModel car) async {
    final db = await database;
    if (car.id == null) return 0;
    return await db.update(
      _carsTable,
      car.toMap(),
      where: '$_colCarId = ?',
      whereArgs: [car.id],
    );
  }

  Future<int> deleteCar(int id) async {
    final db = await database;
    return await db.delete(
      _carsTable,
      where: '$_colCarId = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertPriceRecord(PriceRecordModel record) async {
    final db = await database;
    final id = await db.insert(
      _priceHistoryTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Price record inserted with id: $id');
    return id;
  }

  Future<List<PriceRecordModel>> getPriceHistory({
  int? limit,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final db = await database;
  String? whereClause;
  List<dynamic> whereArgs = [];

  // Monta a cláusula WHERE para o intervalo de datas
  if (startDate != null && endDate != null) {
    // Adiciona um dia ao endDate para incluir todo o dia final
    final endOfDayEndDate = endDate.add(const Duration(days: 1));
    whereClause = '$_colPriceDate >= ? AND $_colPriceDate < ?';
    // Converte para String ISO8601 para comparação no banco
    whereArgs.add(startDate.toIso8601String());
    whereArgs.add(endOfDayEndDate.toIso8601String());
  } else if (startDate != null) {
    whereClause = '$_colPriceDate >= ?';
    whereArgs.add(startDate.toIso8601String());
  } else if (endDate != null) {
     final endOfDayEndDate = endDate.add(const Duration(days: 1));
    whereClause = '$_colPriceDate < ?';
    whereArgs.add(endOfDayEndDate.toIso8601String());
  }

  final List<Map<String, dynamic>> maps = await db.query(
    _priceHistoryTable,
    where: whereClause, // Aplica o filtro de data
    whereArgs: whereArgs.isNotEmpty ? whereArgs : null, // Passa os argumentos
    orderBy: '$_colPriceDate DESC', // Mantém a ordem para a lista
    limit: limit,
  );

  if (maps.isEmpty) {
    return [];
  }

  return List.generate(maps.length, (i) {
    return PriceRecordModel.fromMap(maps[i]);
  });
}

  Future<int> deletePriceRecord(int id) async {
    final db = await database;
    return await db.delete(
      _priceHistoryTable,
      where: '$_colPriceId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllPriceHistory() async {
    final db = await database;
    return await db.delete(_priceHistoryTable);
  }

  Future<int> insertRefuelRecord(RefuelRecordModel record) async {
    final db = await database;
    final id = await db.insert(
      _refuelHistoryTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Refuel record inserted with id: $id');
    return id;
  }

  Future<List<RefuelRecordModel>> getRefuelHistory({
    int? carId,
    int? limit,
  }) async {
    final db = await database;
    final maps = await db.query(
      _refuelHistoryTable,
      where: carId != null ? '$_colRefuelCarId = ?' : null,
      whereArgs: carId != null ? [carId] : null,
      orderBy: '$_colRefuelDate DESC',
      limit: limit,
    );
    return maps.isEmpty
        ? []
        : maps.map((e) => RefuelRecordModel.fromMap(e)).toList();
  }

  Future<int> deleteRefuelRecord(int id) async {
    final db = await database;
    return await db.delete(
      _refuelHistoryTable,
      where: '$_colRefuelId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllRefuelHistory({int? carId}) async {
    final db = await database;
    return await db.delete(
      _refuelHistoryTable,
      where: carId != null ? '$_colRefuelCarId = ?' : null,
      whereArgs: carId != null ? [carId] : null,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print("Database closed.");
  }
}
