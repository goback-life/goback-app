enum Flavor { prestage, stage, production }

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.prestage:
        return 'goback .';
      case Flavor.stage:
        return 'goback .';
      case Flavor.production:
        return 'goback .';
    }
  }
}
