// API config — reads backend URL from compile-time environment
// For deployment, change baseUrl to your Render backend URL.
// Example: 'https://stark-vms-backend.onrender.com/api'

class ApiConfig {
  ApiConfig._();

  /// Change this to your Render backend URL after deployment.
  /// Local dev: http://localhost:9001/api
  /// Production: https://<your-render-service>.onrender.com/api
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:9001/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout    = Duration(seconds: 20);

  static const int defaultPageSize = 10;
}
