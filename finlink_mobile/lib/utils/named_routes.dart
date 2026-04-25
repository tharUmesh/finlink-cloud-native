enum NamedRoutes {
  login("/login"),
  register("/register"),
  home("/home"),
  receive('/receive'),
  qrScanner('/qr-scanner'),
  withdraw('/withdraw');

  final String path;
  const NamedRoutes(this.path);
}