import 'package:cloudless/presentation/pages/camera_capture/views/camera_capture_view.dart';
import 'package:flutter/material.dart';

class CameraCapturePage extends StatelessWidget {
  const CameraCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: CameraCaptureView(),
    );
  }
}
