import 'package:flutter/material.dart';
import '../../models/absensi_model.dart';
import '../../services/realtime_database_service.dart';
import '../../services/triple_des_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/shimmer_loader.dart';

class DataAbsensiScreen extends StatefulWidget {
  const DataAbsensiScreen({Key? key}) : super(key: key);

  @override
  State<DataAbsensiScreen> createState() => _DataAbsensiScreenState();
}

class _DataAbsensiScreenState extends State<DataAbsensiScreen> {
  List<AbsensiModel> _list = [];
  bool _isLoading = true;
  String _errorMsg = '';
  final _db = RealtimeDatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchAbsensi();
  }

  Future<void> _fetchAbsensi() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final data = await _db.getAllAbsensi();
      setState(() {
        _list = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMsg = 'Gagal mengambil data absensi.';
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

  void _showDetail(AbsensiModel absensi) {
    String decrypted = '';
    bool ok = true;
    try {
      decrypted = TripleDesService.decryptData(absensi.cipherText);
    } catch (e) {
      decrypted = 'Dekripsi gagal: $e';
      ok = false;
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.enhanced_encryption_rounded,
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absensi.nama ?? 'Mahasiswa',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'NIM: ${absensi.nim ?? '-'}  ·  ${absensi.tanggal}  ·  ${absensi.jam}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(label: absensi.status, color: color),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'CIPHERTEXT',
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
                color: isDark ? AppColors.cardDark : const Color(0xFFFFF5F5),
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
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Absensi',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_list.length} catatan',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _fetchAbsensi,
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => const ListItemSkeleton(),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 56,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(_errorMsg,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                )),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 160,
              child: PrimaryButton(
                label: 'Coba Lagi',
                onPressed: _fetchAbsensi,
                icon: Icons.refresh_rounded,
              ),
            ),
          ],
        ),
      );
    }

    if (_list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined,
                size: 64,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum ada data absensi',
              style: AppTextStyles.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAbsensi,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, 100),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final absensi = _list[i];
          final color = _statusColor(absensi.status);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => _showDetail(absensi),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.person_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          absensi.nama ?? 'Mahasiswa',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIM: ${absensi.nim ?? '-'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${absensi.tanggal}  ·  ${absensi.jam}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(label: absensi.status, color: color),
                      const SizedBox(height: 4),
                      StatusBadge(
                        label: '3DES',
                        color: AppColors.success,
                        icon: Icons.lock_rounded,
                        small: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
