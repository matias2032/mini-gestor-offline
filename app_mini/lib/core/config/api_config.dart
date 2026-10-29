//core/config/api_config.dart
class ApiConfig {
  ApiConfig._();

  // Definido no build: --dart-define=API_BASE_URL=https://licencas.teudominio.com
  // Sem barra final. O valor por omissao serve so para desenvolvimento.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mini-gestor-offline2.onrender.com',
  );

  static const String _v1 = '/api/v1';

  // Unico endpoint que o aplicativo chama (publico, sem token)
  static const String activateLicense = '$_v1/licenses/activate';

  static const Duration timeout = Duration(seconds: 15);

  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}