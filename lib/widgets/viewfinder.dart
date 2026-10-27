import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VcamViewfinder extends StatefulWidget {
  final String streamUrl;
  final String activeCameraId;
  final bool isCapturing;

  const VcamViewfinder({
    super.key,
    required this.streamUrl,
    required this.activeCameraId,
    this.isCapturing = false,
  });

  @override
  State<VcamViewfinder> createState() => _VcamViewfinderState();
}

class _VcamViewfinderState extends State<VcamViewfinder> {
  late final Player _player;
  late final VideoController _videoController;
  StreamSubscription? _completedSub;
  StreamSubscription? _errorSub;
  bool _showGrid = true;

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024,
      ),
    );
    _videoController = VideoController(_player);

    _completedSub = _player.stream.completed.listen((completed) {
      if (completed && mounted) {
        _initStream();
      }
    });

    _errorSub = _player.stream.error.listen((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 250), _initStream);
      }
    });

    _initStream();
  }

  @override
  void didUpdateWidget(covariant VcamViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl || oldWidget.activeCameraId != widget.activeCameraId) {
      _initStream();
    }
  }

  Future<void> _initStream() async {
    try {
      final nativePlatform = _player.platform as dynamic;
      nativePlatform.setProperty('demuxer-lavf-o', 'nobuffer=1');
      nativePlatform.setProperty('profile', 'low-latency');
      nativePlatform.setProperty('untimed', 'yes');
      nativePlatform.setProperty('cache', 'no');
    } catch (_) {}

    await _player.open(Media(widget.streamUrl), play: true);
  }

  @override
  void dispose() {
    _completedSub?.cancel();
    _errorSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Video(
              controller: _videoController,
              controls: NoVideoControls,
            ),
          ),
          if (_showGrid)
            CustomPaint(
              painter: _GridPainter(),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => setState(() => _showGrid = !_showGrid),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  _showGrid ? Icons.grid_on : Icons.grid_off,
                  color: _showGrid ? const Color(0xFFEF4444) : const Color(0xFF3F3F46),
                  size: 16,
                ),
              ),
            ),
          ),
          if (widget.isCapturing)
            const Positioned(
              top: 10,
              left: 10,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    final x1 = size.width / 3.0;
    final x2 = size.width * 2.0 / 3.0;
    final y1 = size.height / 3.0;
    final y2 = size.height * 2.0 / 3.0;

    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), paint);
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
