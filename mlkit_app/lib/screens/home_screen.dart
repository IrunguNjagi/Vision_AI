import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mlkit_app/services/detection_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DetectionService _service = DetectionService();

  Uint8List? _imageBytes;
  DetectionResult? _result;
  bool _loading = false;
  String? _error;
  double _confidence = 0.25;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _imageBytes = result.files.single.bytes!;
        _result = null;
        _error = null;
      });
      await _runDetection();
    }
  }

  Future<void> _runDetection() async {
    if (_imageBytes == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.detect(
        _imageBytes!,
        confidence: _confidence,
      );
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFF00E676);
    if (confidence >= 0.5) return const Color(0xFFFFD600);
    return const Color(0xFFFF6D00);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Column(
        children: [
          _buildTopBar(),
          if (_result != null) _buildStatsBar(),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      Expanded(flex: 3, child: _buildImageArea()),
                      if (_result != null)
                        SizedBox(width: 340, child: _buildResultsPanel()),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 400, child: _buildImageArea()),
                        if (_result != null) _buildResultsPanel(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D14),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E2E), width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: Color(0xFF00E5FF), size: 22),
          const SizedBox(width: 10),
          const Text(
            'VisionAI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'YOLOv8',
              style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11),
            ),
          ),
          const Spacer(),
          const Text(
            'Confidence',
            style: TextStyle(color: Color(0xFF888899), fontSize: 13),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF00E5FF),
                inactiveTrackColor: const Color(0xFF1E1E2E),
                thumbColor: const Color(0xFF00E5FF),
                overlayColor: const Color(0xFF00E5FF22),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _confidence,
                min: 0.1,
                max: 0.9,
                onChanged: (v) => setState(() => _confidence = v),
                onChangeEnd: (_) => _runDetection(),
              ),
            ),
          ),
          Text(
            '${(_confidence * 100).round()}%',
            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: _loading ? null : _pickImage,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Upload Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS BAR ─────────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    final r = _result!;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFF0D0D14),
      child: Row(
        children: [
          _statItem(
            Icons.speed,
            '${r.inferenceTimeMs}ms',
            const Color(0xFF00E5FF),
          ),
          _statDivider(),
          _statItem(
            Icons.category,
            '${r.totalObjects} objects',
            const Color(0xFF00E676),
          ),
          _statDivider(),
          _statItem(
            Icons.label,
            '${r.labelCounts.length} classes',
            const Color(0xFFFFD600),
          ),
          _statDivider(),
          _statItem(
            Icons.photo_size_select_actual,
            '${r.originalSize['width']}×${r.originalSize['height']}',
            const Color(0xFFBB86FC),
          ),
          const Spacer(),
          ...r.labelCounts.entries
              .take(5)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      e.value > 1 ? '${e.key} ×${e.value}' : e.key,
                      style: const TextStyle(
                        color: Color(0xFF888899),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statDivider() => Container(
    width: 1,
    height: 16,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: const Color(0xFF1E1E2E),
  );

  // ── IMAGE AREA ────────────────────────────────────────────────────────────

  Widget _buildImageArea() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E5FF)),
            SizedBox(height: 16),
            Text(
              'Running inference...',
              style: TextStyle(color: Color(0xFF888899)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF4D6D), size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFFF4D6D))),
            const SizedBox(height: 12),
            TextButton(onPressed: _runDetection, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_result != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(_result!.annotatedImage, fit: BoxFit.contain),
        ),
      );
    }

    // Drop zone
    return _buildDropZone();
  }

  Widget _buildDropZone() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 380,
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A3E), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xFF00E5FF),
                  size: 56,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Click to upload an image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PNG, JPG, WEBP supported',
                  style: TextStyle(color: Color(0xFF555566), fontSize: 13),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Browse files',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── RESULTS PANEL ─────────────────────────────────────────────────────────

  Widget _buildResultsPanel() {
    final r = _result!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D14),
        border: Border(left: BorderSide(color: Color(0xFF1E1E2E))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E1E2E))),
            ),
            child: Row(
              children: [
                const Text(
                  'Detections',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${r.totalObjects}',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: r.detections.isEmpty
                ? const Center(
                    child: Text(
                      'No objects detected',
                      style: TextStyle(color: Color(0xFF555566)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: r.detections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final d = r.detections[index];
                      final color = _confidenceColor(d.confidence);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1E1E2E)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: d.confidence,
                                      backgroundColor: const Color(0xFF1E1E2E),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                      minHeight: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(d.confidence * 100).round()}%',
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
