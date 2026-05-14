import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'har_suld_sound_service.dart';
import 'sound_recorder.dart';
import 'lobby_audio_player.dart';

enum _EditAction { rerecord, delete, cancel }

/// Тоглогч Хар Сүлд руу нэвтрэхэд харуулдаг lobby дэлгэц.
/// Тоглогчийн бичсэн дуунуудыг удирдаж, тоглоом эхлэх боломжийг олгоно.
class HarSuldLobbyScreen extends StatefulWidget {
  final VoidCallback onStartGame;
  final VoidCallback onBack;

  const HarSuldLobbyScreen({
    super.key,
    required this.onStartGame,
    required this.onBack,
  });

  @override
  State<HarSuldLobbyScreen> createState() => _HarSuldLobbyScreenState();
}

class _HarSuldLobbyScreenState extends State<HarSuldLobbyScreen> {
  // ── Төлөв ──────────────────────────────────────────────────────
  bool _loadingRecordings = true;
  final Set<String> _recordedKeys = {};

  // Бичиж буй дуугийн key (нэг дор нэг дуу бичнэ)
  String? _recordingKey;
  double  _recordingProgress = 0; // 0.0 → 1.0
  Timer?  _progressTimer;
  final   _recorder = SoundRecorder();

  // Preview тоглуулж буй key
  String? _previewKey;
  // Platform-specific audio player (web: AudioElement, mobile: audioplayers)
  final _audioPlayer = LobbyAudioPlayer();
  // Татаж авсан байт-уудыг cache хийнэ — дахин download хийхгүй
  final Map<String, Uint8List> _previewCache = {};

  @override
  void initState() {
    super.initState();
    _loadRecordedKeys();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _previewCache.clear();
    super.dispose();
  }

  // ── Supabase ачаалалт ──────────────────────────────────────────

  Future<void> _loadRecordedKeys() async {
    setState(() => _loadingRecordings = true);
    final keys = await HarSuldSoundService.recordedKeys();
    if (!mounted) return;
    setState(() {
      _recordedKeys
        ..clear()
        ..addAll(keys);
      _loadingRecordings = false;
    });
  }

  // ── Бичлэг ────────────────────────────────────────────────────

  /// Mic товч дарахад: бичигдсэн дуу байвал edit dialog харуулна,
  /// байхгүй бол шууд бичнэ.
  Future<void> _handleRecordTap(String key) async {
    if (_recorder.isRecording) return;
    if (_recordedKeys.contains(key)) {
      final choice = await _showEditDialog(key);
      if (!mounted) return;
      if (choice == _EditAction.rerecord) {
        await _startRecording(key);
      } else if (choice == _EditAction.delete) {
        await _delete(key);
      }
    } else {
      await _startRecording(key);
    }
  }

