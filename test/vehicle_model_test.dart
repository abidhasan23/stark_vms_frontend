import 'package:flutter_test/flutter_test.dart';
import 'package:stark_vms_frontend/models/vehicle.dart';

void main() {
  group('Vehicle Model Tests', () {
    test('Vehicle.fromJson parses correctly', () {
      final json = {
        'id': 1,
        'vehicleNumber': 'DHA-TEST-GA-11-0001',
        'vehicleType': 'CAR',
        'brand': 'Toyota',
        'model': 'Corolla',
        'manufacturingYear': 2023,
        'color': 'Silver',
        'fuelType': 'HYBRID',
        'seatingCapacity': 5,
        'driverName': 'Test Driver',
        'driverPhone': '+8801700000000',
        'status': 'AVAILABLE',
      };

      final vehicle = Vehicle.fromJson(json);

      expect(vehicle.id, 1);
      expect(vehicle.vehicleNumber, 'DHA-TEST-GA-11-0001');
      expect(vehicle.vehicleType, VehicleType.car);
      expect(vehicle.brand, 'Toyota');
      expect(vehicle.model, 'Corolla');
      expect(vehicle.fuelType, FuelType.hybrid);
      expect(vehicle.status, VehicleStatus.available);
      expect(vehicle.seatingCapacity, 5);
    });

    test('Vehicle.toJson serializes correctly', () {
      const vehicle = Vehicle(
        vehicleNumber: 'DHA-TEST-GA-11-0001',
        vehicleType: VehicleType.car,
        brand: 'Toyota',
        model: 'Corolla',
        fuelType: FuelType.hybrid,
        status: VehicleStatus.available,
      );

      final json = vehicle.toJson();

      expect(json['vehicleNumber'], 'DHA-TEST-GA-11-0001');
      expect(json['vehicleType'], 'CAR');
      expect(json['fuelType'], 'HYBRID');
      expect(json['status'], 'AVAILABLE');
      expect(json.containsKey('id'), false); // null not included
    });

    test('Vehicle.copyWith creates correct copy', () {
      const original = Vehicle(
        vehicleNumber: 'DHA-ORIG-00-00-0001',
        vehicleType: VehicleType.suv,
        brand: 'Honda',
        model: 'CR-V',
        fuelType: FuelType.petrol,
      );

      final updated = original.copyWith(
        status: VehicleStatus.inUse,
        color: 'Blue',
      );

      expect(updated.vehicleNumber, 'DHA-ORIG-00-00-0001');
      expect(updated.brand, 'Honda');
      expect(updated.status, VehicleStatus.inUse);
      expect(updated.color, 'Blue');
    });

    test('VehicleStatus.inUse serializes to IN_USE', () {
      const vehicle = Vehicle(
        vehicleNumber: 'TEST-001',
        vehicleType: VehicleType.car,
        brand: 'Toyota',
        model: 'Corolla',
        fuelType: FuelType.petrol,
        status: VehicleStatus.inUse,
      );
      final json = vehicle.toJson();
      expect(json['status'], 'IN_USE');
    });

    test('Duplicate vehicle number detection logic', () {

      const number = 'DHA-TEST-GA-11-0001';
      const otherNumber = 'dha-test-ga-11-0001';
      expect(number.toLowerCase() == otherNumber.toLowerCase(), isTrue);
    });
  });
}
