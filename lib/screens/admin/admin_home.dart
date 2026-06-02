import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/shimmer_loader.dart';
import '../auth/login_screen.dart';
import 'generate_barcode.dart';
import 'data_user.dart';
import 'data_absensi.dart';
import 'laporan_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  UserModel? _admin;
  bool _isLoading = true;
  int _totalMahasiswa = 0;
  int _totalAbsensi = 0;
  final _db = RealtimeDatabaseService();

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  void _loadSession() async {
    final session = await AuthService().getUserSession();
    if (!mounted) return;

    // Session null or invalid role → redirect to login immediately
    if (session == null || !session.isAdmin) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
      return;
    }

    setState(() {
      _admin = session;
      _isLoading = false;
    });
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final stats = await _db.getAdminStats();
      if (!mounted) return;
      setState(() {
        _totalMahasiswa = stats['mahasiswa'] ?? 0;
        _totalAbsensi = stats['absensi'] ?? 0;
      });
    } catch (_) {
      // Stats are non-critical — silently ignored, dashboard still usable
    }
  }

  void _handleLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Keluar dari Panel Admin?',
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda akan keluar dari sesi admin.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Ya, Keluar',
              gradientColors: [AppColors.error, const Color(0xFFDC2626)],
              onPressed: () async {
                await AuthService().logout();
                if (ctx.mounted) {
                  Navigator.pushAndRemoveUntil(
                    ctx,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            GhostButton(label: 'Batal', onPressed: () => Navigator.pop(ctx)),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _admin == null) {
      return const Scaffold(body: DashboardSkeleton());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _AdminDashboard(
        admin: _admin!,
        totalMahasiswa: _totalMahasiswa,
        totalAbsensi: _totalAbsensi,
        onRefresh: _fetchStats,
        onNavigate: (i) => setState(() => _currentIndex = i),
        onLogout: _handleLogout,
      ),
      GenerateBarcodeScreen(admin: _admin!),
      const DataUserScreen(),
      const DataAbsensiScreen(),
      const LaporanScreen(),
    ];

    final navItems = [
      _AdminNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
      _AdminNavItem(icon: Icons.qr_code_2_rounded, label: 'QR Code'),
      _AdminNavItem(icon: Icons.people_rounded, label: 'Mahasiswa'),
      _AdminNavItem(icon: Icons.history_edu_rounded, label: 'Absensi'),
      _AdminNavItem(icon: Icons.bar_chart_rounded, label: 'Laporan'),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: List.generate(navItems.length, (i) {
                final isSelected = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 44 : 36,
                          height: isSelected ? 32 : 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            navItems[i].icon,
                            size: 20,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          navItems[i].label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem {
  final IconData icon;
  final String label;
  const _AdminNavItem({required this.icon, required this.label});
}

// ── Admin Dashboard Tab ───────────────────────────────────────────────────────

class _AdminDashboard extends StatelessWidget {
  final UserModel admin;
  final int totalMahasiswa;
  final int totalAbsensi;
  final VoidCallback onRefresh;
  final void Function(int) onNavigate;
  final VoidCallback onLogout;

  const _AdminDashboard({
    required this.admin,
    required this.totalMahasiswa,
    required this.totalAbsensi,
    required this.onRefresh,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 56, AppSpacing.lg, AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.xxl),
                  bottomRight: Radius.circular(AppRadius.xxl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panel Admin',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              admin.nama,
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              admin.email,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Tooltip(
                        message: 'Keluar',
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: InkWell(
                            onTap: onLogout,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                ),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            admin.nama.isNotEmpty
                                ? admin.nama[0].toUpperCase()
                                : 'A',
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Stats row inside header
                  Row(
                    children: [
                      _HeaderStat(
                        label: 'Mahasiswa',
                        value: '$totalMahasiswa',
                        icon: Icons.people_rounded,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.2),
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                      ),
                      _HeaderStat(
                        label: 'Total Absensi',
                        value: '$totalAbsensi',
                        icon: Icons.assignment_turned_in_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Quick Actions ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Menu Utama'),
                  const SizedBox(height: AppSpacing.md),
                  _AdminActionCard(
                    title: 'Generate QR Absensi',
                    subtitle:
                        'Buat sesi QR Code baru dengan masa berlaku terbatas',
                    icon: Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () => onNavigate(1),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdminActionCard(
                    title: 'Monitoring Absensi',
                    subtitle:
                        'Lihat data kehadiran mahasiswa secara realtime',
                    icon: Icons.history_edu_rounded,
                    color: AppColors.success,
                    isDark: isDark,
                    onTap: () => onNavigate(3),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdminActionCard(
                    title: 'Data Mahasiswa',
                    subtitle: 'Kelola daftar mahasiswa terdaftar',
                    icon: Icons.people_rounded,
                    color: AppColors.info,
                    isDark: isDark,
                    onTap: () => onNavigate(2),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _AdminActionCard(
                    title: 'Laporan Rekapitulasi',
                    subtitle: 'Ringkasan kehadiran per mahasiswa',
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.warning,
                    isDark: isDark,
                    onTap: () => onNavigate(4),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
