import 'package:hive/hive.dart';
import 'package:language_miner/model/wordModel.dart';

class WordController {
  static void editText(
      WordModel wordModel, String word, String translation, String sentence) {
    wordModel.word = word;
    wordModel.translation = translation;
    wordModel.sentence = sentence;

    wordModel.save();
  }

  static void deleteWord(WordModel wordModel) {
    wordModel.delete();
  }

  static Future addWord(
      String word, String translation, String sentence) async {
    final wordToAdd = WordModel()
      ..word = word
      ..sentence = sentence
      ..translation = translation
      ..timeAdded = DateTime.now();

    final box = Hive.box<WordModel>('words');
    box.add(wordToAdd);
  }

  //TODO dodać sprawdzanie po definicji
  static bool checkIfExists(String term, String sentence) {
    var box = Hive.box<WordModel>('words');
    var terms = box.values.where(
        (element) => element.word == term && element.sentence == sentence);

    if (terms.isEmpty) {
      return false;
    } else {
      return true;
    }
  }
}
