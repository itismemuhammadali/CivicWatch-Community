class ApiResponse<T> {
  final String? message;
  final int? statusCode;
  final dynamic exception;
  final T? content;
  final bool? success;
  final String? token;
  final String? refreshToken;
  final String? accessToken;
  final String? tokenType;

  const ApiResponse({
    required this.message,
    required this.statusCode,
    required this.exception,
    required this.content,
    required this.success,
    required this.token,
    required this.refreshToken,
    required this.accessToken,
    required this.tokenType,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? json)? contentParser,
  }) {
    return ApiResponse<T>(
      message: json['MESSAGE'] as String?,
      statusCode: json['STATUS_CODE'] as int?,
      exception: json['EXCEPTION'],
      content: contentParser == null ? null : contentParser(json['CONTENT']),
      success: json['SUCCESS'] as bool?,
      token: json['TOKEN'] as String?,
      refreshToken: json['REFRESH_TOKEN'] as String?,
      accessToken: json['access_token'] as String?,
      tokenType: json['token_type'] as String?,
    );
  }
}

