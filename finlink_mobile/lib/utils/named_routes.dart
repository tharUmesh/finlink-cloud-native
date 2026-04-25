enum NamedRoutes {
  login("/login"),
  register("/register"),
  home("/home");

  final String path;
  const NamedRoutes(this.path);
}