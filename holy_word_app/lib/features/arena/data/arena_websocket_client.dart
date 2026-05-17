import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:holy_word_app/core/env_config.dart';

/// WebSocket client for real-time Bible Trivia Battles.
/// Authenticates using Firebase ID tokens.
class ArenaWebSocketClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  String? _authToken;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool _disposed = false;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server using a Firebase ID token
  Future<void> connect(String idToken) async {
    _authToken = idToken;
    _reconnectAttempts = 0;
    _disposed = false;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed) return;

    try {
      const wsUrl = EnvConfig.arenaWsUrl;
      debugPrint('WS: Connecting to $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data.toString());
            debugPrint('WS IN: ${msg['event']}');
            _messageController.add(msg);

            if (msg['event'] == 'auth:success') {
              _isConnected = true;
              _reconnectAttempts = 0;
              debugPrint('WS: Authenticated as ${msg['data']['userId']}');
            } else if (msg['event'] == 'auth:error') {
              _isConnected = false;
              debugPrint('WS: Auth failed: ${msg['data']['message']}');
            }
          } catch (e) {
            debugPrint('WS: Failed to parse message: $e');
          }
        },
        onError: (error) {
          debugPrint('WS ERROR: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WS: Connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      // Authenticate with Firebase ID token
      if (_authToken != null) {
        send('auth', {'token': _authToken});
      }
    } catch (e) {
      debugPrint('WS: Connection failed: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// Send a message through WebSocket
  void send(String event, Map<String, dynamic> data) {
    if (_channel == null) {
      debugPrint('WS: Cannot send — not connected');
      return;
    }

    final message = jsonEncode({'event': event, 'data': data});
    debugPrint('WS OUT: $event');
    _channel!.sink.add(message);
  }

  /// Join a battle room
  void joinBattle(String battleId) {
    send('battle:join', {'battleId': battleId});
  }

  /// Send battle answer
  void sendAnswer(String battleId, int questionIndex, int answer, int timeMs) {
    send('battle:answer', {
      'battleId': battleId,
      'questionIndex': questionIndex,
      'answer': answer,
      'timeMs': timeMs,
    });
  }

  /// Signal ready to start battle
  void sendReady(String battleId) {
    send('battle:ready', {'battleId': battleId});
  }

  /// Listen for specific event type
  Stream<Map<String, dynamic>> on(String eventName) {
    return messages
        .where((msg) => msg['event'] == eventName)
        .map((msg) => msg['data'] ?? {});
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WS: Max reconnect attempts reached');
      _messageController.add({
        'event': 'connection:failed',
        'data': {'message': 'Unable to connect to server'},
      });
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (_reconnectAttempts + 1) * 2);
    debugPrint('WS: Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _doConnect();
    });
  }

  /// Disconnect and cleanup
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _authToken = null;
    debugPrint('WS: Disconnected');
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _messageController.close();
  }
}
