import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'game/har_suld_game.dart';
import 'game/ui/hud.dart';
import 'game/ui/build_menu.dart';
import 'game/ui/structure_menu.dart';
import 'lobby/har_suld_lobby_screen.dart';
import 'lobby/har_suld_sound_service.dart';
import 'lobby/har_suld_game_audio.dart';
import 'package:game_hub/constants/score_service.dart';

enum _Screen { lobby, game }

class HarSuldWrapper extends StatefulWidget {
  const HarSuldWrapper({super.key});

  @override
  State<HarSuldWrapper> createState() => _HarSuldWrapperState();
}

class _HarSuldWrapperState extends State<HarSuldWrapper> {
  _Screen _screen = _Screen.lobby;
  HarSuldGame? _game;

  @override
  void initState() {
    super.initState();
    // Landscape + full screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _restoreOrientation();
    HarSuldGameAudio.dispose();
    super.dispose();
  }

  void _restoreOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // Lobby → Game шилжилт
  Future<void> _onStartGame() async {
    // Supabase-аас бичлэгүүдийг татаж, audio player-т ачаалах
    final Map<String, Uint8List> recordings =
        await HarSuldSoundService.loadAll();
    HarSuldGameAudio.load(recordings);

    // Game объект үүсгэх
    final game = HarSuldGame();
    game.onGameOver = (score, waves, playtime) {
      ScoreService.submitScore(
        gameName: 'har_suld',
        score: score,
        playtimeSeconds: playtime,
      );
    };
    // Тоглогчийн бичсэн дуугаар тоглуулах
    game.onPlayCustomSound = HarSuldGameAudio.play;

    if (!mounted) return;
    setState(() {
      _game = game;
      _screen = _Screen.game;
    });
  }

  void _onBackToLobby() {
    HarSuldGameAudio.dispose();
    setState(() {
      _game = null;
      _screen = _Screen.lobby;
    });
  }

  void _goToMainMenu() {
    HarSuldGameAudio.dispose();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screen == _Screen.lobby
          ? HarSuldLobbyScreen(
              onStartGame: _onStartGame,
              onBack: _goToMainMenu,
            )
          : _buildGame(),
    );
  }

  Widget _buildGame() {
    final game = _game!;
    return GameWidget<HarSuldGame>(
      game: game,
      overlayBuilderMap: {
        'Loading': (context, g) => const _LoadingScreen(),
        'HUD': (context, g) => HudOverlay(game: g),
        'BuildMenu': (context, g) => BuildMenuOverlay(game: g),
        'StructureMenu': (context, g) => StructureMenuOverlay(game: g),
        'PauseMenu': (context, g) => PauseMenuOverlay(
              game: g,
              onMainMenu: _onBackToLobby,
            ),
        'GameOver': (context, g) => GameOverOverlay(
              game: g,
              onMainMenu: _onBackToLobby,
            ),
      },
      initialActiveOverlays: const [],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Loading дэлгэц
// ────────────────────────────────────────────────────────────────

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
