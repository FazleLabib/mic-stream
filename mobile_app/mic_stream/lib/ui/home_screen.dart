import 'package:flutter/material.dart';
import '../services/mic_service.dart';
import '../services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '8080',
  );
  final MicService _micService = MicService();
  final SocketService _socketService = SocketService();

  bool _isStreaming = false;
  String _statusMessage = 'Ready';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initServices();

    _socketService.statusStream.listen((status) {
      setState(() {
        _statusMessage = status;
        _isConnected = _socketService.isConnected;
      });
    });
  }

  Future<void> _initServices() async {
    try {
      await _micService.init();

      _micService.audioStream.listen((audioData) async {
        if (_isStreaming && _socketService.isConnected) {
          try {
            await _socketService.sendAudioData(audioData);
          } catch (e) {
            setState(() {
              _statusMessage = 'Error sending audio: $e';
              _stopStreaming();
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization error: $e';
      });
    }
  }

  Future<void> _toggleStreaming() async {
    if (!_isStreaming) {
      await _startStreaming();
    } else {
      await _stopStreaming();
    }
  }

  Future<void> _startStreaming() async {
    if (!_socketService.isConnected) {
      try {
        final ip = _ipController.text.trim();
        final port = int.tryParse(_portController.text.trim()) ?? 8080;

        if (ip.isEmpty) {
          setState(() {
            _statusMessage = 'Please enter a valid IP address';
          });
          return;
        }

        await _socketService.connectToServer(ip, port);
      } catch (e) {
        setState(() {
          _statusMessage = 'Connection error: $e';
        });
        return;
      }
    }

    try {
      await _micService.startRecording();
      setState(() {
        _isStreaming = true;
        _statusMessage =
            'Streaming audio to ${_socketService.serverIp}:${_socketService.port}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error starting stream: $e';
      });
    }
  }

  Future<void> _stopStreaming() async {
    try {
      await _micService.stopRecording();
      setState(() {
        _isStreaming = false;
        _statusMessage =
            _socketService.isConnected
                ? 'Connected to ${_socketService.serverIp}:${_socketService.port}'
                : 'Ready';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping stream: $e';
        _isStreaming = false;
      });
    }
  }

  @override
  void dispose() {
    _micService.dispose();
    _socketService.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mic Stream'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Server connection section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Server Connection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // IP Address input
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'Server IP Address',
                          border: OutlineInputBorder(),
                          hintText: '192.168.0.100',
                          prefixIcon: Icon(Icons.computer),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isStreaming,
                      ),
                      const SizedBox(height: 12),

                      // Port input
                      TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.settings_ethernet),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isStreaming,
                      ),

                      const SizedBox(height: 16),

                      // Connection indicator
                      Row(
                        children: [
                          Icon(
                            _isConnected ? Icons.link : Icons.link_off,
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: _isConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Streaming controls
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle streaming button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _toggleStreaming,
                          icon: Icon(_isStreaming ? Icons.stop : Icons.mic),
                          label: Text(
                            _isStreaming ? 'Stop Streaming' : 'Start Streaming',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isStreaming ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Status section
              Card(
                elevation: 4,
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status message
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        width: double.infinity,
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _isStreaming ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Info text
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Make sure the PC application is running and listening on the specified IP and port.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
