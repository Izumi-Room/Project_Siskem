import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_logo.dart';
import '../../utils/lottie_assets.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/shimmer_loader.dart';
import '../auth/login_screen.dart';
import 'scan_screen.dart';
import 'riwayat_screen.dart';
import 'profil_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  UserModel? _currentUser;
  bool _isLoading = true;
  final _databaseService = RealtimeDatabaseService();

  // Stats
  int _hadirCount = 0;
  int _sakitCount = 0;
  int _izinCount = 0;
  bool _sudahAbsenHariIni = false;

  // Nav animation
  late AnimationController _navController;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadUserSession();
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  void _loadUserSession() async {
    try {
      final session = await AuthService().getUserSession();
      if (!mounted) return;
      if (session == null) {
        // Session expired — redirect to login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
        );
        return;
      }
      setState(() {
        _currentUser = session;
        _isLoading = false;
      });
      _fetchStats();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _fetchStats() async {
    try {
      final stats = await _databaseService.getUserStats(_currentUser!.uid);
      final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final sudahAbsen =
          await _databaseService.hasAttendanceToday(_currentUser!.uid, tanggal);
      if (!mounted) return;
      setState(() {
        _hadirCount = stats['hadir'] ?? 0;
        _sakitCount = stats['sakit'] ?? 0;
        _izinCount = stats['izin'] ?? 0;
        _sudahAbsenHariIni = sudahAbsen;
      });
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentUser == null) {
      return const Scaffold(body: DashboardSkeleton());
    }

    final pages = [
      _DashboardTab(
        user: _currentUser!,
        hadirCount: _hadirCount,
        sakitCount: _sakitCount,
        izinCount: _izinCount,
        sudahAbsen: _sudahAbsenHariIni,
        greeting: _getGreeting(),
        onRefresh: _fetchStats,
        onScanTap: () => setState(() => _currentIndex = 1),
      ),
      ScanScreen(
        user: _currentUser!,
        onAttendanceSuccess: () {
          _fetchStats();
          setState(() => _currentIndex = 2);
        },
      ),
      RiwayatScreen(user: _currentUser!),
      ProfilScreen(user: _currentUser!),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
      _NavItem(icon: Icons.history_rounded, label: 'Riwayat'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = _currentIndex == i;
              final isScan = i == 1;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentIndex = i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isScan)
                          // Scan button — elevated FAB style
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          )
                        else
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
                              items[i].icon,
                              size: 22,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textTertiary),
                            ),
                          ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
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
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ════════════════════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ════════════════════════════════════════════════════════════════════════════

class _DashboardTab extends StatefulWidget {
  final UserModel user;
  final int hadirCount;
  final int sakitCount;
  final int izinCount;
  final bool sudahAbsen;
  final String greeting;
  final VoidCallback onRefresh;
  final VoidCallback onScanTap;

