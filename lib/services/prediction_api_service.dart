import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_config.dart';

class PredictionApiResult {
  const PredictionApiResult({required this.odds, required this.playTime});

  final double odds;
  final String playTime;
}

class PredictionApiService {
  PredictionApiService({HttpClient? client}) : _client = client ?? HttpClient();

  static final RegExp _timePattern = RegExp(r'^\d{2}:\d{2}:\d{2}$');

  final HttpClient _client;

  Future<PredictionApiResult> fetchPrediction() async {
    final responseBody = await _getFromFirstAvailable(
      candidates: AviatorApiConfig.predictionCandidates(),
    );

    final decoded = _decodeObject(responseBody);

    // Debug log the full response
    // ignore: avoid_print
    print(
      'PredictionApiService: response decoded -> success=${decoded['success']}, has_message=${decoded['message'] != null}',
    );

    // If server explicitly says success: false, show the message
    if (decoded['success'] == false && decoded['message'] != null) {
      final msg = decoded['message'].toString();
      // ignore: avoid_print
      print('PredictionApiService: server message -> $msg');
      throw FormatException(msg);
    }

    // If success is not true and we don't have prediction data, it's an error
    if (decoded['success'] != true &&
        decoded['odds'] == null &&
        decoded['data'] == null) {
      throw FormatException(
        decoded['message']?.toString() ?? 'Prediction API returned an error.',
      );
    }

    final data = decoded['data'];
    final payload = data is Map<String, dynamic> ? data : decoded;

    final odds = payload['odds'];
    final playTime = payload['play_time'] ?? payload['next_play_time'];

    if (odds is! num || playTime is! String) {
      throw const FormatException('Prediction API response is incomplete.');
    }

    if (!_timePattern.hasMatch(playTime)) {
      throw const FormatException('Prediction time must be HH:MM:SS.');
    }

    return PredictionApiResult(odds: odds.toDouble(), playTime: playTime);
  }

  Future<String> _getFromFirstAvailable({required List<Uri> candidates}) async {
    // ignore: avoid_print
    print('PredictionApiService: trying ${candidates.length} candidate(s)');

    for (final uri in candidates) {
      HttpClientRequest? request;
      try {
        // ignore: avoid_print
        print('PredictionApiService: GET $uri');

        request = await _client.getUrl(uri).timeout(const Duration(seconds: 8));
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.headers.set(HttpHeaders.connectionHeader, 'close');

        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        final responseBody = await response.transform(utf8.decoder).join();

        // ignore: avoid_print
        print('PredictionApiService: $uri -> ${response.statusCode}');
        // ignore: avoid_print
        print('PredictionApiService: response body -> $responseBody');

        if (response.statusCode == HttpStatus.notFound ||
            response.statusCode == HttpStatus.methodNotAllowed) {
          // ignore: avoid_print
          print(
            'PredictionApiService: endpoint not found, trying next candidate',
          );
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          final decoded = _tryDecodeObject(responseBody);
          // ignore: avoid_print
          print('PredictionApiService: error response decoded -> $decoded');

          // If the server indicates the round is in progress (409), provide
          // a friendly short message for the UI while keeping server detail
          // available in logs.
          if (response.statusCode == HttpStatus.conflict) {
            throw HttpException(
              'Wait for another round befero generating',
              uri: uri,
            );
          }

          final message = decoded?['message']?.toString();
          throw HttpException(
            message?.isNotEmpty == true
                ? message!
                : 'Prediction API returned HTTP ${response.statusCode}.',
            uri: uri,
          );
        }

        // 200 OK - return the response body
        return responseBody;
      } on TimeoutException catch (e) {
        // ignore: avoid_print
        print('PredictionApiService: timeout on $uri -> $e');
        continue;
      } on SocketException catch (e) {
        // ignore: avoid_print
        print('PredictionApiService: socket error on $uri -> $e');
        continue;
      } on HttpException {
        // RE-THROW HttpException immediately - don't try next candidate
        // This preserves error messages like 409 "round in progress"
        rethrow;
      } catch (e) {
        // Only catch non-Http/Socket/Timeout exceptions
        // ignore: avoid_print
        print(
          'PredictionApiService: exception on $uri -> ${e.runtimeType}: $e',
        );
        continue;
      }
    }

    throw HttpException(
      'Unable to reach the prediction API.',
      uri: candidates.isNotEmpty ? candidates.first : null,
    );
  }

  Map<String, dynamic> _decodeObject(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Prediction API returned invalid JSON.');
    }

    return decoded;
  }

  Map<String, dynamic>? _tryDecodeObject(String responseBody) {
    try {
      return _decodeObject(responseBody);
    } catch (_) {
      return null;
    }
  }

  void close() {
    _client.close(force: true);
  }
}
