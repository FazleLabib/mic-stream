import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class MicService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<Uint8List> _audioStreamController = StreamController<Uint8List>.broadcast();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;

  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  Future<void> init() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) {
      await init();
    }

    if (!_isRecording) {
      try {
        await _recorder.startRecorder(
          toStream: _audioStreamController.sink,
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: 16000,
        );
        _isRecording = true;
      } catch (e) {
        throw Exception('Failed to start recording: $e');
      }
    }
  }

  Future<void> stopRecording() async {
    if (_isRecorderInitialized && _isRecording) {
      try {
        await _recorder.stopRecorder();
        _isRecording = false;
      } catch (e) {
        throw Exception('Failed to stop recording: $e');
      }
    }
  }

  bool get isRecording => _isRecording;

  Future<void> dispose() async {
    if (_isRecorderInitialized) {
      if (_isRecording) {
        await stopRecording();
      }
      await _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }
    await _audioStreamController.close();
  }
}