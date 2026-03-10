import 'package:flutter/material.dart';
import 'package:mlkit_app/services/detection_services.dart';

class StatsBar extends StatelessWidget {
  final DetectionResult result;

  const StatsBar({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFF0D0D14),
      child: Row(
        children: [
          _Stat(
            icon: Icons.speed,
            label: '${result.inferenceTimeMs}ms',
            color: const Color(0xFF00E5FF),
          ),
          const _Divider(),
          _Stat(
            icon: Icons.category,
            label: '${result.totalObjects} objects',
            color: const Color(0xFF00E676),
          ),
          const _Divider(),
          _Stat(
            icon: Icons.label,
            label: '${result.labelCounts.length} classes',
            color: const Color(0xFFFFD600),
          ),
          const _Divider(),
          _Stat(
            icon: Icons.photo_size_select_actual,
            label:
                '${result.originalSize['width']}×${result.originalSize['height']}',
            color: const Color(0xFFBB86FC),
          ),
          const Spacer(),
          // Label chips
          ...result.labelCounts.entries
              .take(5)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _LabelChip(label: e.key, count: e.value),
                ),
              ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Stat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFF1E1E2E),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final int count;

  const _LabelChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        count > 1 ? '$label ×$count' : label,
        style: const TextStyle(color: Color(0xFF888899), fontSize: 11),
      ),
    );
  }
}
