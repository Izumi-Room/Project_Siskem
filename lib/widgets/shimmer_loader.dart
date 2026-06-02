import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// SHIMMER LOADING SYSTEM
// Replaces CircularProgressIndicator with skeleton screens
// ════════════════════════════════════════════════════════════════════════════

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? const Color(0xFF1E1E2E)
        : const Color(0xFFE8EAFF);
    final highlightColor = isDark
        ? const Color(0xFF2D2D4A)
        : const Color(0xFFF0F1FF);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value + 1, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Dashboard skeleton loader
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header skeleton
          Container(
            height: 200,
            margin: const EdgeInsets.all(0),
            child: const ShimmerBox(
              width: double.infinity,
              height: 200,
              borderRadius: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card skeleton
                const ShimmerBox(
                  width: double.infinity,
                  height: 120,
                  borderRadius: AppRadius.xl,
                ),
                const SizedBox(height: AppSpacing.md),
                // Stats row skeleton
                Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                      child: const ShimmerBox(
                        width: double.infinity,
                        height: 80,
                        borderRadius: AppRadius.lg,
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: AppSpacing.md),
                // List items skeleton
                ...List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: const ShimmerBox(
                    width: double.infinity,
                    height: 72,
                    borderRadius: AppRadius.lg,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List item skeleton
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 6,
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 48, height: 48, borderRadius: AppRadius.md),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 14,
                  borderRadius: AppRadius.xs,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 12,
                  borderRadius: AppRadius.xs,
                ),
              ],
            ),
          ),
          const ShimmerBox(width: 60, height: 28, borderRadius: AppRadius.full),
        ],
      ),
    );
  }
}
