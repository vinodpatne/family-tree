class AppConfig {
  static const String googleClientId = String.fromEnvironment(
    'NEXT_PUBLIC_GOOGLE_CLIENT_ID',
    defaultValue: '589984283666-lfqpl9j3tvl9ianh5tnmk67pq6umnnp9.apps.googleusercontent.com',
  );
}
