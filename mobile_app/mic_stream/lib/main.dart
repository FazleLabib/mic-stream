import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

void main() {
  runApp(const MicStreamApp());
}

class MicStreamApp extends StatelessWidget {
  const MicStreamApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mic Stream',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}