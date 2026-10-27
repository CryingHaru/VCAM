import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'models/camera_models.dart';
import 'services/vcam_discovery.dart';
import 'services/vcam_service.dart';
import 'widgets/controls_panel.dart';
import 'widgets/viewfinder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const VcamApp());
}

class VcamApp extends StatelessWidget {
  const VcamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VCAM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEF4444),
          surface: Color(0xFF09090B),
        ),
        fontFamily: 'monospace',
      ),
      home: const VcamHomeScreen(),
    );
  }
}

class VcamHomeScreen extends StatefulWidget {
  const VcamHomeScreen({super.key});

  @override
  State<VcamHomeScreen> createState() => _VcamHomeScreenState();
}

class _VcamHomeScreenState extends State<VcamHomeScreen> {
  VcamService? _service;
  CameraInfo? _cameraInfo;

  bool _isConnected = false;
  bool _isCapturing = false;
  int _sequenceCount = 1;

  StreamSubscription<({String host, int port})>? _discoverySub;

  @override
  void initState() {
    super.initState();
    _startAutoDiscovery();
  }

  @override
  void dispose() {
    _discoverySub?.cancel();
    super.dispose();
  }

  void _startAutoDiscovery() {
    _discoverySub?.cancel();
    _discoverySub = VcamDiscovery.discover().listen((peer) {
      if (!_isConnected) {
        _connectTo(peer.host, peer.port);
      }
    });
  }

  Future<void> _connectTo(String host, int port) async {
    final service = VcamService(host: host, port: port);
    try {
      final info = await service.fetchInfo();
      if (!mounted) return;
      setState(() {
        _service = service;
        _cameraInfo = info;
        _isConnected = true;
      });
    } catch (_) {}
  }

  Future<void> _updateParams(CameraParams newParams) async {
    final service = _service;
    if (service == null) return;
    try {
      final updated = await service.updateParams(
        iso: newParams.iso,
        exposureTimeNs: newParams.exposureTimeNs,
        focusDistance: newParams.focusDistance,
        awbMode: newParams.awbMode,
        exposureCompensation: newParams.exposureCompensation,
      );
      if (!mounted || _cameraInfo == null) return;
      setState(() {
        _cameraInfo = CameraInfo(
          service: _cameraInfo!.service,
          status: _cameraInfo!.status,
          device: _cameraInfo!.device,
          codec: _cameraInfo!.codec,
          streamPath: _cameraInfo!.streamPath,
          rearCameras: _cameraInfo!.rearCameras,
          previewCameraId: _cameraInfo!.previewCameraId,
          captureCameraId: _cameraInfo!.captureCameraId,
          activeCameraId: _cameraInfo!.activeCameraId,
          previewWidth: _cameraInfo!.previewWidth,
          previewHeight: _cameraInfo!.previewHeight,
          rawWidth: _cameraInfo!.rawWidth,
          rawHeight: _cameraInfo!.rawHeight,
          params: updated,
        );
      });
    } catch (_) {}
  }

  Future<void> _changePreviewCam(String id) async {
    final service = _service;
    if (service == null) return;
    try {
      await service.updateParams(previewCam: id);
      final info = await service.fetchInfo();
      if (!mounted) return;
      setState(() => _cameraInfo = info);
    } catch (_) {}
  }

  Future<void> _changeCaptureCam(String id) async {
    final service = _service;
    if (service == null) return;
    try {
      await service.updateParams(captureCam: id);
      final info = await service.fetchInfo();
      if (!mounted) return;
      setState(() => _cameraInfo = info);
    } catch (_) {}
  }

  Future<void> _swapCameras() async {
    final service = _service;
    if (service == null) return;
    try {
      await service.swapCameras();
      final info = await service.fetchInfo();
      if (!mounted) return;
      setState(() => _cameraInfo = info);
    } catch (_) {}
  }

  Future<void> _shoot() async {
    final service = _service;
    if (service == null || _cameraInfo == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final result = await service.capture(
        format: 'dng',
        count: _sequenceCount,
        params: _cameraInfo!.params,
        captureCam: _cameraInfo!.captureCameraId,
      );
      await service.saveCaptureLocally(result.bytes, result.filename);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected || _cameraInfo == null || _service == null) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
      );
    }

    final info = _cameraInfo!;
    final service = _service!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            final viewfinderWidget = VcamViewfinder(
              streamUrl: service.streamUrl,
              activeCameraId: info.previewCameraId,
              isCapturing: _isCapturing,
            );

            final controlsWidget = VcamControlsPanel(
              rearCameras: info.rearCameras,
              previewCam: info.previewCameraId,
              captureCam: info.captureCameraId,
              params: info.params,
              sequenceCount: _sequenceCount,
              isCapturing: _isCapturing,
              onPreviewCamChanged: _changePreviewCam,
              onCaptureCamChanged: _changeCaptureCam,
              onSwapCameras: _swapCameras,
              onParamsChanged: _updateParams,
              onSequenceCountChanged: (val) => setState(() => _sequenceCount = val),
              onShoot: _shoot,
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: viewfinderWidget),
                  Container(
                    width: 320,
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Color(0xFF27272A))),
                    ),
                    child: SingleChildScrollView(child: controlsWidget),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Expanded(child: viewfinderWidget),
                  SingleChildScrollView(child: controlsWidget),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
