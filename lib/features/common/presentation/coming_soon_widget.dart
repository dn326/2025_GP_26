import 'package:flutter/material.dart';

class ComingSoonWidget extends StatefulWidget {
  const ComingSoonWidget({super.key});

  static const String routeName = 'coming-soon';
  static const String routePath = '/$routeName';

  @override
  State<ComingSoonWidget> createState() => _ComingSoonWidgetState();
}

class _ComingSoonWidgetState extends State<ComingSoonWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coming Soon')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}
