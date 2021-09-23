import 'package:hive/hive.dart';

part 'wordModel.g.dart';

@HiveType(typeId: 1)
class WordModel extends HiveObject {
  @HiveField(0)
  late String word;

  @HiveField(1)
  late String? translation;

  @HiveField(2)
  late String sentence;

  @HiveField(3)
  late DateTime timeAdded;
}
