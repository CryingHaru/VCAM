import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/camera_models.dart';

class VcamService {
  String host;
  int port;

  static const _galleryChannel = MethodChannel('com.example.vcam/gallery');

  VcamService({
    this.host = '127.0.0.1',
    this.port = 8080,
  });

  String get baseUrl => 'http://$host:$port';
  String get streamUrl => '$baseUrl/vcam/stream';

  Future<CameraInfo> fetchInfo() async {
    final uri = Uri.parse('$baseUrl/vcam/info');
    final response = await http.get(uri).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CameraInfo.fromJson(json);
    } else {
      throw Exception('Server returned HTTP ${response.statusCode}');
    }
  }

  Future<CameraParams> updateParams({
    int? iso,
    int? exposureTimeNs,
    double? focusDistance,
    int? awbMode,
    int? exposureCompensation,
    String? previewCam,
    String? captureCam,
  }) async {
    final queryParams = <String, String>{};
    if (iso != null) queryParams['iso'] = iso.toString();
    if (exposureTimeNs != null) queryParams['exposure'] = exposureTimeNs.toString();
    if (focusDistance != null) queryParams['focus'] = focusDistance.toString();
    if (awbMode != null) queryParams['wb'] = awbMode.toString();
    if (exposureCompensation != null) queryParams['ev'] = exposureCompensation.toString();
    if (previewCam != null) queryParams['preview_cam'] = previewCam;
    if (captureCam != null) queryParams['capture_cam'] = captureCam;

    final uri = Uri.parse('$baseUrl/vcam/params').replace(queryParameters: queryParams);
    final response = await http.get(uri).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CameraParams.fromJson(json);
    } else {
      throw Exception('Error updating params: HTTP ${response.statusCode}');
    }
  }

  Future<Map<String, String>> swapCameras() async {
    final uri = Uri.parse('$baseUrl/vcam/swap');
    final response = await http.get(uri).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'preview_camera_id': json['preview_camera_id']?.toString() ?? '',
        'capture_camera_id': json['capture_camera_id']?.toString() ?? '',
      };
    } else {
      throw Exception('Error swapping cameras: HTTP ${response.statusCode}');
    }
  }

  Future<({Uint8List bytes, String filename})> capture({
    required String format,
    required int count,
    required CameraParams params,
    String? captureCam,
  }) async {
    final queryParams = <String, String>{
      'format': format,
      'count': count.toString(),
      'iso': params.iso.toString(),
      'exposure': params.exposureTimeNs.toString(),
      'focus': params.focusDistance.toString(),
      'wb': params.awbMode.toString(),
      'ev': params.exposureCompensation.toString(),
    };
    if (captureCam != null) {
      queryParams['capture_cam'] = captureCam;
    }

    final uri = Uri.parse('$baseUrl/vcam/capture').replace(queryParameters: queryParams);
    final effectiveTimeout = Duration(
      seconds: ((params.exposureTimeNs / 1000000000.0) * count).ceil() + 45,
    );

    final response = await http.get(uri).timeout(effectiveTimeout);
    if (response.statusCode == 200) {
      String filename = 'capture.$format';
      final disposition = response.headers['content-disposition'];
      if (disposition != null && disposition.contains('filename=')) {
        final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
        if (match != null) {
          filename = match.group(1) ?? filename;
        }
      }
      return (bytes: response.bodyBytes, filename: filename);
    } else {
      throw Exception('Capture failed: HTTP ${response.statusCode}');
    }
  }

  Future<String> saveCaptureLocally(Uint8List bytes, String filename) async {
    Directory? baseDir;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      baseDir = await getDownloadsDirectory();
    } else if (Platform.isIOS || Platform.isAndroid) {
      baseDir = await getApplicationDocumentsDirectory();
    }

    baseDir ??= await getTemporaryDirectory();
    final vcamDir = Directory('${baseDir.path}/VCAM');
    if (!await vcamDir.exists()) {
      await vcamDir.create(recursive: true);
    }

    final filePath = '${vcamDir.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (Platform.isIOS) {
      if (filename.toLowerCase().endsWith('.zip')) {
        try {
          final archive = ZipDecoder().decodeBytes(bytes);
          for (final entry in archive) {
            if (entry.isFile && (entry.name.endsWith('.dng') || entry.name.endsWith('.raw'))) {
              final unzippedPath = '${vcamDir.path}/${entry.name}';
              final unzippedFile = File(unzippedPath);
              await unzippedFile.writeAsBytes(entry.content as List<int>);
              await _galleryChannel.invokeMethod('saveToPhotos', {'filePath': unzippedPath});
            }
          }
        } catch (_) {}
      } else {
        try {
          await _galleryChannel.invokeMethod('saveToPhotos', {'filePath': filePath});
        } catch (_) {}
      }
    }

    return filePath;
  }
}
