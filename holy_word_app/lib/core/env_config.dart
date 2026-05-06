/// Environment configuration for Bible Arena
/// Loaded from .env file at app startup
class EnvConfig {
  // Arena API Configuration
  static const String arenaApiUrl = String.fromEnvironment(
    'ARENA_API_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // Android emulator localhost
  );

  static const String arenaWsUrl = String.fromEnvironment(
    'ARENA_WS_URL',
    defaultValue: 'ws://10.0.2.2:3000/ws',
  );

  // For production, override via --dart-define:
  // flutter build apk --dart-define=ARENA_API_URL=https://your-app.vercel.app/api
  // flutter build apk --dart-define=ARENA_WS_URL=wss://your-app.vercel.app/ws
}
