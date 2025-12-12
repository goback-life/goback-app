import 'package:flutter/material.dart';

/// A widget that displays an error page with a message and a retry button.
///
/// This page is typically shown when there's a startup error in the application.
/// It provides a simple interface with an error message and a retry mechanism.
class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({
    required this.message,
    required this.onRetry,
    super.key,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
