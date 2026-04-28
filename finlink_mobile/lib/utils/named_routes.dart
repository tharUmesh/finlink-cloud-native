enum NamedRoutes {
  login("/login"),
  register("/register"),
  home("/home"),
  profile('/profile'),
  receive('/receive'),
  qrScanner('/qr-scanner'),
  withdraw('/withdraw'),
  deposit('/deposit'),
  loan('/loan');

  final String path;
  const NamedRoutes(this.path);
}