import 'package:flutter/material.dart';

/// A widget that represents a loading page during application startup.
///
/// It's typically used as a placeholder screen while the application is initializing
/// or loading necessary resources.
class StartupLoadingPage extends StatelessWidget {
  const StartupLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
