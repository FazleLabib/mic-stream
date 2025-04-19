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

        if (!_isConnected && _isStreaming) {
          _isStreaming = false;
        }
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
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Container(
                  decoration: _buildBackground(),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAppBar(),
                          const SizedBox(height: 36),
                          _buildStreamingButton(),
                          const SizedBox(height: 40),
                          _buildStatusCard(),
                          Expanded(child: _buildServerConnectionCard()),
                          const SizedBox(height: 16),
                          _buildInfoBox(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _buildBackground() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1A2151), Color(0xFF0D1333)],
    ),
  );

  Widget _buildAppBar() => Row(
    children: [
      const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
      const SizedBox(width: 12),
      const Text(
        'Mic Stream',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              _isConnected
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isConnected ? Icons.link : Icons.link_off,
              color: _isConnected ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _buildStreamingButton() => Hero(
    tag: 'streaming_button',
    child: GestureDetector(
      onTap: _toggleStreaming,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  _isStreaming
                      ? Colors.red.withOpacity(0.5)
                      : Colors.green.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                _isStreaming
                    ? [Colors.red.shade700, Colors.red.shade900]
                    : [Colors.green.shade500, Colors.green.shade700],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isStreaming ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 12),
              Text(
                _isStreaming ? 'STOP' : 'START',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _buildStatusCard() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text(
              'STATUS',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                _isStreaming
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _isStreaming
                      ? Colors.green.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          width: double.infinity,
          child: Text(
            _statusMessage,
            style: TextStyle(
              color:
                  _isStreaming ? Colors.green.shade300 : Colors.blue.shade300,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _buildServerConnectionCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.settings_ethernet, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text(
              'SERVER CONNECTION',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          _ipController,
          'Server IP Address',
          '192.168.0.100',
          Icons.computer,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _portController,
          'Port',
          '',
          Icons.settings_input_component,
        ),
      ],
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      enabled: !_isStreaming,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white54),
        labelStyle: TextStyle(color: Colors.blue.shade200),
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
      ),
    );
  }

  Widget _buildInfoBox() => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.amber, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Make sure the PC application is running and listening on the specified IP and port.',
            style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
