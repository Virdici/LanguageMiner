// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wordModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordModelAdapter extends TypeAdapter<WordModel> {
  @override
  final int typeId = 1;

  @override
  WordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordModel()
      ..word = fields[0] as String
      ..translation = fields[1] as String
      ..sentence = fields[2] as String
      ..timeAdded = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, WordModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.translation)
      ..writeByte(2)
      ..write(obj.sentence)
      ..writeByte(3)
      ..write(obj.timeAdded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
