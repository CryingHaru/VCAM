class CameraParams {
  int iso;
  int exposureTimeNs;
  double focusDistance;
  int awbMode;
  int exposureCompensation;

  CameraParams({
    this.iso = 0,
    this.exposureTimeNs = 0,
    this.focusDistance = -1.0,
    this.awbMode = 0,
    this.exposureCompensation = 0,
  });

  factory CameraParams.fromJson(Map<String, dynamic> json) {
    return CameraParams(
      iso: (json['iso'] as num?)?.toInt() ?? 0,
      exposureTimeNs: (json['exposureTimeNs'] as num?)?.toInt() ?? 0,
      focusDistance: (json['focusDistance'] as num?)?.toDouble() ?? -1.0,
      awbMode: (json['awbMode'] as num?)?.toInt() ?? 0,
      exposureCompensation: (json['exposureCompensation'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'iso': iso,
    'exposureTimeNs': exposureTimeNs,
    'focusDistance': focusDistance,
    'awbMode': awbMode,
    'exposureCompensation': exposureCompensation,
  };

  CameraParams copyWith({
    int? iso,
    int? exposureTimeNs,
    double? focusDistance,
    int? awbMode,
    int? exposureCompensation,
  }) {
    return CameraParams(
      iso: iso ?? this.iso,
      exposureTimeNs: exposureTimeNs ?? this.exposureTimeNs,
      focusDistance: focusDistance ?? this.focusDistance,
      awbMode: awbMode ?? this.awbMode,
      exposureCompensation: exposureCompensation ?? this.exposureCompensation,
    );
  }

  String get exposureLabel {
    if (exposureTimeNs <= 0) return 'AUTO';
    final sec = exposureTimeNs / 1000000000.0;
    if (sec >= 1.0) {
      return '${sec.toStringAsFixed(sec.truncateToDouble() == sec ? 0 : 1)}s';
    }
    final denom = (1.0 / sec).round();
    return '1/$denom';
  }

  String get isoLabel => iso == 0 ? 'AUTO' : '$iso';

  String get focusLabel {
    if (focusDistance < 0) return 'AUTO';
    if (focusDistance == 0.0) return 'INF';
    if (focusDistance >= 10.0) return 'MACRO';
    return focusDistance.toStringAsFixed(1);
  }

  String get awbLabel {
    switch (awbMode) {
      case 5:
        return 'DAY';
      case 6:
        return 'CLOUD';
      case 1:
        return 'TUNG';
      case 2:
        return 'FLUO';
      default:
        return 'AUTO';
    }
  }

  String get evLabel {
    if (exposureCompensation > 0) return '+$exposureCompensation';
    return '$exposureCompensation';
  }
}

class CameraInfo {
  final String service;
  final String status;
  final String device;
  final String codec;
  final String streamPath;
  final List<String> rearCameras;
  final String previewCameraId;
  final String captureCameraId;
  final String activeCameraId;
  final int previewWidth;
  final int previewHeight;
  final int rawWidth;
  final int rawHeight;
  final CameraParams params;

  CameraInfo({
    required this.service,
    required this.status,
    required this.device,
    required this.codec,
    required this.streamPath,
    required this.rearCameras,
    required this.previewCameraId,
    required this.captureCameraId,
    required this.activeCameraId,
    required this.previewWidth,
    required this.previewHeight,
    required this.rawWidth,
    required this.rawHeight,
    required this.params,
  });

  factory CameraInfo.fromJson(Map<String, dynamic> json) {
    return CameraInfo(
      service: json['service'] as String? ?? 'vcam',
      status: json['status'] as String? ?? 'init',
      device: json['device'] as String? ?? 'Unknown',
      codec: json['codec'] as String? ?? 'h265',
      streamPath: json['stream'] as String? ?? '/vcam/stream',
      rearCameras: (json['rear_cameras'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      previewCameraId: json['preview_camera_id']?.toString() ?? '0',
      captureCameraId: json['capture_camera_id']?.toString() ?? '0',
      activeCameraId: json['active_camera_id']?.toString() ?? '0',
      previewWidth: (json['preview_width'] as num?)?.toInt() ?? 1280,
      previewHeight: (json['preview_height'] as num?)?.toInt() ?? 720,
      rawWidth: (json['raw_width'] as num?)?.toInt() ?? 4032,
      rawHeight: (json['raw_height'] as num?)?.toInt() ?? 3024,
      params: json['params'] != null
          ? CameraParams.fromJson(json['params'] as Map<String, dynamic>)
          : CameraParams(),
    );
  }
}

