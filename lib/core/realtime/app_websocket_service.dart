import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cctv_app/core/network/api_config.dart';
import 'package:cctv_app/core/realtime/app_websocket_event.dart';
import 'package:cctv_app/core/session/app_session_manager.dart';
import 'package:cctv_app/core/storage/auth_storage.dart';

class AppWebSocketService {
  AppWebSocketService._();

  static final AppWebSocketService instance = AppWebSocketService._();
  static const String _room = 'GLOBAL';
  static const Duration _reconnectDelay = Duration(seconds: 5);

  final StreamController<AppWebSocketEvent> _eventController =
      StreamController<AppWebSocketEvent>.broadcast();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  Future<void>? _connectOperation;
  String? _token;
  bool _disconnectRequested = false;

  Stream<AppWebSocketEvent> get events => _eventController.stream;

  Stream<AppWebSocketEvent> eventsFor(
    Set<AppWebSocketEventType> eventTypes,
  ) {
    return events.where((event) => eventTypes.contains(event.type));
  }

  Future<void> connect({String? accessToken}) async {
    // WebSocket disabled in mock mode
    if (ApiConfig.MOCK_MODE) {
      return;
    }

    final resolvedToken = await _resolveToken(accessToken);
    if (resolvedToken == null || resolvedToken.isEmpty) {
      return;
    }

    if (_socket != null && _token == resolvedToken) {
      return;
    }

    if (_connectOperation != null) {
      return _connectOperation!;
    }

    _disconnectRequested = false;
    _connectOperation = _connectInternal(resolvedToken);
    try {
      await _connectOperation;
    } finally {
      _connectOperation = null;
    }
  }

  Future<void> disconnect() async {
    _disconnectRequested = true;
    _token = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _closeSocket();
  }

  Future<void> _connectInternal(String accessToken) async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _token = accessToken;

    await _closeSocket();

    try {
      final socket = await WebSocket.connect(_buildUrl(accessToken));
      _socket = socket;
      _socketSubscription = socket.listen(
        _handleMessage,
        onError: (_, __) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  Future<String?> _resolveToken(String? accessToken) async {
    final token = accessToken ?? await const AuthStorage().readAccessToken();
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return AppSessionManager.instance.normalizeBearerToken(token);
  }

  String _buildUrl(String accessToken) {
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    return baseUri
        .replace(
          scheme: scheme,
          path: '/application_global/subscribeAppWebSocket',
          queryParameters: {
            'room': _room,
            'token': accessToken,
          },
        )
        .toString();
  }

  void _handleMessage(dynamic rawMessage) {
    if (rawMessage is! String || rawMessage.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      _eventController.add(AppWebSocketEvent.fromJson(decoded));
    } catch (_) {
      // Ignore malformed payloads from the socket.
    }
  }

  void _handleDisconnect() {
    _closeSocket();
    if (_disconnectRequested) {
      return;
    }

    if (_reconnectTimer != null || _token == null) {
      return;
    }

    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectTimer = null;
      connect(accessToken: _token);
    });
  }

  Future<void> _closeSocket() async {
    final subscription = _socketSubscription;
    final socket = _socket;
    _socketSubscription = null;
    _socket = null;

    await subscription?.cancel();
    await socket?.close();
  }
}
