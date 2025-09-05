import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketEchoService {
  WebsocketEchoService(this.uri);
  final Uri uri;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _incoming = StreamController<String>.broadcast();
  Stream<String> get stream => _incoming.stream;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    await disconnect(); // ensure clean state
    try {
      final ch = WebSocketChannel.connect(uri);
      _channel = ch;
      _subscription = ch.stream.listen(
        (data) {
          try {
            if (!_incoming.isClosed) {
              _incoming.add(data.toString());
            }
          } catch (_) {}
        },
        onError: (_) {},
        onDone: () {},
        cancelOnError: true,
      );
    } catch (_) {
      await disconnect();
    }
  }

  void send(String text) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(text);
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }
}
