import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../services/barcode_service.dart';
import '../../services/realtime_database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class GenerateBarcodeScreen extends StatefulWidget {
  final UserModel admin;
  const GenerateBarcodeScreen({Key? key, required this.admin}) : super(key: key);

  @override
  State<GenerateBarcodeScreen> createState() => _GenerateBarcodeScreenState();
}

class _GenerateBarcodeScreenState extends State<GenerateBarcodeScreen>
    with SingleTickerProviderStateMixin {
  final _barcodeService = BarcodeService();
  final _databaseService = RealtimeDatabaseService();

  // ── Tab ──────────────────────────────────────────────────────────────────
  late TabController _tabController;

  // ── QR (Hadir) ───────────────────────────────────────────────────────────
  String _location = 'Ruang Kelas';
  int _durationMinutes = 15;
  String? _generatedQrId;
  bool _isLoadingQr = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isExpired = false;

  // ── Manual (Sakit / Izin) ────────────────────────────────────────────────
  List<UserModel> _students = [];
  bool _isLoadingStudents = false;
  UserModel? _selectedStudent;
  String _manualStatus = 'Sakit';
  final _reasonController = TextEditingController();
  bool _isSubmittingManual = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadStudents();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _loadStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final list = await _databaseService.getUsers(mahasiswaOnly: true);
      if (mounted) setState(() { _students = list; _isLoadingStudents = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  String _formatCountdown(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.all(AppSpacing.md),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.all(AppSpacing.md),
    ));
  }

  // ── QR Generate ──────────────────────────────────────────────────────────

  void _handleGenerateQR() async {
    setState(() { _isLoadingQr = true; _generatedQrId = null; _isExpired = false; });
    _countdownTimer?.cancel();

    try {
      final result = await _barcodeService.generateNewSession(
        adminId: widget.admin.id,
        adminUid: widget.admin.uid,
        status: 'Hadir',
        location: _location,
        durationMinutes: _durationMinutes,
      );
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _generatedQrId = result['qrId'];
          _remainingSeconds = _durationMinutes * 60;
          _isLoadingQr = false;
        });
        _startCountdown();
        _showSuccess('QR Code Hadir berhasil dibuat!');
      } else {
        setState(() => _isLoadingQr = false);
        _showError('Gagal menyimpan sesi QR ke Firebase.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingQr = false);
      _showError('Error: $e');
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isExpired = true;
          timer.cancel();
          if (_generatedQrId != null) {
            _databaseService.deactivateQrCode(_generatedQrId!);
          }
        }
      });
    });
  }

  // ── Manual Submit (Sakit/Izin) ───────────────────────────────────────────

  void _handleManualSubmit() async {
    if (_selectedStudent == null) {
      _showError('Pilih mahasiswa terlebih dahulu.');
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _showError('Isi keterangan terlebih dahulu.');
      return;
    }

    setState(() => _isSubmittingManual = true);
    final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Cek apakah mahasiswa sudah absen hari ini
    final alreadyAbsen = await _databaseService.hasAttendanceToday(
      _selectedStudent!.uid, tanggal,
    );

    if (alreadyAbsen) {
      if (!mounted) return;
      setState(() => _isSubmittingManual = false);
      _showError('${_selectedStudent!.nama} sudah absen hari ini.');
      return;
    }

    try {
      await _databaseService.submitManualAttendance(
        user: _selectedStudent!,
        status: _manualStatus,
        tanggal: tanggal,
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      // Save name BEFORE nulling _selectedStudent
      final studentName = _selectedStudent!.nama;
      final submittedStatus = _manualStatus;
      setState(() {
        _isSubmittingManual = false;
        _selectedStudent = null;
        _reasonController.clear();
      });
      _showSuccess('$submittedStatus untuk $studentName berhasil dicatat.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingManual = false);
      _showError('Gagal: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelola Absensi',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'QR untuk Hadir · Formulir untuk Sakit & Izin',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // ── Tab Bar ───────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      labelStyle: AppTextStyles.titleMedium,
                      unselectedLabelStyle: AppTextStyles.bodyMedium,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.qr_code_2_rounded, size: 18),
                          text: 'QR Hadir',
                        ),
                        Tab(
                          icon: Icon(Icons.assignment_outlined, size: 18),
                          text: 'Sakit / Izin',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Tab Views ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQrTab(isDark),
                  _buildManualTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: QR Hadir ───────────────────────────────────────────────────────

  Widget _buildQrTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        children: [
          // Info banner: QR hanya untuk Hadir
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR Code hanya digunakan untuk absensi Hadir. '
                    'Untuk Sakit & Izin gunakan tab "Sakit / Izin".',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Lokasi ──────────────────────────────────────────────
                Text('LOKASI ABSENSI',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _location,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration(isDark,
                      icon: Icons.location_on_outlined,
                      hint: 'Contoh: Ruang Kelas A, Lab Komputer...'),
                  onChanged: (val) =>
                      _location = val.trim().isEmpty ? 'Lokasi' : val,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Durasi ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DURASI EXPIRED',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          letterSpacing: 1,
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$_durationMinutes menit',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$_durationMinutes mnt',
                    onChanged: (val) =>
                        setState(() => _durationMinutes = val.toInt()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                PrimaryButton(
                  label: 'Generate QR Hadir',
                  isLoading: _isLoadingQr,
                  icon: Icons.qr_code_2_rounded,
                  onPressed: _isLoadingQr ? null : _handleGenerateQR,
                ),
              ],
            ),
          ),

          if (_generatedQrId != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildQrResult(isDark),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Tab 2: Manual Sakit / Izin ────────────────────────────────────────────

  Widget _buildManualTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gunakan formulir ini untuk mencatat absensi '
                    'Sakit atau Izin mahasiswa tanpa QR Code.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status toggle ────────────────────────────────────────
                Text('STATUS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatusToggle(
                      label: 'Sakit',
                      icon: Icons.medical_services_rounded,
                      color: AppColors.warning,
                      isSelected: _manualStatus == 'Sakit',
                      onTap: () => setState(() => _manualStatus = 'Sakit'),
                    ),
                    const SizedBox(width: 10),
                    _StatusToggle(
                      label: 'Izin',
                      icon: Icons.event_note_rounded,
                      color: AppColors.info,
                      isSelected: _manualStatus == 'Izin',
                      onTap: () => setState(() => _manualStatus = 'Izin'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Pilih Mahasiswa ──────────────────────────────────────
                Text('MAHASISWA',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 8),
                _isLoadingStudents
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2),
                        ),
                      )
                    : DropdownButtonFormField<UserModel>(
                        value: _selectedStudent,
                        hint: Text(
                          'Pilih mahasiswa...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary,
                          ),
                        ),
                        dropdownColor:
                            isDark ? AppColors.cardDark : AppColors.cardLight,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration(isDark,
                            icon: Icons.person_search_rounded),
                        isExpanded: true,
                        items: _students.map((student) {
                          return DropdownMenuItem<UserModel>(
                            value: student,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(student.nama,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  'NIM ${student.nim ?? '-'}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedStudent = val),
                      ),
                const SizedBox(height: AppSpacing.md),

                // ── Keterangan ────────────────────────────────────────────
                Text('KETERANGAN',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  maxLength: 200,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: _manualStatus == 'Sakit'
                        ? 'Contoh: Demam tinggi, tidak dapat hadir...'
                        : 'Contoh: Keperluan keluarga mendesak...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
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
                      borderSide: BorderSide(
                        color: _manualStatus == 'Sakit'
                            ? AppColors.warning
                            : AppColors.info,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Tanggal info ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Submit Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _manualStatus == 'Sakit'
                          ? AppColors.warning
                          : AppColors.info,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSubmittingManual ? null : _handleManualSubmit,
                    icon: _isSubmittingManual
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(
                            _manualStatus == 'Sakit'
                                ? Icons.medical_services_rounded
                                : Icons.event_note_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                    label: Text(
                      _isSubmittingManual
                          ? 'Menyimpan...'
                          : 'Simpan Absensi $_manualStatus',
                      style: const TextStyle(
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── QR Result ─────────────────────────────────────────────────────────────

  Widget _buildQrResult(bool isDark) {
    final isActive = !_isExpired && _remainingSeconds > 0;
    final statusColor = isActive ? AppColors.success : AppColors.error;

    return AppCard(
      hasBorder: false,
      shadows: [
        BoxShadow(
          color: statusColor.withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: isActive ? 'QR AKTIF' : 'KEDALUWARSA',
                color: statusColor,
                icon: isActive
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
              ),
              if (isActive)
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: _remainingSeconds < 60
                          ? AppColors.error
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCountdown(_remainingSeconds),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: _remainingSeconds < 60
                            ? AppColors.error
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary),
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_location  ·  Hadir',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── QR Code ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ColorFiltered(
              colorFilter: isActive
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
              child: QrImageView(
                data: _generatedQrId!,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primaryDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          if (_isExpired) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sesi telah berakhir. Buat sesi baru.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          Text(
            'QR ID (FIREBASE KEY)',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : const Color(0xFFF0F1FF),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: SelectableText(
              _generatedQrId!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontFamily: 'monospace',
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Security info ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _SecurityRow(
                  icon: Icons.security_rounded,
                  text: 'Validasi dilakukan di Firebase (server-side)',
                ),
                const SizedBox(height: 6),
                _SecurityRow(
                  icon: Icons.block_rounded,
                  text: 'Setiap mahasiswa hanya bisa absen 1x per hari',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Decoration ──────────────────────────────────────────────────────

  InputDecoration _inputDecoration(bool isDark,
      {required IconData icon, String? hint}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color:
            isDark ? AppColors.textSecondaryDark : AppColors.textTertiary,
      ),
      filled: true,
      fillColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
    );
  }
}

// ── Status Toggle Widget ───────────────────────────────────────────────────

class _StatusToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : (isDark ? AppColors.surfaceDark : AppColors.bgLight),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected
                      ? color
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textTertiary),
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.titleMedium.copyWith(
                  color: isSelected
                      ? color
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Security Row Widget ────────────────────────────────────────────────────

class _SecurityRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SecurityRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.success),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
