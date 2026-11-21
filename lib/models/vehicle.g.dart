// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
      id: (json['id'] as num?)?.toInt(),
      vehicleNumber: json['vehicleNumber'] as String,
      vehicleType: $enumDecode(_$VehicleTypeEnumMap, json['vehicleType']),
      brand: json['brand'] as String,
      model: json['model'] as String,
      manufacturingYear: (json['manufacturingYear'] as num?)?.toInt(),
      color: json['color'] as String?,
      fuelType: $enumDecode(_$FuelTypeEnumMap, json['fuelType']),
      seatingCapacity: (json['seatingCapacity'] as num?)?.toInt(),
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      status: $enumDecodeNullable(_$VehicleStatusEnumMap, json['status']) ??
          VehicleStatus.available,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$VehicleToJson(Vehicle instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['vehicleNumber'] = instance.vehicleNumber;
  val['vehicleType'] = _$VehicleTypeEnumMap[instance.vehicleType]!;
  val['brand'] = instance.brand;
  val['model'] = instance.model;
  writeNotNull('manufacturingYear', instance.manufacturingYear);
  writeNotNull('color', instance.color);
  val['fuelType'] = _$FuelTypeEnumMap[instance.fuelType]!;
  writeNotNull('seatingCapacity', instance.seatingCapacity);
  writeNotNull('driverName', instance.driverName);
  writeNotNull('driverPhone', instance.driverPhone);
  val['status'] = _$VehicleStatusEnumMap[instance.status]!;
  writeNotNull('createdAt', instance.createdAt?.toIso8601String());
  writeNotNull('updatedAt', instance.updatedAt?.toIso8601String());
  return val;
}

const _$VehicleTypeEnumMap = {
  VehicleType.car: 'CAR',
  VehicleType.suv: 'SUV',
  VehicleType.van: 'VAN',
  VehicleType.microbus: 'MICROBUS',
  VehicleType.bus: 'BUS',
  VehicleType.truck: 'TRUCK',
  VehicleType.pickup: 'PICKUP',
  VehicleType.motorcycle: 'MOTORCYCLE',
};

const _$FuelTypeEnumMap = {
  FuelType.petrol: 'PETROL',
  FuelType.diesel: 'DIESEL',
  FuelType.octane: 'OCTANE',
  FuelType.cng: 'CNG',
  FuelType.lpg: 'LPG',
  FuelType.hybrid: 'HYBRID',
  FuelType.electric: 'ELECTRIC',
};

const _$VehicleStatusEnumMap = {
  VehicleStatus.available: 'AVAILABLE',
  VehicleStatus.inUse: 'IN_USE',
  VehicleStatus.maintenance: 'MAINTENANCE',
  VehicleStatus.inactive: 'INACTIVE',
};

T $enumDecode<T extends Enum>(Map<T, String> map, dynamic value) {
  for (final entry in map.entries) {
    if (entry.value == value) return entry.key;
  }
  throw ArgumentError('$value is not one of the supported values: $map');
}

T? $enumDecodeNullable<T extends Enum>(Map<T, String> map, dynamic value) {
  if (value == null) return null;
  return $enumDecode(map, value);
}
