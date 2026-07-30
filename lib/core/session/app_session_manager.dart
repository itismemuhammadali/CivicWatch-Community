import 'dart:convert';

import 'package:cctv_app/core/components/app_alert.dart';
import 'package:cctv_app/core/network/api_exception.dart';
import 'package:cctv_app/core/realtime/app_websocket_service.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';
import 'package:cctv_app/feature/auth/pages/auth_page.dart';
import 'package:flutter/material.dart';

class AppSessionManager {
  AppSessionManager._();

  static final AppSessionManager instance = AppSessionManager._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isLoggingOut = false;

  String normalizeBearerToken(String accessToken) {
    final trimmedToken = accessToken.trim();
    if (trimmedToken.toLowerCase().startsWith('bearer ')) {
      return trimmedToken.substring(7).trim();
    }
    return trimmedToken;
  }

  bool isJwtExpired(String accessToken) {
    final normalizedToken = normalizeBearerToken(accessToken);
    final parts = normalizedToken.split('.');
    if (parts.length != 3) return false;

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return false;

      final exp = payload['exp'];
      final expirySeconds = switch (exp) {
        int value => value,
        String value => int.tryParse(value),
        _ => null,
      };

      if (expirySeconds == null) return false;

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        expirySeconds * 1000,
        isUtc: true,
      );
      return !DateTime.now().toUtc().isBefore(expiry);
    } catch (_) {
      return false;
    }
  }

  Future<String> requireValidAccessToken(String accessToken) async {
    final normalizedToken = normalizeBearerToken(accessToken);
    if (normalizedToken.isEmpty) {
      throw const ApiException('Session token not found');
    }

    if (isJwtExpired(normalizedToken)) {
      await logout(isSessionExpired: true);
      throw const ApiException(
        'Session expired. Please log in again.',
        statusCode: 401,
      );
    }

    return normalizedToken;
  }

  Future<void> logout({bool isSessionExpired = false}) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      await AppWebSocketService.instance.disconnect();
      await const AuthStorage().clear();

      final navigator = navigatorKey.currentState;
      final context = navigatorKey.currentContext;
      if (navigator != null && context != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );

        if (isSessionExpired) {
          AppAlert.showWarning(
            context,
            'Your session expired. Please log in again.',
          );
        }
      }
    } finally {
      _isLoggingOut = false;
    }
  }
}
