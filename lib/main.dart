import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  final gameState = await GameState.load();
  runApp(BrainrotClickerApp(gameState: gameState));
}

class BrainrotClickerApp extends StatelessWidget {
  const BrainrotClickerApp({super.key, required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gameState,
      child: MaterialApp(
        title: 'Brainrot Clicker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFB06EFF),
            secondary: const Color(0xFF4ECDC4),
            surface: const Color(0xFF0D0A2E),
          ),
          scaffoldBackgroundColor: const Color(0xFF1E0B55),
          splashFactory: InkRipple.splashFactory,
          splashColor: const Color(0xFFB06EFF).withValues(alpha: 0.2),
          highlightColor: Colors.transparent,
        ),
        home: const GameScreen(),
      ),
    );
  }
}
