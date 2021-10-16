import 'package:hive/hive.dart';

part 'textModel.g.dart';

@HiveType(typeId: 0)
class TextModel extends HiveObject {
  @HiveField(0)
  late String title;
  @HiveField(1)
  late DateTime timeCreated;
  @HiveField(2)
  late String contents;
}
