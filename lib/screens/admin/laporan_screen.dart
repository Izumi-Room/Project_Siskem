import 'package:flutter/material.dart';
import '../../models/absensi_model.dart';
import '../../services/realtime_database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/shimmer_loader.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({Key? key}) : super(key: key);

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  List<AbsensiModel> _absensiList = [];
  Map<String, Map<String, dynamic>> _rekap = {};
  bool _isLoading = true;
  String _errorMsg = '';
  final _db = RealtimeDatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final list = await _db.getAllAbsensi();
      final Map<String, Map<String, dynamic>> rekap = {};
      for (final item in list) {
        final nim = item.nim ?? '-';
        rekap.putIfAbsent(nim, () => {
          'nama': item.nama ?? 'N/A',
          'nim': nim,
          'hadir': 0,
          'sakit': 0,
          'izin': 0,
          'total': 0,
        });
        final s = item.status.toLowerCase();
        if (s.contains('hadir')) rekap[nim]!['hadir']++;
        if (s.contains('sakit')) rekap[nim]!['sakit']++;
        if (s.contains('izin')) rekap[nim]!['izin']++;
        rekap[nim]!['total']++;
      }
      setState(() {
        _absensiList = list;
        _rekap = rekap;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMsg = 'Gagal mengambil laporan.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                        'Laporan',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rekapitulasi kehadiran mahasiswa',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _fetchLaporan,
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
        itemCount: 5,
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
                onPressed: _fetchLaporan,
                icon: Icons.refresh_rounded,
              ),
            ),
          ],
        ),
      );
    }

    final rekapList = _rekap.values.toList();

    return RefreshIndicator(
      onRefresh: _fetchLaporan,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, 100),
        children: [
          // Summary card
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Total Mahasiswa',
                    value: '${_rekap.length}',
                    color: AppColors.info,
                    icon: Icons.people_rounded,
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Total Absensi',
                    value: '${_absensiList.length}',
                    color: AppColors.success,
                    icon: Icons.assignment_turned_in_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SectionHeader(title: 'Rekap Per Mahasiswa'),
          const SizedBox(height: AppSpacing.md),

          if (rekapList.isEmpty)
            AppCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Belum ada data kehadiran.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            )
          else
            ...rekapList.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RekapCard(rekap: r, isDark: isDark),
            )),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RekapCard extends StatelessWidget {
  final Map<String, dynamic> rekap;
  final bool isDark;

  const _RekapCard({required this.rekap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = (rekap['total'] as int).clamp(1, 9999);
    final hadir = rekap['hadir'] as int;
    final pct = hadir / total;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    (rekap['nama'] as String).isNotEmpty
                        ? (rekap['nama'] as String)[0].toUpperCase()
                        : 'M',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rekap['nama'] as String,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'NIM: ${rekap['nim']}',
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
                label: '${(pct * 100).toStringAsFixed(0)}%',
                color: pct >= 0.75
                    ? AppColors.success
                    : pct >= 0.5
                        ? AppColors.warning
                        : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AttendanceProgressBar(
            percentage: pct,
            color: pct >= 0.75
                ? AppColors.success
                : pct >= 0.5
                    ? AppColors.warning
                    : AppColors.error,
            height: 6,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatChip(
                label: 'Hadir',
                value: '${rekap['hadir']}',
                color: AppColors.success,
              ),
              _StatChip(
                label: 'Sakit',
                value: '${rekap['sakit']}',
                color: AppColors.warning,
              ),
              _StatChip(
                label: 'Izin',
                value: '${rekap['izin']}',
                color: AppColors.info,
              ),
              _StatChip(
                label: 'Total',
                value: '${rekap['total']}',
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
