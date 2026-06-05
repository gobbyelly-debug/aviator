import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_config.dart';

typedef AccessKeyValidator =
    Future<AccessKeyValidationResult> Function(String accessKey);

class AccessKeyValidationResult {
  const AccessKeyValidationResult({
    required this.isValid,
    this.message,
    this.expiresAt,
  });

  final bool isValid;
  final String? message;
  final DateTime? expiresAt;
}

class AccessApiService {
  AccessApiService({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  Future<AccessKeyValidationResult> validateAccessKey(String accessKey) async {
    // Debug: log the exact key being validated
    // ignore: avoid_print
    print('AccessApiService: validating key -> $accessKey');

    final body = jsonEncode({'access_key': accessKey});

    final responseBody = await _postToFirstAvailable(
      candidates: AviatorApiConfig.accessKeyValidationCandidates(),
      body: body,
    );

    // Debug: log response body for validation troubleshooting
    try {
      // ignore: avoid_print
      print('AccessApiService: validate response -> $responseBody');
    } catch (_) {}

    final decoded = _decodeObject(responseBody);
    if (decoded['success'] != true) {
      throw FormatException(
        decoded['message']?.toString() ?? 'Access API returned an error.',
      );
    }

    return AccessKeyValidationResult(
      isValid: decoded['valid'] == true,
      message: decoded['message']?.toString(),
      expiresAt: _parseExpiresAt(decoded),
    );
  }

  DateTime? _parseExpiresAt(Map<String, dynamic> decoded) {
    try {
      final data = decoded['data'];
      if (data is Map && data['expires_at'] != null) {
        final s = data['expires_at'].toString();
        final dt = DateTime.tryParse(s);
        return dt;
      }
    } catch (_) {}
    return null;
  }

  Future<String> _postToFirstAvailable({
    required List<Uri> candidates,
    required String body,
  }) async {
    for (final uri in candidates) {
      HttpClientRequest? request;
      try {
        // ignore: avoid_print
        print('AccessApiService: POST $uri');

        final bodyBytes = utf8.encode(body);
        request = await _client
            .postUrl(uri)
            .timeout(const Duration(seconds: 8));
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.connectionHeader, 'close');
        request.contentLength = bodyBytes.length;
        request.add(bodyBytes);

        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        final responseBody = await response.transform(utf8.decoder).join();

        // ignore: avoid_print
        print('AccessApiService: $uri -> ${response.statusCode}');

        if (response.statusCode == HttpStatus.notFound ||
            response.statusCode == HttpStatus.methodNotAllowed) {
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw HttpException(
            'Access API returned HTTP ${response.statusCode}.',
            uri: uri,
          );
        }

        return responseBody;
      } on TimeoutException catch (_) {
        continue;
      } on SocketException catch (_) {
        continue;
      } catch (e) {
        continue;
      }
    }

    throw HttpException(
      'Unable to reach the access API.',
      uri: candidates.isNotEmpty ? candidates.first : null,
    );
  }

  Map<String, dynamic> _decodeObject(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Access API returned invalid JSON.');
    }

    return decoded;
  }

  void close() {
    _client.close(force: true);
  }
}
