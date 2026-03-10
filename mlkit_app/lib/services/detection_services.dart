import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetectionResult {
  final bool success;
  final double inferenceTimeMs;
  final int totalObjects;
  final Map<String, int> labelCounts;
  final List<Detection> detections;
  final String annotatedImage; // base64 data URI
  final Map<String, int> originalSize;

  DetectionResult({
    required this.success,
    required this.inferenceTimeMs,
    required this.totalObjects,
    required this.labelCounts,
    required this.detections,
    required this.annotatedImage,
    required this.originalSize,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      success: json['success'] ?? false,
      inferenceTimeMs: (json['inference_time_ms'] ?? 0).toDouble(),
      totalObjects: json['total_objects'] ?? 0,
      labelCounts: Map<String, int>.from(json['label_counts'] ?? {}),
      detections: (json['detections'] as List<dynamic>? ?? [])
          .map((d) => Detection.fromJson(d))
          .toList(),
      annotatedImage: json['annotated_image'] ?? '',
      originalSize: Map<String, int>.from(json['original_size'] ?? {}),
    );
  }
}

class Detection {
  final String label;
  final double confidence;
  final Map<String, int> bbox;

  Detection({
    required this.label,
    required this.confidence,
    required this.bbox,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: json['label'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      bbox: Map<String, int>.from(json['bbox'] ?? {}),
    );
  }
}

class DetectionService {
  static const String baseUrl = 'http://localhost:5000';

  Future<DetectionResult> detect(
    Uint8List imageBytes, {
    double confidence = 0.25,
  }) async {
    final uri = Uri.parse('$baseUrl/detect');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes, filename: 'image.jpg'),
    );
    request.fields['confidence'] = confidence.toString();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return DetectionResult.fromJson(json);
    } else {
      throw Exception('Detection failed: ${response.body}');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
