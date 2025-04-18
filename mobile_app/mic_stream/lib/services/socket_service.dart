import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class SocketService {
  Socket? _socket;
  String _serverIp = '';
  int _port = 8080;
  bool _isConnected = false;
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  Stream<String> get statusStream => _statusController.stream;

  Future<void> connectToServer(String ip, [int port = 8080]) async {
    if (_isConnected) {
      await disconnectFromServer();
    }

    _serverIp = ip;
    _port = port;
    
    try {
      _statusController.add('Connecting to $_serverIp:$_port...');
      
      _socket = await Socket.connect(_serverIp, _port, timeout: const Duration(seconds: 5));
      _isConnected = true;
      _statusController.add('Connected to $_serverIp:$_port');

      _socket!.listen(
        (data) {
          _statusController.add('Received data from server');
        },
        onError: (error) {
          _isConnected = false;
          _statusController.add('Connection error: $error');
        },
        onDone: () {
          _isConnected = false;
          _statusController.add('Server disconnected');
        },
      );
    } on SocketException catch (e) {
      _isConnected = false;
      _statusController.add('Failed to connect: ${e.message}');
      throw Exception('Failed to connect: ${e.message}');
    } on TimeoutException {
      _isConnected = false;
      _statusController.add('Connection timeout');
      throw Exception('Connection timeout');
    }
  }

  Future<void> sendAudioData(Uint8List data) async {
    if (!_isConnected || _socket == null) {
      throw Exception('Not connected to server');
    }

    try {
      _socket!.add(data);
      await _socket!.flush();
    } catch (e) {
      _statusController.add('Error sending data: $e');
      throw Exception('Error sending data: $e');
    }
  }

  Future<void> disconnectFromServer() async {
    if (_socket != null) {
      try {
        await _socket!.close();
        _socket = null;
        _isConnected = false;
        _statusController.add('Disconnected from server');
      } catch (e) {
        _statusController.add('Error during disconnection: $e');
        throw Exception('Error during disconnection: $e');
      }
    }
  }

  bool get isConnected => _isConnected;

  String get serverIp => _serverIp;

  int get port => _port;

  void dispose() {
    disconnectFromServer();
    _statusController.close();
  }
}