import 'package:cloudless/presentation/pages/home/components/lockout_bottom_sheet.dart';
import 'package:cloudless/presentation/themes/main_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    required void Function(
      ({Duration? duration, String? actionText, bool nfcScan})?,
    )
    onResult,
  }) {
    return MaterialApp(
      theme: MainTheme().themeData,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await LockoutBottomSheet.show(context);
              onResult(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  testWidgets('sheet shows Go Back button and NFC link', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(buildApp(onResult: (_) {}));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('GO BACK'), findsWidgets); // title
    expect(find.text('Go Back'), findsWidgets); // CTA
    expect(find.text('Scan Tag'), findsOneWidget);
  });

  testWidgets('tapping Scan Tag returns nfcScan true', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    ({Duration? duration, String? actionText, bool nfcScan})? result;
    await tester.pumpWidget(buildApp(onResult: (r) => result = r));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan Tag'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.nfcScan, isTrue);
    expect(result!.duration, isNull);
  });
}
