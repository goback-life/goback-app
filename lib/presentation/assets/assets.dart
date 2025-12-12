import 'package:cloudless/presentation/assets/assets.gen.dart' as assets;
import 'package:cloudless/presentation/assets/icons.g.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart' show SvgTheme;
import 'package:flutter/material.dart';

part 'utilities/icon_assets_extension.dart';
part 'utilities/png_assets_extension.dart';
part 'utilities/svg_assets_extension.dart';

class Assets {
  static final png = assets.Assets.images.pngs;
  static final svg = assets.Assets.images.svgs;
  static final icon = IconAssets();
}
