import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/realtime_database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/shimmer_loader.dart';

class DataUserScreen extends StatefulWidget {
  const DataUserScreen({Key? key}) : super(key: key);

  @override
  State<DataUserScreen> createState() => _DataUserScreenState();
}

class _DataUserScreenState extends State<DataUserScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _isLoading = true;
  String _errorMsg = '';
  final _db = RealtimeDatabaseService();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? List.from(_users)
            : _users.where((u) {
                return u.nama.toLowerCase().contains(q) ||
                    (u.nim?.toLowerCase().contains(q) ?? false) ||
                    u.email.toLowerCase().contains(q);
              }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final data = await _db.getUsers();
      setState(() {
        _users = data;
        _filtered = List.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMsg = 'Gagal mengambil data mahasiswa.';
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
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Mahasiswa',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_users.length} mahasiswa terdaftar',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _searchCtrl,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, NIM, atau email...',
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
                      suffixIcon: _searchCtrl.text.isNotEmpty
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
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
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
            Text(
              _errorMsg,
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
                onPressed: _fetchUsers,
                icon: Icons.refresh_rounded,
              ),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mahasiswa tidak ditemukan',
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
      onRefresh: _fetchUsers,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, 100),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final user = _filtered[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        user.nama.isNotEmpty
                            ? user.nama[0].toUpperCase()
                            : 'M',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
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
                          user.nama,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIM: ${user.nim ?? '-'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          user.email,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: 'MHS',
                    color: AppColors.info,
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
