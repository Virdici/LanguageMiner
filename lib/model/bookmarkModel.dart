import 'package:hive/hive.dart';

part 'bookmarkModel.g.dart';

@HiveType(typeId: 3)
class BookmarkModel extends HiveObject {
  @HiveField(0)
  late String textTitle;
  @HiveField(1)
  late int sentenceIndex;
}
