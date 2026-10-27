import 'package:flutter/material.dart';
import '../models/camera_models.dart';

class VcamControlsPanel extends StatelessWidget {
  final List<String> rearCameras;
  final String previewCam;
  final String captureCam;
  final CameraParams params;
  final int sequenceCount;
  final bool isCapturing;

  final ValueChanged<String> onPreviewCamChanged;
  final ValueChanged<String> onCaptureCamChanged;
  final VoidCallback onSwapCameras;
  final ValueChanged<CameraParams> onParamsChanged;
  final ValueChanged<int> onSequenceCountChanged;
  final VoidCallback onShoot;

  const VcamControlsPanel({
    super.key,
    required this.rearCameras,
    required this.previewCam,
    required this.captureCam,
    required this.params,
    required this.sequenceCount,
    required this.isCapturing,
    required this.onPreviewCamChanged,
    required this.onCaptureCamChanged,
    required this.onSwapCameras,
    required this.onParamsChanged,
    required this.onSequenceCountChanged,
    required this.onShoot,
  });

  static const exposureTimes = <int, String>{
    0: 'AUTO',
    500000: '1/2000',
    1000000: '1/1000',
    2000000: '1/500',
    4000000: '1/250',
    8000000: '1/125',
    16666666: '1/60',
    33333333: '1/30',
    66666666: '1/15',
    125000000: '1/8',
    250000000: '1/4',
    500000000: '1/2',
    1000000000: '1s',
    2000000000: '2s',
    4000000000: '4s',
    8000000000: '8s',
    15000000000: '15s',
    20000000000: '20s',
    30000000000: '30s',
  };

  static const isoOptions = <int>[0, 50, 100, 200, 400, 800, 1600, 3200];
  static final focusOptions = <double, String>{
    -1.0: 'AUTO',
    0.0: 'INF',
    1.0: '1.0',
    3.0: '3.0',
    6.0: '6.0',
    10.0: 'MACRO',
  };
  static const wbOptions = <int, String>{
    0: 'AUTO',
    5: 'DAY',
    6: 'CLOUD',
    1: 'TUNG',
    2: 'FLUO',
  };
  static const evOptions = <int>[-3, -2, -1, 0, 1, 2, 3];
  static const seqOptions = <int>[1, 2, 3, 5, 10, 15, 20, 30, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF09090B),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSelector(
                  label: 'PREV',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: rearCameras.contains(previewCam) ? previewCam : (rearCameras.isNotEmpty ? rearCameras.first : null),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF18181B),
                      style: _textStyle,
                      items: rearCameras.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
                      onChanged: isCapturing || rearCameras.isEmpty ? null : (val) => val != null ? onPreviewCamChanged(val) : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSelector(
                  label: 'CAPT',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: rearCameras.contains(captureCam) ? captureCam : (rearCameras.isNotEmpty ? rearCameras.first : null),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF18181B),
                      style: _textStyle,
                      items: rearCameras.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
                      onChanged: isCapturing || rearCameras.isEmpty ? null : (val) => val != null ? onCaptureCamChanged(val) : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: isCapturing ? null : onSwapCameras,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF27272A)),
                    shape: const RoundedRectangleBorder(),
                    backgroundColor: const Color(0xFF18181B),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('SWAP', style: _textStyle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              SizedBox(
                width: 95,
                child: _buildSelector(
                  label: 'ISO',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: isoOptions.contains(params.iso) ? params.iso : 0,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF18181B),
                      style: _textStyle,
                      items: isoOptions.map((iso) => DropdownMenuItem(value: iso, child: Text(iso == 0 ? 'AUTO' : '$iso'))).toList(),
                      onChanged: isCapturing ? null : (val) => val != null ? onParamsChanged(params.copyWith(iso: val)) : null,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: _buildSelector(
                  label: 'EXP',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: exposureTimes.containsKey(params.exposureTimeNs) ? params.exposureTimeNs : 0,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF18181B),
                      style: _textStyle,
                      items: exposureTimes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: isCapturing ? null : (val) => val != null ? onParamsChanged(params.copyWith(exposureTimeNs: val)) : null,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 95,
                child: _buildSelector(
                  label: 'AF',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: focusOptions.containsKey(params.focusDistance) ? params.focusDistance : -1.0,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF18181B),
                      style: _textStyle,
                      items: focusOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: isCapturing ? null : (val) => val != null ? onParamsChanged(params.copyWith(focusDistance: val)) : null,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 95,
                child: _buildSelector(
                  label: 'WB',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: wbOptions.containsKey(params.awbMode) ? params.awbMode : 0,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF18181B),
                      style: _textStyle,
                      items: wbOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: isCapturing ? null : (val) => val != null ? onParamsChanged(params.copyWith(awbMode: val)) : null,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: _buildSelector(
                  label: 'EV',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: evOptions.contains(params.exposureCompensation) ? params.exposureCompensation : 0,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF18181B),
                      style: _textStyle,
                      items: evOptions.map((ev) => DropdownMenuItem(value: ev, child: Text(ev > 0 ? '+$ev' : '$ev'))).toList(),
                      onChanged: isCapturing ? null : (val) => val != null ? onParamsChanged(params.copyWith(exposureCompensation: val)) : null,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: _buildSelector(
                  label: 'SEQ',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: seqOptions.contains(sequenceCount) ? sequenceCount : 1,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF18181B),
                      style: _textStyle,
                      items: seqOptions.map((seq) => DropdownMenuItem(value: seq, child: Text('$seq'))).toList(),
                      onChanged: isCapturing ? null : (val) => val != null ? onSequenceCountChanged(val) : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: isCapturing ? null : onShoot,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            child: Text(
              sequenceCount > 1 ? 'RAW ($sequenceCount)' : 'RAW',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({required String label, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF71717A),
              fontFamily: 'monospace',
            ),
          ),
          child,
        ],
      ),
    );
  }

  static const _textStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFFFAFAFA),
    fontFamily: 'monospace',
  );
}
