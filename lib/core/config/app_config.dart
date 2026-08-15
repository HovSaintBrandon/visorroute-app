enum AppFlavor { dev, prod }

class AppConfig {
  static late AppFlavor flavor;
  static late String baseUrl;

  // HERE SDK Navigate Edition credentials — a separate key/secret pair from
  // the backend's HERE_API_KEY (that one authenticates server-to-server REST
  // calls; this pair authenticates the native SDK running on-device). Read at
  // build time via --dart-define so a real secret never has to be committed
  // to this tracked file, e.g.:
  //   flutter run --dart-define=HERE_ACCESS_KEY_ID=... --dart-define=HERE_ACCESS_KEY_SECRET=...
  static const String hereAccessKeyId = String.fromEnvironment('HERE_ACCESS_KEY_ID');
  static const String hereAccessKeySecret = String.fromEnvironment('HERE_ACCESS_KEY_SECRET');
  static bool get hasHereSdkCredentials => hereAccessKeyId.isNotEmpty && hereAccessKeySecret.isNotEmpty;

  static void init({required AppFlavor appFlavor}) {
    flavor = appFlavor;
    switch (flavor) {
      case AppFlavor.dev:
        baseUrl = 'https://api.visorroute.venuefy.top';
        break;
      case AppFlavor.prod:
        baseUrl = 'https://api.visorroute.venuefy.top';
        break;
    }
  }
}
