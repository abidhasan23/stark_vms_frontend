import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/page_response.dart';
import '../models/vehicle.dart';
import '../network/vehicle_api.dart';


class VehicleApiException implements Exception {
  const VehicleApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, String>? fieldErrors;
  final bool isNetworkError;

  bool get isConflict => statusCode == 409;
  bool get isValidationError => statusCode == 400;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class VehicleRepository {
  const VehicleRepository(this._api);

  final VehicleApi _api;

  Future<PageResponse<Vehicle>> getVehicles({
    int page = 0,
    int size = ApiConfig.defaultPageSize,
  }) async {
    try {
      return await _api.getVehicles(page: page, size: size);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<Vehicle> getVehicleById(int id) async {
    try {
      return await _api.getVehicleById(id);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    try {
      return await _api.createVehicle(vehicle);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<Vehicle> updateVehicle(int id, Vehicle vehicle) async {
    try {
      return await _api.updateVehicle(id, vehicle);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<void> deleteVehicle(int id) async {
    try {
      await _api.deleteVehicle(id);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  VehicleApiException _map(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const VehicleApiException(
          message: 'Request timed out. Please check your backend server.',
          isNetworkError: true,
        );
      case DioExceptionType.connectionError:
        return const VehicleApiException(
          message:
              'Unable to reach the VMS server. Ensure the backend is running at ${ApiConfig.baseUrl}.',
          isNetworkError: true,
        );
      case DioExceptionType.cancel:
        return const VehicleApiException(message: 'Request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const VehicleApiException(
          message: 'A network error occurred.',
          isNetworkError: true,
        );
      case DioExceptionType.badResponse:
        return _mapResponse(error.response);
      case DioExceptionType.transformTimeout:
        return const VehicleApiException(
          message: 'Response parse timeout.',
          isNetworkError: true,
        );
    }
  }

  VehicleApiException _mapResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      try {
        final message = data['message'] as String?;
        final rawErrors = data['errors'];
        Map<String, String>? fieldErrors;
        if (rawErrors is Map) {
          fieldErrors = rawErrors
              .map((k, v) => MapEntry(k.toString(), v.toString()));
        }
        return VehicleApiException(
          message: message ?? 'Server error',
          statusCode: (data['status'] as num?)?.toInt() ?? statusCode,
          fieldErrors: fieldErrors,
        );
      } catch (_) {}
    }

    return switch (statusCode) {
      400 => const VehicleApiException(
          message: 'Invalid data. Check the form fields.',
          statusCode: 400,
        ),
      404 => const VehicleApiException(
          message: 'The vehicle could not be found.',
          statusCode: 404,
        ),
      409 => const VehicleApiException(
          message: 'A vehicle with this number already exists.',
          statusCode: 409,
        ),
      500 => const VehicleApiException(
          message: 'Internal server error. Try again.',
          statusCode: 500,
        ),
      _ => VehicleApiException(
          message: 'Server error (HTTP ${statusCode ?? 'unknown'}).',
          statusCode: statusCode,
        ),
    };
  }
}