  const _DashboardTab({
    required this.user,
    required this.hadirCount,
    required this.sakitCount,
    required this.izinCount,
    required this.sudahAbsen,
    required this.greeting,
    required this.onRefresh,
    required this.onScanTap,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _dbService = RealtimeDatabaseService();
  bool _isSubmitting = false;

  // ── Manual Sakit/Izin submission ─────────────────────────────────────────
  void _showManualSubmitDialog(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasonCtrl = TextEditingController();
    final isWarning = status == 'Sakit';
    final color = isWarning ? AppColors.warning : AppColors.info;
    final icon = isWarning
        ? Icons.medical_services_rounded
        : Icons.event_note_rounded;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Lapor $status',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Berikan keterangan singkat sebagai alasan ${status.toLowerCase()} hari ini.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                maxLength: 200,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      status == 'Sakit'
                          ? 'Contoh: Demam dan batuk...'
                          : 'Contoh: Ada keperluan keluarga...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.cardDark
                      : AppColors.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final reason = reasonCtrl.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Mohon isi keterangan terlebih dahulu.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      await _submitManual(status, reason);
                    },
              child: Text(
                'Kirim $status',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitManual(String status, String reason) async {
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Guard: check again (race condition safety)
    final alreadyDone = await _dbService.hasAttendanceToday(
      widget.user.uid,
      tanggal,
    );
    if (alreadyDone) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah melakukan absensi hari ini.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    try {
      await _dbService.submitManualAttendance(
        user: widget.user,
        status: status,
        tanggal: tanggal,
        reason: reason,
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onRefresh();
        _showSubmitSuccessSheet(status);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSubmitSuccessSheet(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWarning = status == 'Sakit';
    final color = isWarning ? AppColors.warning : AppColors.info;
    final icon = isWarning
        ? Icons.medical_services_rounded
        : Icons.event_note_rounded;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              '$status Berhasil Dicatat',
              style: AppTextStyles.headlineMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keterangan $status hari ini telah tersimpan.\nAdmin dapat melihat laporan Anda.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Oke, Mengerti',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.hadirCount + widget.sakitCount + widget.izinCount;
    final pct = total > 0 ? widget.hadirCount / total : 0.0;

    return RefreshIndicator(
          onRefresh: () async => widget.onRefresh(),
          color: AppColors.primary,
          child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            backgroundColor:
                isDark ? AppColors.bgDark : AppColors.bgLight,
            elevation: 0,
            title: Row(
              children: [
                const AppLogo(size: 36),
                const SizedBox(width: 10),
                Text(
                  'Absensi',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
                onPressed: widget.onRefresh,
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ────────────────────────────────────────
                  _buildGreeting(isDark),
                  const SizedBox(height: AppSpacing.md),

                  // ── Status Card (main hero) ──────────────────────────
                  _buildStatusCard(isDark),
                  const SizedBox(height: AppSpacing.md),

                  // ── Manual Submission (Sakit/Izin) ───────────────────
                  if (!widget.sudahAbsen) _buildManualSubmissionCard(isDark),
                  if (!widget.sudahAbsen) const SizedBox(height: AppSpacing.md),

                  // ── Stats Row ────────────────────────────────────────
                  _buildStatsRow(isDark),
                  const SizedBox(height: AppSpacing.md),

                  // ── Attendance Progress ──────────────────────────────
                  _buildProgressCard(isDark, pct, total),
                  const SizedBox(height: AppSpacing.md),

                  // ── Quick Actions ────────────────────────────────────
                  _buildQuickActions(isDark),
                  const SizedBox(height: 100), // bottom nav clearance
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.greeting},',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.user.nama.split(' ').first,
                style: AppTextStyles.displayMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                'NIM ${widget.user.nim ?? '-'}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Avatar
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.user.nama.isNotEmpty ? widget.user.nama[0].toUpperCase() : 'M',
              style: AppTextStyles.headlineLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return AppCard(
      padding: EdgeInsets.zero,
      hasBorder: false,
      shadows: [
        BoxShadow(
          color: (widget.sudahAbsen ? AppColors.success : AppColors.primary)
              .withValues(alpha: 0.2),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          gradient: widget.sudahAbsen
              ? AppColors.successGradient
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sudahAbsen
                        ? 'Absensi Hari Ini'
                        : 'Status Absensi',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.sudahAbsen ? 'Sudah Hadir ✓' : 'Belum Absen',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.sudahAbsen
                        ? 'Kehadiran Anda telah tercatat hari ini'
                        : 'Jangan lupa melakukan absensi hari ini',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  if (!widget.sudahAbsen) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: widget.onScanTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Scan Sekarang',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 100,
              height: 100,
              child: Lottie.asset(
                widget.sudahAbsen
                    ? LottieAssets.dashboardSuccess
                    : LottieAssets.dashboardReminder,
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (_, __, ___) => Icon(
                  widget.sudahAbsen
                      ? Icons.check_circle_rounded
                      : Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        _StatCard(
          label: 'Hadir',
          value: widget.hadirCount,
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Sakit',
          value: widget.sakitCount,
          color: AppColors.warning,
          icon: Icons.medical_services_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Izin',
          value: widget.izinCount,
          color: AppColors.info,
          icon: Icons.event_note_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildProgressCard(bool isDark, double pct, int total) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ringkasan Kehadiran',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
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
            height: 10,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.hadirCount} dari $total pertemuan',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                pct >= 0.75
                    ? 'Kehadiran Baik'
                    : pct >= 0.5
                        ? 'Perlu Ditingkatkan'
                        : 'Kehadiran Rendah',
                style: AppTextStyles.labelSmall.copyWith(
                  color: pct >= 0.75
                      ? AppColors.success
                      : pct >= 0.5
                          ? AppColors.warning
                          : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualSubmissionCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.sick_outlined,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tidak Bisa Hadir Hari Ini?',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Lapor keterangan Sakit atau Izin tanpa perlu scan QR.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isSubmitting ? null : () => _showManualSubmitDialog('Sakit'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.medical_services_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sakit',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _isSubmitting ? null : () => _showManualSubmitDialog('Izin'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_note_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Izin',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isSubmitting) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Panduan Cepat'),
        const SizedBox(height: 12),
        _QuickActionCard(
          step: '1',
          title: 'Minta QR Code dari Admin',
          subtitle: 'Admin akan menampilkan QR Code sesi absensi',
          icon: Icons.admin_panel_settings_rounded,
          color: AppColors.primary,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _QuickActionCard(
          step: '2',
          title: 'Tap tombol Scan di bawah',
          subtitle: 'Arahkan kamera ke QR Code absensi',
          icon: Icons.qr_code_scanner_rounded,
          color: AppColors.secondary,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _QuickActionCard(
          step: '3',
          title: 'Absensi Tercatat Otomatis',
          subtitle: 'Data tersimpan aman dengan enkripsi Triple DES',
          icon: Icons.verified_rounded,
          color: AppColors.success,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: AppTextStyles.headlineLarge.copyWith(
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
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _QuickActionCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                step,
                style: AppTextStyles.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
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
          Icon(icon, color: color, size: 20),
        ],
      ),
    );
  }
}
