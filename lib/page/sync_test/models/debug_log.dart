enum LogType { request, response, error }

class DebugLog {
  final String id;
  final DateTime timestamp;
  final LogType type;
  final String url;
  final Map<String, dynamic>? requestData;
  final Map<String, String>? headers;
  final int? statusCode;
  final String? responseBody;
  final String? errorMessage;
  final Duration? duration;

  DebugLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.url,
    this.requestData,
    this.headers,
    this.statusCode,
    this.responseBody,
    this.errorMessage,
    this.duration,
  });

  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}.'
      '${timestamp.millisecond.toString().padLeft(3, '0')}';

  String get typeLabel {
    switch (type) {
      case LogType.request:
        return 'REQUEST';
      case LogType.response:
        return 'RESPONSE';
      case LogType.error:
        return 'ERROR';
    }
  }

  String get statusLabel {
    if (statusCode == null) return '';
    if (statusCode! >= 200 && statusCode! < 300) {
      return '$statusCode OK';
    } else if (statusCode! >= 400 && statusCode! < 500) {
      return '$statusCode Client Error';
    } else if (statusCode! >= 500) {
      return '$statusCode Server Error';
    }
    return '$statusCode';
  }
}
