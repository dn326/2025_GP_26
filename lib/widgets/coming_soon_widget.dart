import 'package:flutter/material.dart';

class ComingSoonWidget extends StatelessWidget {
  const ComingSoonWidget({super.key});

  static String routeName = 'coming_soon';
  static String routePath = '/comingSoon';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coming Soon')),
      body: const Center(child: Text('Coming Soon')),
    );
  }
}
