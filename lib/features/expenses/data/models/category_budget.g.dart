// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryBudgetAdapter extends TypeAdapter<CategoryBudget> {
  @override
  final int typeId = 2;

  @override
  CategoryBudget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryBudget(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      year: fields[2] as int,
      month: fields[3] as int,
      limitMinor: fields[4] as int,
      warningThreshold: fields[5] as double,
      pushNudgesEnabled: fields[6] as bool,
      emailNudgesEnabled: fields[7] as bool,
      lastAlertLevel: fields[8] as int?,
      lastAlertAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryBudget obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.month)
      ..writeByte(4)
      ..write(obj.limitMinor)
      ..writeByte(5)
      ..write(obj.warningThreshold)
      ..writeByte(6)
      ..write(obj.pushNudgesEnabled)
      ..writeByte(7)
      ..write(obj.emailNudgesEnabled)
      ..writeByte(8)
      ..write(obj.lastAlertLevel)
      ..writeByte(9)
      ..write(obj.lastAlertAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
