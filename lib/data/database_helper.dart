import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:coligan_water/models/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database?> get db async {
    if(_db != null)
      return _db;
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "main.db");
    var theDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return theDb;
  }


  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute(
        "CREATE TABLE User(id INTEGER PRIMARY KEY, username TEXT, password TEXT)");
    print("Created tables");
  }

  Future<int> saveUser(User user) async {
    var dbClient = await (db as FutureOr<Database>);
    int res1 = await dbClient.delete("User");
    int res = await dbClient.insert("User", user.toMap());
    return res;
  }

  Future<int> deleteUsers() async {
    var dbClient = await (db as FutureOr<Database>);
    int res = await dbClient.delete("User");
    sharedPrefs.token = "";
    return res;
  }

  Future<bool> isLoggedIn() async {
    var dbClient = await (db as FutureOr<Database>);
    var res = await dbClient.query("User");
    return res.length > 0? true: false;
  }

}
