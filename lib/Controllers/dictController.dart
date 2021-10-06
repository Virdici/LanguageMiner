import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class DictController {
  static late Database db;

  static Future<List<Map<dynamic, dynamic>>> getTerm(String term) async {
    var dbPath = await getDatabasesPath();
    var path = join(dbPath, "new_dict.db");
    var exists = await databaseExists(path);

    if (!exists) {
      print('creating db copy');

      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets", "dict.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print('opening db');
    }

    db = await openDatabase(path);
    print("is db open: " + db.isOpen.toString());

    var data = await db.rawQuery(
        'select term,definition from definitions where term like "$term"');
    await db.close();

    print("is db open: " + db.isOpen.toString());

    return data;
    // debugPrint(data.toString());
    // debugPrint(firstData);
  }
}
