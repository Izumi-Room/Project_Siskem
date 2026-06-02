import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../models/user_model.dart';
import '../../models/absensi_model.dart';
import '../../services/realtime_database_service.dart';
import '../../services/triple_des_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/lottie_assets.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/shimmer_loader.dart';

class RiwayatScreen extends StatefulWidget {
  final UserModel user;
  const RiwayatScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<AbsensiModel> _riwayatList = [];
  List<AbsensiModel> _filtered = [];
  bool _isLoading = true;
  String _errorMsg = '';
  String _searchQuery = '';
  final _databaseService = RealtimeDatabaseService();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_riwayatList);
    } else {
      _filtered = _riwayatList.where((a) {
        return a.tanggal.toLowerCase().contains(_searchQuery) ||
            a.status.toLowerCase().contains(_searchQuery) ||
            a.jam.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _fetchRiwayat() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final data =
          await _databaseService.getRiwayatAbsensi(widget.user.uid);
      setState(() {
        _riwayatList = data;
        _applyFilter();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMsg = 'Gagal mengambil riwayat dari Firebase.';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir')) return AppColors.success;
    if (s.contains('sakit')) return AppColors.warning;
    if (s.contains('izin')) return AppColors.info;
    return AppColors.textSecondary;
  }

  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir')) return Icons.check_circle_rounded;
    if (s.contains('sakit')) return Icons.medical_services_rounded;
    if (s.contains('izin')) return Icons.event_note_rounded;
    return Icons.help_rounded;
  }

  void _showDetail(AbsensiModel absensi) {
    // Skip decrypt for manual Sakit/Izin submissions (no cipherText)
    final isManual = absensi.isManual;
    String decrypted = '';
    bool ok = false;

    if (!isManual) {
      try {
        decrypted = TripleDesService.decryptData(absensi.cipherText);
        ok = true;
      } catch (_) {
        decrypted = 'Tidak dapat mendekripsi data.';
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor(absensi.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(_statusIcon(absensi.status),
                      color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absensi.status,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${absensi.tanggal}  ·  ${absensi.jam}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: isManual ? 'MANUAL' : '3DES',
                  color: isManual ? AppColors.warning : AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Manual submission: show reason only
            if (isManual) ...[
              Text(
                'JENIS ABSENSI',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.warning,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(absensi.status),
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Absensi Manual (${absensi.status})',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (absensi.reason != null &&
                  absensi.reason!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'KETERANGAN',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                  child: Text(
                    absensi.reason!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ]
            // QR-based: show ciphertext + decrypt
            else ...[
              Text(
                'CIPHERTEXT TERENKRIPSI',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.error,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: SelectableText(
                  absensi.cipherText,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'HASIL DEKRIPSI',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      decrypted,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (ok) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Format: user_id | session_id | tanggal | jam | status | key',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Tutup',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Kehadiran',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_riwayatList.length} catatan absensi',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari tanggal, status...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textTertiary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Content ──────────────────────────────────────────────────
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: 6,
        itemBuilder: (_, __) => const ListItemSkeleton(),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 56,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMsg,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 160,
                child: PrimaryButton(
                  label: 'Coba Lagi',
                  onPressed: _fetchRiwayat,
                  icon: Icons.refresh_rounded,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return EmptyStateWidget(
        animation: Lottie.asset(
          LottieAssets.emptyState,
          repeat: true,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.calendar_today_rounded,
            size: 80,
            color: AppColors.textTertiary,
          ),
        ),
        title: _searchQuery.isNotEmpty
            ? 'Tidak Ditemukan'
            : 'Belum Ada Riwayat',
        subtitle: _searchQuery.isNotEmpty
            ? 'Coba kata kunci lain'
            : 'Scan QR Code untuk mulai absensi',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, 100),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final absensi = _filtered[i];
          final color = _statusColor(absensi.status);
          final isLast = i == _filtered.length - 1;

          return _TimelineItem(
            absensi: absensi,
            color: color,
            icon: _statusIcon(absensi.status),
            isLast: isLast,
            isDark: isDark,
            onTap: () => _showDetail(absensi),
          );
        },
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final AbsensiModel absensi;
  final Color color;
  final IconData icon;
  final bool isLast;
  final bool isDark;
  final VoidCallback onTap;

  const _TimelineItem({
    required this.absensi,
    required this.color,
    required this.icon,
    required this.isLast,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: onTap,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            absensi.status,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${absensi.tanggal}  ·  ${absensi.jam}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (absensi.isManual && absensi.reason != null && absensi.reason!.isNotEmpty)
                            Text(
                              absensi.reason!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(
                          label: absensi.isManual ? 'MANUAL' : '3DES',
                          color: absensi.isManual
                              ? AppColors.warning
                              : AppColors.success,
                          icon: absensi.isManual
                              ? Icons.edit_note_rounded
                              : Icons.lock_rounded,
                          small: true,
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
