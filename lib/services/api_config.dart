import 'dart:io';

class AviatorApiConfig {
  AviatorApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'AVIATOR_API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static List<Uri> predictionCandidates() {
    return [_buildUri('prediction/'), _buildUri('prediction.php')];
  }

  static List<Uri> accessKeyValidationCandidates() {
    return [
      _buildUri('access-keys/validate/'),
      _buildUri('validate-access-key.php'),
    ];
  }

  static Uri _buildUri(String endpoint) {
    final root = Uri.parse(baseUrl.replaceFirst(RegExp(r'/$'), ''));
    final rootPath = root.path.replaceFirst(RegExp(r'/$'), '');
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';
    final parsedBaseUrl = Uri.parse(baseUrl);
    final baseHasApiPrefix =
        parsedBaseUrl.pathSegments.isNotEmpty &&
        parsedBaseUrl.pathSegments.first == 'api';
    final path = baseHasApiPrefix
        ? '$rootPath$normalizedEndpoint'
        : '$rootPath/api$normalizedEndpoint';

    return root.replace(path: path);
  }
}
