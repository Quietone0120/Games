import 'dart:async';
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/audio_service.dart';

// --- Дүрсийн төрлүүд ---
enum Tetromino { I, J, L, O, S, T, Z }

class Piece {
  final Tetromino type;
  List<List<int>> shape;
  final Color color;

  Piece({required this.type})
    : shape = _getInitialShape(type),
      color = _getColor(type);

  static List<List<int>> _getInitialShape(Tetromino type) {
    switch (type) {
      case Tetromino.I:
        return [
          [1, 1, 1, 1],
        ];
      case Tetromino.J:
        return [
          [1, 0, 0],
          [1, 1, 1],
        ];
      case Tetromino.L:
        return [
          [0, 0, 1],
          [1, 1, 1],
        ];
      case Tetromino.O:
        return [
          [1, 1],
          [1, 1],
        ];
      case Tetromino.S:
        return [
          [0, 1, 1],
          [1, 1, 0],
        ];
      case Tetromino.T:
        return [
          [0, 1, 0],
          [1, 1, 1],
        ];
      case Tetromino.Z:
        return [
          [1, 1, 0],
          [0, 1, 1],
        ];
    }
  }

  static Color _getColor(Tetromino type) {
    switch (type) {
      case Tetromino.I:
        return const Color(0xFF00FFFF); // Cyan
      case Tetromino.J:
        return const Color(0xFF007BFF); // Blue
      case Tetromino.L:
        return const Color(0xFFFFA500); // Orange
      case Tetromino.O:
        return const Color(0xFFFFFF00); // Yellow
      case Tetromino.S:
        return const Color(0xFF00FF00); // Green
      case Tetromino.T:
        return const Color(0xFFBD00FF); // Purple
      case Tetromino.Z:
        return const Color(0xFFFF0033); // Red
    }
  }

  void rotate() {
    List<List<int>> newShape = List.generate(
      shape[0].length,
      (j) => List.generate(shape.length, (i) => shape[shape.length - 1 - i][j]),
    );
    shape = newShape;
  }
}

// --- Үндсэн Тоглоомын Класс ---
class TetrisGame extends FlameGame with KeyboardEvents {
  static const int rows = 20;
  static const int cols = 10;
  static const double blockSize = 30.0;

  final Function(int) onGameOver;

  late List<List<Color?>> board;
  Piece? currentPiece;
  int currentX = 0;
  int currentY = 0;

  int score = 0;
  bool isGameOver = false;
  double tickTime = 0.5; // Унах хурд
  double lastTick = 0;

  TetrisGame({required this.onGameOver});

  @override
  Future<void> onLoad() async {
    resetGame();
  }

  void resetGame() {
    board = List.generate(rows, (_) => List.generate(cols, (_) => null));
    score = 0;
    isGameOver = false;
    tickTime = 0.5;
    spawnPiece();
  }

  void spawnPiece() {
    currentPiece = Piece(
      type: Tetromino.values[Random().nextInt(Tetromino.values.length)],
    );
    currentX = (cols / 2).floor() - (currentPiece!.shape[0].length / 2).floor();
    currentY = 0;

    // Хэрэв шууд мөргөлдөж байвал тоглоом дуусна
    if (checkCollision(currentX, currentY, currentPiece!.shape)) {
      isGameOver = true;
      onGameOver(score);
    }
  }

  // Мөргөлдөөн шалгах
  bool checkCollision(int x, int y, List<List<int>> shape) {
    for (int r = 0; r < shape.length; r++) {
      for (int c = 0; c < shape[r].length; c++) {
        if (shape[r][c] != 0) {
          int newX = x + c;
          int newY = y + r;

          if (newX < 0 || newX >= cols || newY >= rows) return true;
          if (newY >= 0 && board[newY][newX] != null) return true;
        }
      }
    }
    return false;
  }

  // Дүрсийг байранд нь түгжих
  void lockPiece() {
    for (int r = 0; r < currentPiece!.shape.length; r++) {
      for (int c = 0; c < currentPiece!.shape[r].length; c++) {
        if (currentPiece!.shape[r][c] != 0) {
          int boardY = currentY + r;
          if (boardY >= 0) {
            board[boardY][currentX + c] = currentPiece!.color;
          }
        }
      }
    }
    clearLines();
    spawnPiece();
  }

