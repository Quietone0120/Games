import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'game/har_suld_game.dart';
import 'game/ui/hud.dart';
import 'game/ui/build_menu.dart';
import 'game/ui/structure_menu.dart';
import 'package:tank_game/constants/score_service.dart';

class HarSuldWrapper extends StatefulWidget {
  const HarSuldWrapper({super.key});

  @override
  State<HarSuldWrapper> createState() => _HarSuldWrapperState();
}

class _HarSuldWrapperState extends State<HarSuldWrapper> {
  late final HarSuldGame _game;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _game = HarSuldGame();
    _game.onGameOver = (score, waves, playtime) {
      ScoreService.submitScore(
        gameName: 'har_suld',
        score: score,
        playtimeSeconds: playtime,
      );
    };
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goToMainMenu() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget<HarSuldGame>(
        game: _game,
        overlayBuilderMap: {
          'Loading': (context, g) => const _LoadingScreen(),
          'HUD': (context, g) => HudOverlay(game: g),
          'BuildMenu': (context, g) => BuildMenuOverlay(game: g),
          'StructureMenu': (context, g) => StructureMenuOverlay(game: g),
          'GameOver': (context, g) => GameOverOverlay(
                game: g,
                onMainMenu: _goToMainMenu,
              ),
        },
        initialActiveOverlays: const [],
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ХАР СҮЛД',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFFFFD700)),
            SizedBox(height: 16),
            Text(
              'Ачааллаж байна...',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
