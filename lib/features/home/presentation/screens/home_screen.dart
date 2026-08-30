import 'package:flutter/material.dart';

import '../../../../core/config/app_environment.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.environment});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('e-Pushti')),
      body: Center(child: Text('Running ${environment.label}')),
    );
  }
}