  // Дүүрсэн мөрүүдийг устгах
  void clearLines() {
    int linesCleared = 0;
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r].every((cell) => cell != null)) {
        board.removeAt(r);
        board.insert(0, List.generate(cols, (_) => null));
        linesCleared++;
        r++;
      }
    }
    if (linesCleared > 0) {
      score += (linesCleared * 100 * linesCleared);
      if (tickTime > 0.1) tickTime -= 0.01;
      AudioService.playSfx(AudioService.sfxClear); // 🔊 мөр устгах дуу
    }
  }

  @override
  void update(double dt) {
    if (isGameOver) return;

    lastTick += dt;
    if (lastTick > tickTime) {
      if (!checkCollision(currentX, currentY + 1, currentPiece!.shape)) {
        currentY++;
      } else {
        lockPiece();
      }
      lastTick = 0;
    }
    void spawnPiece() {
      currentPiece = Piece(
        type: Tetromino.values[Random().nextInt(Tetromino.values.length)],
      );
      currentX =
          (cols / 2).floor() - (currentPiece!.shape[0].length / 2).floor();
      currentY = 0;

      if (checkCollision(currentX, currentY, currentPiece!.shape)) {
        isGameOver = true;
        // UI-д хожигдсон тухай мэдэгдэх
        onGameOver(score);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF0D1117),
    );

    final double startX = (size.x - cols * blockSize) / 2;
    final double startY = 80;

    // Тоглоомын талбайн хүрээ (Neon Glow)
    final framePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(
        startX - 2,
        startY - 2,
        cols * blockSize + 4,
        rows * blockSize + 4,
      ),
      framePaint,
    );

    // Grid (Зөөлөн тор)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke;
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(
        Offset(startX, startY + r * blockSize),
        Offset(startX + cols * blockSize, startY + r * blockSize),
        gridPaint,
      );
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(
        Offset(startX + c * blockSize, startY),
        Offset(startX + c * blockSize, startY + rows * blockSize),
        gridPaint,
      );
    }

    // Түгжигдсэн блокуудыг зурах
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] != null) {
          drawBlock(
            canvas,
            startX + c * blockSize,
            startY + r * blockSize,
            board[r][c]!,
          );
        }
      }
    }

    // Ghost Piece (Сүүдэр) зурах
    if (currentPiece != null && !isGameOver) {
      int ghostY = currentY;
      while (!checkCollision(currentX, ghostY + 1, currentPiece!.shape)) {
        ghostY++;
      }
      drawPiece(
        canvas,
        startX + currentX * blockSize,
        startY + ghostY * blockSize,
        currentPiece!,
        isGhost: true,
      );

      // Одоогийн унаж буй дүрс
      drawPiece(
        canvas,
        startX + currentX * blockSize,
        startY + currentY * blockSize,
        currentPiece!,
      );
    }

    // Оноо харуулах
    final textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
    textPaint.render(canvas, "SCORE: $score", Vector2(size.x / 2 - 60, 30));
  }

  void drawPiece(
    Canvas canvas,
    double x,
    double y,
    Piece piece, {
    bool isGhost = false,
  }) {
    for (int r = 0; r < piece.shape.length; r++) {
      for (int c = 0; c < piece.shape[r].length; c++) {
        if (piece.shape[r][c] != 0) {
          drawBlock(
            canvas,
            x + c * blockSize,
            y + r * blockSize,
            isGhost ? piece.color.withOpacity(0.15) : piece.color,
          );
        }
      }
    }
  }

  void drawBlock(Canvas canvas, double x, double y, Color color) {
    final paint = Paint()..color = color;
    final rect = Rect.fromLTWH(x + 1, y + 1, blockSize - 2, blockSize - 2);

    // Үндсэн блок
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );

    // Neon гэрэлтэлт (Дотор талын цагаан зураас)
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(2)),
      innerPaint,
    );

    // Гялалзсан эффект (Дээд буланд)
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(Offset(x + 8, y + 8), 3, highlightPaint);
  }

  void moveLeft() {
    if (isGameOver || currentPiece == null) return;
    if (!checkCollision(currentX - 1, currentY, currentPiece!.shape)) {
      currentX--;
      AudioService.playSfx(AudioService.sfxMove);
    }
  }

  void moveRight() {
    if (isGameOver || currentPiece == null) return;
    if (!checkCollision(currentX + 1, currentY, currentPiece!.shape)) {
      currentX++;
      AudioService.playSfx(AudioService.sfxMove);
    }
  }

  void softDrop() {
    if (isGameOver || currentPiece == null) return;
    if (!checkCollision(currentX, currentY + 1, currentPiece!.shape)) {
      currentY++;
    }
  }

  void rotatePiece() {
    if (isGameOver || currentPiece == null) return;
    final oldShape = List<List<int>>.from(
      currentPiece!.shape.map((e) => List<int>.from(e)),
    );
    currentPiece!.rotate();
    if (checkCollision(currentX, currentY, currentPiece!.shape)) {
      currentPiece!.shape = oldShape;
    } else {
      AudioService.playSfx(AudioService.sfxRotate);
    }
  }

  void hardDrop() {
    if (isGameOver || currentPiece == null) return;
    while (!checkCollision(currentX, currentY + 1, currentPiece!.shape)) {
      currentY++;
    }
    lockPiece();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (isGameOver) return KeyEventResult.handled;

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (!checkCollision(currentX - 1, currentY, currentPiece!.shape)) {
          currentX--;
          AudioService.playSfx(AudioService.sfxMove); // 🔊 зүүн
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (!checkCollision(currentX + 1, currentY, currentPiece!.shape)) {
          currentX++;
          AudioService.playSfx(AudioService.sfxMove); // 🔊 баруун
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (!checkCollision(currentX, currentY + 1, currentPiece!.shape))
          currentY++;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyR) {
        var oldShape = List<List<int>>.from(
          currentPiece!.shape.map((e) => List<int>.from(e)),
        );
        currentPiece!.rotate();
        if (checkCollision(currentX, currentY, currentPiece!.shape)) {
          currentPiece!.shape = oldShape;
        } else {
          AudioService.playSfx(AudioService.sfxRotate); // 🔊 эргэх
        }
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        while (!checkCollision(currentX, currentY + 1, currentPiece!.shape)) {
          currentY++;
        }
        lockPiece();
      }
    }
    return KeyEventResult.handled;
  }
}
