import 'package:hive/hive.dart';
import 'package:language_miner/model/textModel.dart';

class TextController {
  static void editText(TextModel text, String title, String contents) {
    text.title = title;
    text.contents = contents;

    text.save();
  }

  static void deleteText(TextModel text) {
    text.delete();
  }

  static Future addText(String title, String contents) async {
    final text = TextModel()
      ..title = title
      ..contents = contents
      ..timeCreated = DateTime.now();

    final box = Hive.box<TextModel>('texts');
    box.add(text);
  }
}
