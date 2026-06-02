import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../utils/app_logo.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────────────────────
  late AnimationController _masterController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _buttonController;

  // ── Staggered Animations ───────────────────────────────────────────────────
  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _illustrationFade;
  late Animation<Offset> _illustrationSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _cardsSlide;
  late Animation<double> _buttonsFade;
  late Animation<Offset> _buttonsSlide;

  // ── Continuous Animations ──────────────────────────────────────────────────
  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _masterController.forward();
  }

  void _setupAnimations() {
    // Master stagger controller (2.4s total)
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Continuous float (up/down)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Continuous glow pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Button press feedback
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    // ── Staggered intervals ────────────────────────────────────────────────
    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.1, 0.45, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.1, 0.35, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
    ));

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOut),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.38, 0.65, curve: Curves.easeOutCubic),
    ));

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.38, 0.62, curve: Curves.easeOut),
      ),
    );

    _illustrationFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.45, 0.72, curve: Curves.easeOut),
      ),
    );

    _illustrationSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.45, 0.72, curve: Curves.easeOutCubic),
    ));

    _cardsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.58, 0.82, curve: Curves.easeOut),
      ),
    );

    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.58, 0.82, curve: Curves.easeOutCubic),
    ));

    _buttonsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
    ));

    // Continuous animations
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToRegister() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      // Push register on top of login
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFEEF2FF),
      body: AnimatedBuilder(
        animation: _masterController,
        builder: (context, _) {
          return FadeTransition(
            opacity: _bgFade,
            child: Stack(
              children: [
                // ── Dynamic Background ───────────────────────────────────
                _buildBackground(size, isDark),
                // ── Main Content ─────────────────────────────────────────
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(height: 32),
                                _buildTopSection(isDark),
                                const SizedBox(height: 20),
                                _buildIllustration(isDark),
                                const SizedBox(height: 20),
                                _buildFeatureCards(isDark),
                                const SizedBox(height: 24),
                                _buildButtons(isDark),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Background with animated gradient orbs ──────────────────────────────
  Widget _buildBackground(Size size, bool isDark) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) {
        return Stack(
          children: [
            // Primary orb – top right
            Positioned(
              top: -size.height * 0.12,
              right: -size.width * 0.15,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(
                          alpha: isDark ? 0.35 * _glowAnim.value : 0.25 * _glowAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Secondary orb – bottom left
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.85,
                height: size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF818CF8).withValues(
                          alpha: isDark ? 0.25 * _glowAnim.value : 0.18 * _glowAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Accent orb – center
            Positioned(
              top: size.height * 0.35,
              left: size.width * 0.3,
              child: Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22C55E).withValues(
                          alpha: isDark ? 0.12 * _glowAnim.value : 0.08 * _glowAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Top Section: Logo + Title + Subtitle ────────────────────────────────
  Widget _buildTopSection(bool isDark) {
    return Column(
      children: [
        // Logo with glow + float
        FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(
            scale: _logoScale,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value * 0.5),
                  child: const AppLogo(size: 120, showGlow: true),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Title
        SlideTransition(
          position: _titleSlide,
          child: FadeTransition(
            opacity: _titleFade,
            child: Text(
              'Absensi Triple DES',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: isDark ? Colors.white : const Color(0xFF312E81),
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Subtitle
        SlideTransition(
          position: _subtitleSlide,
          child: FadeTransition(
            opacity: _subtitleFade,
            child: Text(
              'Sistem Absensi Digital Modern untuk\nKehadiran yang Cepat, Akurat, dan Real-Time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Premium Illustration ─────────────────────────────────────────────────
  Widget _buildIllustration(bool isDark) {
    return SlideTransition(
      position: _illustrationSlide,
      child: FadeTransition(
        opacity: _illustrationFade,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _floatAnim.value * 0.7),
              child: _GlassCard(
                isDark: isDark,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Phone mockup
                    _PhoneMockup(isDark: isDark),
                    const SizedBox(width: 16),
                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IllustrationBadge(
                            icon: Icons.location_on_rounded,
                            label: 'GPS Terverifikasi',
                            color: const Color(0xFF22C55E),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _IllustrationBadge(
                            icon: Icons.access_time_rounded,
                            label: 'Check-in Real-Time',
                            color: const Color(0xFF6366F1),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _IllustrationBadge(
                            icon: Icons.check_circle_rounded,
                            label: 'Akurasi 99.9%',
                            color: const Color(0xFF818CF8),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _IllustrationBadge(
                            icon: Icons.bar_chart_rounded,
                            label: 'Laporan Otomatis',
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Feature Cards Grid ───────────────────────────────────────────────────
  Widget _buildFeatureCards(bool isDark) {
    final features = [
      _FeatureData(
        icon: Icons.wifi_tethering_rounded,
        title: 'Absensi\nReal-Time',
        color: const Color(0xFF6366F1),
      ),
      _FeatureData(
        icon: Icons.my_location_rounded,
        title: 'Validasi\nLokasi GPS',
        color: const Color(0xFF22C55E),
      ),
      _FeatureData(
        icon: Icons.history_rounded,
        title: 'Riwayat\nLengkap',
        color: const Color(0xFF818CF8),
      ),
      _FeatureData(
        icon: Icons.assessment_rounded,
        title: 'Laporan\nOtomatis',
        color: const Color(0xFFF59E0B),
      ),
    ];

    return SlideTransition(
      position: _cardsSlide,
      child: FadeTransition(
        opacity: _cardsFade,
        child: Row(
          children: features
              .map((f) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _FeatureCard(feature: f, isDark: isDark),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── CTA Buttons ──────────────────────────────────────────────────────────
  Widget _buildButtons(bool isDark) {
    return SlideTransition(
      position: _buttonsSlide,
      child: FadeTransition(
        opacity: _buttonsFade,
        child: Column(
          children: [
            // Primary CTA → Register
            _PrimaryButton(
              label: 'Mulai Sekarang',
              onPressed: _navigateToRegister,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            // Secondary CTA → Login
            _SecondaryButton(
              label: 'Masuk',
              onPressed: _navigateToLogin,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            // Trust badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Aman & Terenkripsi · Firebase Secured',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ════════════════════════════════════════════════════════════════════════════

/// Glassmorphism card container
class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.75),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFF6366F1).withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : const Color(0xFF6366F1).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Phone mockup illustration
class _PhoneMockup extends StatelessWidget {
  final bool isDark;
  const _PhoneMockup({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF312E81), const Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Notch
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          // Dashboard mini preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Mini bar chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [14.0, 20.0, 12.0, 18.0, 16.0]
                      .map((h) => Container(
                            width: 5,
                            height: h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF818CF8)
                                  .withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            Icons.fingerprint,
            color: Colors.white.withValues(alpha: 0.5),
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// Illustration badge row item
class _IllustrationBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _IllustrationBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

/// Feature data model
class _FeatureData {
  final IconData icon;
  final String title;
  final Color color;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.color,
  });
}

/// Individual feature card
class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final bool isDark;

  const _FeatureCard({required this.feature, required this.isDark});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _hoverController.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _hoverController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _hoverController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.isDark
                ? const Color(0xFF1E293B).withValues(alpha: _isPressed ? 0.9 : 0.6)
                : Colors.white.withValues(alpha: _isPressed ? 1.0 : 0.85),
            border: Border.all(
              color: _isPressed
                  ? widget.feature.color.withValues(alpha: 0.5)
                  : widget.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : widget.feature.color.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.feature.color.withValues(
                    alpha: _isPressed ? 0.25 : 0.1),
                blurRadius: _isPressed ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.feature.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.feature.icon,
                  color: widget.feature.color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.feature.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? Colors.white
                      : const Color(0xFF1E293B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary gradient CTA button
class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDark;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isDark,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Mulai Sekarang',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined button
class _SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDark;

  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.isDark,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isHovered = true);
        _ctrl.forward();
      },
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isHovered = false);
        _ctrl.reverse();
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _isHovered
                ? const Color(0xFF6366F1).withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: _isHovered ? 0.3 : 0.15)
                  : const Color(0xFF6366F1).withValues(alpha: _isHovered ? 0.6 : 0.35),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF6366F1),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
