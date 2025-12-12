import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A widget that displays an error page with a message.
///
/// This page is typically shown when there is a routing error (e.g., "404 Not Found").
/// It provides a simple interface to inform the user about the error.
class RouterErrorPage extends StatelessWidget {
  const RouterErrorPage({
    required this.context,
    required this.state,
    super.key,
  });
  final BuildContext context;
  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error.toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
