// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_nudge_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetNudgeLogAdapter extends TypeAdapter<BudgetNudgeLog> {
  @override
  final int typeId = 3;

  @override
  BudgetNudgeLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetNudgeLog(
      id: fields[0] as String,
      budgetId: fields[1] as String,
      categoryId: fields[2] as String,
      categoryName: fields[3] as String,
      alertLevel: fields[4] as int,
      pushSent: fields[5] as bool,
      emailSent: fields[6] as bool,
      utilization: fields[7] as double,
      createdAt: fields[8] as DateTime,
      message: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetNudgeLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.budgetId)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.categoryName)
      ..writeByte(4)
      ..write(obj.alertLevel)
      ..writeByte(5)
      ..write(obj.pushSent)
      ..writeByte(6)
      ..write(obj.emailSent)
      ..writeByte(7)
      ..write(obj.utilization)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.message);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetNudgeLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
