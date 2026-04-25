enum NamedRoutes {
  login("/login"),
  register("/register");

  final String path;
  const NamedRoutes(this.path);
}