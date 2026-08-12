enum AppFlavor { dev, prod }

class AppConfig {
  static late AppFlavor flavor;
  static late String baseUrl;

  static void init({required AppFlavor appFlavor}) {
    flavor = appFlavor;
    switch (flavor) {
      case AppFlavor.dev:
        baseUrl = 'http://10.10.255.180:4000';
        break;
      case AppFlavor.prod:
        baseUrl = 'https://api.visorroute.venuefy.top';
        break;
    }
  }
}
