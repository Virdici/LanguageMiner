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

    List<Map<String, Object?>> goodData = new List.empty(growable: true);
    for (var term in data) {
      Map<String, Object?> newDefinition = Map();
      if (term['definition'].toString().contains(';')) {
        List<String> definitions = term['definition'].toString().split('; ');
        print(term['definition'].toString().split('. ').first);
        for (var definition in definitions) {
          newDefinition = {
            'term': term['term'],
            'definition': definition.split('. ').last
          };
          goodData.add(newDefinition);
        }
      } else {
        newDefinition = {
          'term': term['term'],
          'definition': term['definition'].toString().split('. ').last
        };
        goodData.add(newDefinition);
      }
    }
    return goodData;
  }
}
