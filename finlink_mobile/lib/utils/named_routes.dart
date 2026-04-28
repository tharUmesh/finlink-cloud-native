enum NamedRoutes {
  login("/login"),
  register("/register"),
  home("/home"),
  profile('/profile'),
  receive('/receive'),
  qrScanner('/qr-scanner'),
  withdraw('/withdraw');

  final String path;
  const NamedRoutes(this.path);
}