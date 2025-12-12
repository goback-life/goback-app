import 'dart:ui';

extension HexToColor on String {
  /// getter to convert a string like [#FF00FF00] to a color wether it has the opacity values in it or not (8 or 6 length string)
  Color? hexToColorOrNull({
    String fillAlpha = 'FF',
    String? overrideAlpha,
  }) {
    final String stripped = replaceFirst('#', '');
    final padded = switch (stripped.length) {
      6 => '${fillAlpha[0]}${fillAlpha[1]}$stripped',
      < 8 => stripped.padLeft(8, 'F'),
      8 => stripped,
      > 8 || _ => stripped.substring(0, 8),
    };

    if (int.tryParse('0x$padded') case final int value) {
      final Color color = Color(value);
      if (overrideAlpha case final String overrideAlpha) {
        if (overrideAlpha.length == 2) {
          if (int.tryParse(overrideAlpha) case final int alphaValue) {
            return color.withAlpha(alphaValue);
          }
        }
      }
      return color;
    }

    return null;
  }
}