  /// Бичигдсэн дуунд "Дахин бичих / Устгах / Цуцлах" dialog
  Future<_EditAction> _showEditDialog(String key) async {
    return await showDialog<_EditAction>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A2A0E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: [
                const Icon(Icons.mic, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 8),
                Text(
                  HarSuldSoundKeys.label(key),
                  style: const TextStyle(
                      color: Color(0xFFFFD700), fontSize: 16),
                ),
              ],
            ),
            content: const Text(
              'Энэ дуутай юу хийх вэ?',
              style: TextStyle(color: Colors.white70),
            ),
            actionsPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              // Шинэ дуу оруулах
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD700),
                    backgroundColor:
                        const Color(0xFFFFD700).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.fiber_manual_record, size: 18),
                  label: const Text('Шинэ дуу оруулах',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () =>
                      Navigator.pop(ctx, _EditAction.rerecord),
                ),
              ),
              const SizedBox(height: 6),
              // Өмнөх дуу устгах
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    backgroundColor:
                        Colors.red.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Өмнөх дуу устгах',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () =>
                      Navigator.pop(ctx, _EditAction.delete),
                ),
              ),
              const SizedBox(height: 2),
              // Цуцлах
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _EditAction.cancel),
                  child: const Text('Цуцлах',
                      style: TextStyle(color: Colors.white38)),
                ),
              ),
            ],
          ),
        ) ??
        _EditAction.cancel;
  }

  Future<void> _startRecording(String key) async {
    if (_recorder.isRecording) return;

    final maxSec = HarSuldSoundKeys.maxDuration(key);
    setState(() {
      _recordingKey     = key;
      _recordingProgress = 0;
    });

    // Хэрэглэгчид хэдэн хувь болсныг харуулах жижиг таймер
    final intervalMs = 50;
    final totalMs    = (maxSec * 1000).toInt();
    var elapsed      = 0;
    _progressTimer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      elapsed += intervalMs;
      if (!mounted) { t.cancel(); return; }
      setState(() => _recordingProgress = (elapsed / totalMs).clamp(0.0, 1.0));
    });

    // Бичих (auto-stop = maxSec секунд)
    final bytes = await _recorder.record(maxSec);

    _progressTimer?.cancel();
    _progressTimer = null;

    if (!mounted) return;
    setState(() {
      _recordingKey      = null;
      _recordingProgress = 0;
    });

    if (bytes == null || bytes.isEmpty) {
      _showSnack('Бичлэг амжилтгүй. Микрофоны зөвшөөрөл олгоно уу (Settings → App → Permissions).');
      return;
    }

    // Supabase-д хадгалах
    try {
      await HarSuldSoundService.save(key, bytes);
      _previewCache.remove(key); // хуучин cache-г арилгах — шинэ байт дараа татна
      if (!mounted) return;
      setState(() => _recordedKeys.add(key));
      _showSnack('${HarSuldSoundKeys.label(key)} — амжилттай хадгаллаа ✓');
    } catch (e) {
      _showSnack('Хадгалахад алдаа гарлаа: $e');
    }
  }

  void _stopRecordingManually() {
    _progressTimer?.cancel();
    _recorder.stop();
  }

  // ── Preview ────────────────────────────────────────────────────

  Future<void> _preview(String key) async {
    // Toggle: аль хэдийн тоглуулж байвал зогсооно
    if (_previewKey == key) {
      _audioPlayer.stop();
      if (mounted) setState(() => _previewKey = null);
      return;
    }

    _audioPlayer.stop();

    // Cache шалгах, байхгүй бол Supabase-аас татна
    var bytes = _previewCache[key];
    if (bytes == null) {
      final downloaded = await HarSuldSoundService.download(key);
      if (downloaded == null) {
        _showSnack('Дуугийн бичлэг татахад алдаа гарлаа');
        return;
      }
      bytes = downloaded;
      _previewCache[key] = bytes;
    }

    if (!mounted) return;
    setState(() => _previewKey = key);

    await _audioPlayer.play(
      bytes,
      onEnded: () {
        if (mounted) setState(() => _previewKey = null);
      },
      onError: () {
        if (mounted) setState(() => _previewKey = null);
        _showSnack('Дуу тоглуулахад алдаа гарлаа');
      },
    );
  }

  // ── Устгах ────────────────────────────────────────────────────

  Future<void> _delete(String key) async {
    final confirmed = await _confirm(
      'Устгах',
      '${HarSuldSoundKeys.label(key)}-г устгах уу?',
    );
    if (!confirmed) return;
    // Preview тоглуулж байвал зогсооно
    if (_previewKey == key) {
      _audioPlayer.stop();
      if (mounted) setState(() => _previewKey = null);
    }
    await HarSuldSoundService.delete(key);
    _previewCache.remove(key);
    if (!mounted) return;
    setState(() => _recordedKeys.remove(key));
  }

  // ── Тусламжийн методууд ────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1A2A0E),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A2A0E),
            title: Text(title, style: const TextStyle(color: Colors.amber)),
            content: Text(body,
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Үгүй',
                    style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Тийм',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }


  // ── UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user       = Supabase.instance.client.auth.currentUser;
    final screenSize = MediaQuery.of(context).size;
    final isCompact  = screenSize.height < 480;

    return Scaffold(
      backgroundColor: const Color(0xFF141E0A),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              username: user?.email?.split('@').first ?? 'Тоглогч',
              onBack: widget.onBack,
              isCompact: isCompact,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 700;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GameInfoPanel(isCompact: isCompact),
                        const VerticalDivider(
                            color: Color(0xFF2A4A1A), width: 1),
                        Expanded(
                          child: _SoundPanel(
                            loadingRecordings: _loadingRecordings,
                            recordedKeys: _recordedKeys,
                            recordingKey: _recordingKey,
                            recordingProgress: _recordingProgress,
                            previewKey: _previewKey,
                            isCompact: isCompact,
                            onRecord: _handleRecordTap,
                            onStopRecord: _stopRecordingManually,
                            onPreview: _preview,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return _SoundPanel(
                      loadingRecordings: _loadingRecordings,
                      recordedKeys: _recordedKeys,
                      recordingKey: _recordingKey,
                      recordingProgress: _recordingProgress,
                      previewKey: _previewKey,
                      isCompact: isCompact,
                      onRecord: _handleRecordTap,
                      onStopRecord: _stopRecordingManually,
                      onPreview: _preview,
                    );
                  }
                },
              ),
            ),
            _StartButton(
              isCompact: isCompact,
              onStart: widget.onStartGame,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Top bar
// ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String username;
  final VoidCallback onBack;
  final bool isCompact;
  const _TopBar(
      {required this.username, required this.onBack, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 16, vertical: isCompact ? 8 : 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2A0E),
        border: Border(
            bottom: BorderSide(color: Color(0xFF2A4A1A), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 18),
            onPressed: onBack,
            tooltip: 'Буцах',
          ),
          const SizedBox(width: 8),
          Text(
            'ХАР СҮЛД',
            style: TextStyle(
              color: const Color(0xFFFFD700),
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Icon(Icons.person_outline,
              color: Colors.white54, size: isCompact ? 16 : 18),
          const SizedBox(width: 6),
          Text(username,
              style: TextStyle(
                  color: Colors.white54, fontSize: isCompact ? 11 : 13)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Тоглоомын тухай мэдээлэл (зүүн хэсэг — wide layout)
// ────────────────────────────────────────────────────────────────

class _GameInfoPanel extends StatelessWidget {
  final bool isCompact;
  const _GameInfoPanel({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.castle, color: Color(0xFFFFD700), size: 40),
            const SizedBox(height: 12),
            Text('Тоглоом',
                style: TextStyle(
                    color: Colors.amber[200],
                    fontSize: isCompact ? 11 : 13,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(
              'Монгол баатрын цайзыг хамгаал',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _InfoRow(Icons.waves, 'Давалгаагаар дайчид ирнэ'),
            _InfoRow(Icons.build, 'Хана, цамхаг барь'),
            _InfoRow(Icons.forest, 'Нөөц цуглуул'),
            _InfoRow(Icons.pets, 'Чоно, морьтон дайсад'),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF2A4A1A)),
            const SizedBox(height: 12),
            Text('Хяналт',
                style: TextStyle(
                    color: Colors.amber[200],
                    fontSize: isCompact ? 10 : 12,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            _InfoRow(Icons.keyboard, 'WASD / Arrow — хөдлөх'),
            _InfoRow(Icons.mouse, 'Хулгана — харвах'),
            _InfoRow(Icons.keyboard_alt, 'B — байгуулалт'),
            _InfoRow(Icons.keyboard_alt, 'ESC — цэс'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Дуу бичлэгийн хэсэг
// ────────────────────────────────────────────────────────────────

class _SoundPanel extends StatelessWidget {
  final bool loadingRecordings;
  final Set<String> recordedKeys;
  final String? recordingKey;
  final double recordingProgress;
  final String? previewKey;
  final bool isCompact;

  final void Function(String key) onRecord;
  final void Function() onStopRecord;
  final void Function(String key) onPreview;

  const _SoundPanel({
    required this.loadingRecordings,
    required this.recordedKeys,
    required this.recordingKey,
    required this.recordingProgress,
    required this.previewKey,
    required this.isCompact,
    required this.onRecord,
    required this.onStopRecord,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              20, isCompact ? 12 : 16, 20, isCompact ? 8 : 12),
          child: Row(
            children: [
              const Icon(Icons.mic, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Text(
                'Тоглоомын дуу',
                style: TextStyle(
                  color: const Color(0xFFFFD700),
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '— өөрийн хоолойгоор тоглоомыг дүүргэ',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: isCompact ? 10 : 12),
              ),
            ],
          ),
        ),
        if (loadingRecordings)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              itemCount: HarSuldSoundKeys.all.length,
              itemBuilder: (context, i) {
                final key = HarSuldSoundKeys.all[i];
                final isRecorded  = recordedKeys.contains(key);
                final isRecording = recordingKey == key;
                final isPreviewing = previewKey == key;
                final maxSec = HarSuldSoundKeys.maxDuration(key);

                return _SoundRow(
                  soundKey: key,
                  label: HarSuldSoundKeys.label(key),
                  maxDuration: maxSec,
                  isRecorded: isRecorded,
                  isRecording: isRecording,
                  recordingProgress: isRecording ? recordingProgress : 0,
                  isPreviewing: isPreviewing,
                  anyRecording: recordingKey != null,
                  isCompact: isCompact,
                  onRecord: () => isRecording ? onStopRecord() : onRecord(key),
                  onPreview: () => onPreview(key),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Нэг дуугийн мөр
// ────────────────────────────────────────────────────────────────

class _SoundRow extends StatelessWidget {
  final String soundKey;
  final String label;
  final double maxDuration;
  final bool isRecorded;
  final bool isRecording;
  final double recordingProgress;
  final bool isPreviewing;
  final bool anyRecording;
  final bool isCompact;

  final VoidCallback onRecord;
  final VoidCallback onPreview;

  const _SoundRow({
    required this.soundKey,
    required this.label,
    required this.maxDuration,
    required this.isRecorded,
    required this.isRecording,
    required this.recordingProgress,
    required this.isPreviewing,
    required this.anyRecording,
    required this.isCompact,
    required this.onRecord,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = maxDuration * (1 - recordingProgress);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.symmetric(
          horizontal: 14, vertical: isCompact ? 7 : 10),
      decoration: BoxDecoration(
        color: isRecording
            ? Colors.red.withValues(alpha: 0.12)
            : const Color(0xFF1A2A0E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRecording
              ? Colors.red.withValues(alpha: 0.6)
              : isRecorded
                  ? Colors.green.withValues(alpha: 0.35)
                  : const Color(0xFF2A4A1A),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Дуугийн нэр + status
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isRecorded && !isRecording)
                      _Chip(
                          '✓ Бичигдсэн', Colors.green, Colors.green.shade900)
                    else if (!isRecorded && !isRecording)
                      _Chip('Хоосон', Colors.white38, const Color(0xFF1A2A0E)),
                    const SizedBox(width: 4),
                    Text(
                      '${maxDuration.toStringAsFixed(1)}с',
                      style: const TextStyle(
                          color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Товчнууд
              if (isRecording) ...[
                // Хугацааны тоолуур
                SizedBox(
                  width: 36,
                  child: Text(
                    remaining.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                _IconBtn(
                  icon: Icons.stop,
                  color: Colors.red,
                  tooltip: 'Зогсоох',
                  onTap: onRecord,
                ),
              ] else ...[
                // Бичих / Засах товч
                // Бичигдсэн дуунд: edit icon (dialog нээнэ)
                // Бичигдээгүй дуунд: mic icon (шууд бичнэ)
                _IconBtn(
                  icon: isRecorded ? Icons.edit_note : Icons.mic,
                  color: anyRecording
                      ? Colors.white24
                      : isRecorded
                          ? Colors.white60
                          : const Color(0xFFFFD700),
                  tooltip: anyRecording
                      ? ''
                      : isRecorded
                          ? 'Засах'
                          : 'Бичих',
                  onTap: anyRecording ? null : onRecord,
                ),
                if (isRecorded) ...[
                  _IconBtn(
                    icon: isPreviewing ? Icons.volume_up : Icons.play_arrow,
                    color: isPreviewing ? Colors.amber : Colors.white60,
                    tooltip: isPreviewing ? 'Зогсоох' : 'Сонсох',
                    onTap: onPreview,
                  ),
                ],
              ],
            ],
          ),
          // Progress bar бичиж байх үед
          if (isRecording) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: recordingProgress,
                backgroundColor: Colors.red.withValues(alpha: 0.15),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color textColor;
  final Color bgColor;
  const _Chip(this.text, this.textColor, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: TextStyle(color: textColor, fontSize: 10)),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;
  const _IconBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Start button
// ────────────────────────────────────────────────────────────────

class _StartButton extends StatelessWidget {
  final bool isCompact;
  final VoidCallback onStart;
  const _StartButton({required this.isCompact, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: isCompact ? 10 : 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2A0E),
        border: Border(top: BorderSide(color: Color(0xFF2A4A1A), width: 1)),
      ),
      child: GestureDetector(
        onTap: onStart,
        child: Container(
          height: isCompact ? 42 : 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow, color: Colors.black, size: 24),
              const SizedBox(width: 8),
              Text(
                'ТОГЛООМ ЭХЛЭХ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 14 : 16,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
