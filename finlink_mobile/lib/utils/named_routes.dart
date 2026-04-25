enum NamedRoutes {
  login("/login"),
  register("/register"),
  home("/home"),
  qrScanner('/qr-scanner'),
  withdraw('/withdraw');

  final String path;
  const NamedRoutes(this.path);
}