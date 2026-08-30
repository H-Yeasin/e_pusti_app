enum AppEnvironment {
  dev,
  staging,
  prod,
}

extension AppEnvironmentLabel on AppEnvironment {
  String get label => switch (this) {
    AppEnvironment.dev => 'Development',
    AppEnvironment.staging => 'Staging',
    AppEnvironment.prod => 'Production',
  };
}
