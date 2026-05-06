import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:holy_word_app/core/env_config.dart';

/// WebSocket client for real-time Bible Trivia Battles
class ArenaWebSocketClient {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  String? _userId;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect(String userId) async {
    _userId = userId;
    _reconnectAttempts = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
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

            // Handle auth success
            if (msg['event'] == 'auth:success') {
              _isConnected = true;
              _reconnectAttempts = 0;
              debugPrint('WS: Authenticated as ${msg['data']['userId']}');
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

      // Authenticate
      if (_userId != null) {
        send('auth', {'userId': _userId});
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
      debugPrint('WS: Cannot send - not connected');
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
    return messages.where((msg) => msg['event'] == eventName).map((msg) => msg['data'] ?? {});
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WS: Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (_reconnectAttempts + 1) * 2); // Exponential backoff
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
    _userId = null;
    debugPrint('WS: Disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
