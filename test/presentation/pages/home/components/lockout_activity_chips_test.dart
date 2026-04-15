import 'package:cloudless/presentation/pages/home/components/lockout_activity_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp({
    String? selected,
    String? customText,
    ValueChanged<String?>? onSelected,
    ValueChanged<String?>? onCustomTextChanged,
  }) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: LockoutActivityChips(
            selectedPreset: selected,
            customText: customText,
            onPresetSelected: onSelected ?? (_) {},
            onCustomTextChanged: onCustomTextChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders all 5 preset chips plus custom', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    await tester.pumpWidget(buildApp());
    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Relax'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.byType(LockoutActivityChips), findsOneWidget);
  });

  testWidgets('tapping a chip calls onPresetSelected', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    String? result;
    await tester.pumpWidget(buildApp(onSelected: (v) => result = v));

    await tester.tap(find.text('Music'));
    expect(result, 'music');
  });

  testWidgets('tapping selected chip deselects it', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    String? result = 'sport';
    await tester.pumpWidget(
      buildApp(selected: 'sport', onSelected: (v) => result = v),
    );

    await tester.tap(find.text('Sport'));
    expect(result, isNull);
  });
}
