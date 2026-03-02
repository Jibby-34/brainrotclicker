import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/game_screen.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';
import 'services/notification_service.dart';

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

  // Initialize notifications and schedule reminders with the current count.
  await NotificationService.init();
  await NotificationService.scheduleReminders(gameState.totalClicks);

  final adService = AdService();
  await adService.initialize();

  final iapService = IAPService();
  await iapService.initialize(
    onSuccess: gameState.handleIapPurchase,
    onFailed: () {},
    alreadyPurchased: IAPService.nonConsumableIds
        .where(gameState.isIapUpgradePurchased)
        .toSet(),
  );

  runApp(BrainrotClickerApp(
    gameState: gameState,
    adService: adService,
    iapService: iapService,
  ));
}

class BrainrotClickerApp extends StatelessWidget {
  const BrainrotClickerApp({
    super.key,
    required this.gameState,
    required this.adService,
    required this.iapService,
  });

  final GameState gameState;
  final AdService adService;
  final IAPService iapService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameState),
        ChangeNotifierProvider.value(value: adService),
        ChangeNotifierProvider.value(value: iapService),
      ],
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
