// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LinkItemAdapter extends TypeAdapter<LinkItem> {
  @override
  final int typeId = 0;

  @override
  LinkItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinkItem(
      id: fields[0] as String,
      title: fields[1] as String,
      url: fields[2] as String,
      description: fields[3] as String?,
      faviconUrl: fields[4] as String?,
      category: fields[5] as String?,
      previewImageUrl: fields[10] as String?,
      isArchived: fields[7] as bool?,
      clickCount: fields[8] as int?,
      tags: (fields[9] as List?)?.cast<String>(),
      timestamp: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, LinkItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.faviconUrl)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.isArchived)
      ..writeByte(8)
      ..write(obj.clickCount)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.previewImageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
