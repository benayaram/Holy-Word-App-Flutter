/// Environment configuration for Bible Arena
/// Loaded from .env file at app startup
class EnvConfig {
  // Arena API Configuration
  static const String arenaApiUrl = String.fromEnvironment(
    'ARENA_API_URL',
    defaultValue: 'https://holy-word-app-flutter.vercel.app/api',
  );

  static const String arenaWsUrl = String.fromEnvironment(
    'ARENA_WS_URL',
    defaultValue: 'wss://holy-word-app-flutter.vercel.app/ws',
  );

  // For production, override via --dart-define:
  // flutter build apk --dart-define=ARENA_API_URL=https://your-app.vercel.app/api
  // flutter build apk --dart-define=ARENA_WS_URL=wss://your-app.vercel.app/ws
}
