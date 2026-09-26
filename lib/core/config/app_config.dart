enum AppEnv { development, staging, production }

abstract final class AppConfig {
  static const envName = String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static AppEnv get env {
    switch (envName) {
      case 'production':
        return AppEnv.production;
      case 'staging':
        return AppEnv.staging;
      default:
        return AppEnv.development;
    }
  }

  static bool get isProduction => env == AppEnv.production;
}
