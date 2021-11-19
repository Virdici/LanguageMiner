import 'package:hive/hive.dart';
import 'package:language_miner/model/bookmarkModel.dart';

class BookmarkController {
  static void deleteBookmark(BookmarkModel bookmark) {
    bookmark.delete();
  }

  static Future addBookmark(String title, double sentenceIndex) async {
    final bookmark = BookmarkModel()
      ..textTitle = title
      ..sentenceIndex = sentenceIndex;

    final box = Hive.box<BookmarkModel>('bookmarks');
    box.add(bookmark);
  }

  static bool checkIfExists(int sentence) {
    var box = Hive.box<BookmarkModel>('bookmarks');
    var terms =
        box.values.where((element) => element.sentenceIndex == sentence);

    if (terms.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  static void deleteAllBookmarksOfTitle(String title) {
    var box = Hive.box<BookmarkModel>('bookmarks');
    var bookmarks = box.values
        .where((element) => element.textTitle == title)
        .cast<BookmarkModel>()
        .toList();

    for (var bookmark in bookmarks) {
      bookmark.delete();
    }
  }
}
