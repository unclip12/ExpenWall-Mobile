import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home/home_screen.dart';
import 'wallet_painter.dart';

// ═══════════════════════════════════════════════════════════════════
// ExpenWall Wallet Splash — 5-Stage Animation
//
//  Stage 1  (0 → 700ms)   Wallet scales + fades in, then pulses
//  Stage 2  (700 → 1900ms) Flap rotates open (leather 3D perspective)
//  Stage 3  (1900 → 2600ms) Cash & cards peek up from wallet slot
//  Stage 4  (2600 → 3500ms) Items fly out — fan spread with bounce
//  Stage 5  (3500 → 4800ms) Items morph & land as dashboard widgets
// ═══════════════════════════════════════════════════════════════════

class WalletSplashScreen extends StatefulWidget {
  const WalletSplashScreen({Key? key}) : super(key: key);

  @override
  State<WalletSplashScreen> createState() => _WalletSplashScreenState();
}

class _WalletSplashScreenState extends State<WalletSplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ───────────────────────────────────────────────
  late final AnimationController _enterCtrl;  // Stage 1a: wallet appears
  late final AnimationController _pulseCtrl;  // Stage 1b: closed wallet breathes
  late final AnimationController _openCtrl;   // Stage 2: flap opens
  late final AnimationController _peekCtrl;   // Stage 3: cards/cash peek
  late final AnimationController _flyCtrl;    // Stage 4: items fly out
  late final AnimationController _dashCtrl;   // Stage 5: dashboard lands

  // ── Derived animations ────────────────────────────────────────
  late final Animation<double> _enterScale;
  late final Animation<double> _enterOpacity;
  late final Animation<double> _pulseScale;
  late final Animation<double> _flapOpen;
  late final Animation<double> _peek;
  late final Animation<double> _fly;
  late final Animation<double> _dash;
  late final Animation<double> _walletFade;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initAnimations();
    _runSequence();
  }

  // ── Setup ─────────────────────────────────────────────────────
  void _initControllers() {
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _openCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _peekCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _flyCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
    _dashCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  }

  void _initAnimations() {
    // Wallet pops in from 0.25 scale with elastic bounce
    _enterScale = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut),
    );
    _enterOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: const Interval(0.0, 0.4)),
    );

    // Breathing pulse: 1.0 → 1.07 → 1.0
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.07), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.07, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Flap swings open with slight overshoot
    _flapOpen = CurvedAnimation(parent: _openCtrl, curve: Curves.easeOutBack);

    // Cards ease out of slot
    _peek = CurvedAnimation(parent: _peekCtrl, curve: Curves.easeOutCubic);

    // Items bounce out
    _fly = CurvedAnimation(parent: _flyCtrl, curve: Curves.easeOutBack);

    // Dashboard morphs in with ease
    _dash = CurvedAnimation(parent: _dashCtrl, curve: Curves.easeInOutCubic);

    // Wallet fades out as dashboard arrives (first 40% of dash animation)
    _walletFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _dashCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  // ── Sequence ─────────────────────────────────────────────────
  Future<void> _runSequence() async {
    // Stage 1a — wallet enters
    await _enterCtrl.forward();
    if (!mounted) return;

    // Stage 1b — pulse 2× (breathe in and out)
    _pulseCtrl.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _pulseCtrl.stop();
    await _pulseCtrl.animateTo(0.0, duration: const Duration(milliseconds: 150));
    if (!mounted) return;

    // Stage 2 — flap opens
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    await _openCtrl.forward();
    if (!mounted) return;

    // Stage 3 — cards & cash peek out
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    await _peekCtrl.forward();
    if (!mounted) return;

    // Stage 4 — fly out fan
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    await _flyCtrl.forward();
    if (!mounted) return;

    // Stage 5 — morph to dashboard
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _dashCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1550));
    if (!mounted) return;

    // Navigate to home
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    _openCtrl.dispose();
    _peekCtrl.dispose();
    _flyCtrl.dispose();
    _dashCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF07071A),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _enterCtrl, _pulseCtrl, _openCtrl,
          _peekCtrl,  _flyCtrl,  _dashCtrl,
        ]),
        builder: (context, _) {
          final walletVis = (_walletFade.value * _enterOpacity.value).clamp(0.0, 1.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Dark radial background ──────────────────────
              _buildBackground(size),

              // ── App name (fades with wallet) ────────────────
              _buildAppName(size, walletVis),

              // ── Leather wallet (back body only) ────────────
              Opacity(
                opacity: walletVis,
                child: Transform.scale(
                  scale: _enterScale.value,
                  child: CustomPaint(
                    size: size,
                    painter: WalletPainter(
                      openProgress: _flapOpen.value,
                      pulseScale: _pulseScale.value,
                      primaryColor: const Color(0xFF3D2314),
                      accentColor: const Color(0xFF6B3D22),
                    ),
                  ),
                ),
              ),

              // ── Flying items (z-order: cash behind cards) ───
              // Item 2: Cash bill (green)
              _buildFlyingItem(
                size: size, index: 2, isCash: true,
                color: const Color(0xFF2D7A3A),
              ),
              // Item 1: Blue Visa card
              _buildFlyingItem(
                size: size, index: 1, isCash: false,
                color: const Color(0xFF3A4DB7),
              ),
              // Item 0: Gold card (topmost)
              _buildFlyingItem(
                size: size, index: 0, isCash: false,
                color: const Color(0xFFC8960C),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────
  Widget _buildBackground(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 0.05),
          radius: 1.25,
          colors: [Color(0xFF10103A), Color(0xFF07071A)],
        ),
      ),
    );
  }

  // ── App name ────────────────────────────────────────────────
  Widget _buildAppName(Size size, double opacity) {
    return Positioned(
      top: size.height * 0.16,
      left: 0, right: 0,
      child: Opacity(
        opacity: opacity,
        child: Center(
          child: Text(
            'ExpenWall',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 5,
              shadows: [
                Shadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.65),
                  blurRadius: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Flying Item (card or cash) ──────────────────────────────
  Widget _buildFlyingItem({
    required Size size,
    required int index,
    required bool isCash,
    required Color color,
  }) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Natural item dimensions
    const cardW = 300.0;  const cardH = 185.0;
    const cashW = 285.0;  const cashH = 148.0;
    final itemW = isCash ? cashW : cardW;
    final itemH = isCash ? cashH : cardH;

    // ── Phase positions ────────────────────────────────────────

    // PEEK: items rise slightly from wallet slot (staggered depth)
    final double peekY = cy - 10.0 - (index * 18.0);
    final double peekScale = 0.68 + index * 0.035;

    // FLY: each item fans to a unique position with tilt
    // index 0 (gold)  → top-left
    // index 1 (blue)  → top-center-right
    // index 2 (cash)  → top-center slightly left
    final flyPositions = [
      Offset(cx - size.width * 0.18, cy - size.height * 0.30),
      Offset(cx + size.width * 0.14, cy - size.height * 0.26),
      Offset(cx - size.width * 0.05, cy - size.height * 0.22),
    ];
    final flyAngles = [-0.18, 0.12, -0.05]; // tilt when flying
    final flyScales = [0.82, 0.80, 0.78];

    // DASHBOARD LAND: each item becomes a dashboard panel
    double dashX = cx;
    double dashY, dashW, dashH;
    if (index == 0) {
      // Gold card → Balance summary (upper panel)
      dashY = size.height * 0.27;
      dashW = size.width * 0.88;
      dashH = size.height * 0.20;
    } else if (index == 1) {
      // Blue card → Transactions list (mid panel)
      dashY = size.height * 0.565;
      dashW = size.width * 0.88;
      dashH = size.height * 0.32;
    } else {
      // Cash → Bottom action bar
      dashY = size.height * 0.865;
      dashW = size.width * 0.88;
      dashH = 58.0;
    }

    // ── Interpolate through peek → fly → dash ─────────────────
    double curX = cx;
    double curY  = cy + 14.0 + (index * 10.0); // start hidden inside wallet
    double curW  = itemW;
    double curH  = itemH;
    double curS  = 0.60;
    double curRot = 0.0;

    // Peek phase
    curY = lerpDouble(curY, peekY, _peek.value)!;
    curS = lerpDouble(curS, peekScale, _peek.value)!;

    // Fly phase
    curX   = lerpDouble(curX,   flyPositions[index].dx, _fly.value)!;
    curY   = lerpDouble(curY,   flyPositions[index].dy, _fly.value)!;
    curS   = lerpDouble(curS,   flyScales[index],        _fly.value)!;
    curRot = lerpDouble(curRot, flyAngles[index],         _fly.value)!;

    // Dash phase
    curX   = lerpDouble(curX,   dashX,    _dash.value)!;
    curY   = lerpDouble(curY,   dashY,    _dash.value)!;
    curW   = lerpDouble(curW,   dashW,    _dash.value)!;
    curH   = lerpDouble(curH,   dashH,    _dash.value)!;
    curS   = lerpDouble(curS,   1.0,      _dash.value)!;
    curRot = lerpDouble(curRot, 0.0,      _dash.value)!;

    // Corner radius: card-like → panel-like
    final curRadius = lerpDouble(20.0, 14.0, _dash.value)!;

    // Opacity: invisible until peek starts
    final curOpacity = _peek.value.clamp(0.0, 1.0);

    // Glow shadow fades in on fly, fades slightly on dash
    final shadowOpacity = (_fly.value * (1.0 - _dash.value * 0.5)).clamp(0.0, 1.0);

    return Positioned(
      left: curX - curW / 2,
      top:  curY - curH / 2,
      child: Opacity(
        opacity: curOpacity,
        child: Transform.rotate(
          angle: curRot,
          child: Transform.scale(
            scale: curS,
            alignment: Alignment.center,
            child: Container(
              width: curW,
              height: curH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(curRadius),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.45 * shadowOpacity),
                    blurRadius: 28,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(curRadius),
                child: Stack(
                  children: [
                    // Original item design (card / cash)
                    Opacity(
                      opacity: (1.0 - _dash.value * 1.8).clamp(0.0, 1.0),
                      child: isCash
                          ? _buildCashBill(curW, curH)
                          : _buildCreditCard(index, curW, curH),
                    ),
                    // Dashboard panel fades over the top
                    Opacity(
                      opacity: _dash.value.clamp(0.0, 1.0),
                      child: _buildDashboardPanel(index, curW, curH),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ╔══════════════════════════════════════════╗
  // ║  CASH BILL DESIGN                        ║
  // ╚══════════════════════════════════════════╝
  Widget _buildCashBill(double w, double h) {
    return Container(
      width: w, height: h,
      color: const Color(0xFF2D7A3A),
      child: Stack(
        children: [
          // Outer inset border (like real bills)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green.shade300.withOpacity(0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          // Portrait oval
          Center(
            child: Container(
              width: h * 0.56, height: h * 0.56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.shade200.withOpacity(0.45), width: 1.5,
                ),
                color: const Color(0xFF246630).withOpacity(0.6),
              ),
            ),
          ),
          // Dollar sign
          const Center(
            child: Text(
              '\$',
              style: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // "100" denomination corners
          Positioned(
            left: 14, top: 9,
            child: Text('100',
              style: TextStyle(color: Colors.green.shade200.withOpacity(0.75),
                fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            right: 14, bottom: 9,
            child: Text('100',
              style: TextStyle(color: Colors.green.shade200.withOpacity(0.75),
                fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          // "UNITED STATES" text strip
          Positioned(
            bottom: 22, left: 0, right: 0,
            child: Center(
              child: Text(
                'EXPENWALL  ·  ONE HUNDRED',
                style: TextStyle(
                  color: Colors.green.shade100.withOpacity(0.55),
                  fontSize: 7,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════╗
  // ║  CREDIT CARD DESIGN                      ║
  // ╚══════════════════════════════════════════╝
  Widget _buildCreditCard(int index, double w, double h) {
    final isGold = index == 0;
    final gradColors = isGold
        ? [const Color(0xFFF5C842), const Color(0xFFB8860B), const Color(0xFF8B6914)]
        : [const Color(0xFF4A6CF7), const Color(0xFF1A3AD0), const Color(0xFF0A1A8A)];

    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
      ),
      child: Stack(
        children: [
          // Light shimmer diagonal
          Positioned(
            top: 0, right: 0,
            width: w * 0.5, height: h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),
          // Network logo (top right)
          Positioned(
            top: 16, right: 18,
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.85),
                  ),
                ),
                const SizedBox(width: -10),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          // EMV Chip
          Positioned(
            left: 22, top: h * 0.27,
            child: Container(
              width: 40, height: 30,
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.shade500, width: 0.5),
              ),
              child: CustomPaint(painter: _ChipLinePainter()),
            ),
          ),
          // Contactless wave icon
          Positioned(
            left: 72, top: h * 0.29,
            child: Icon(Icons.wifi_rounded,
              color: Colors.white.withOpacity(0.65), size: 22),
          ),
          // Card number (dot groups)
          Positioned(
            left: 22, bottom: h * 0.32,
            child: Row(
              children: List.generate(4, (g) => Row(
                children: [
                  ...List.generate(4, (_) => Container(
                    width: 5, height: 5,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )),
                  if (g < 3) const SizedBox(width: 8),
                ],
              )),
            ),
          ),
          // Card holder name
          Positioned(
            left: 22, bottom: 16,
            child: Text(
              isGold ? 'EXPEN GOLD' : 'EXPEN VISA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
              ),
            ),
          ),
          // Expiry
          Positioned(
            right: 22, bottom: 16,
            child: Text(
              '12/29',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ╔══════════════════════════════════════════╗
  // ║  DASHBOARD PANELS                        ║
  // ╚══════════════════════════════════════════╝
  Widget _buildDashboardPanel(int index, double w, double h) {
    switch (index) {
      case 0: return _buildBalancePanel(w, h);
      case 1: return _buildTransactionsPanel(w, h);
      default: return _buildActionBar(w, h);
    }
  }

  // Balance Summary Panel (gold card → this)
  Widget _buildBalancePanel(double w, double h) {
    return Container(
      width: w, height: h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF2D2870)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBar(90, 10),
                  const SizedBox(height: 10),
                  _shimmerBar(155, 28),
                ],
              ),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _statChip('Income', Colors.greenAccent),
              const SizedBox(width: 14),
              _statChip('Spent', Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  // Transactions Panel (blue card → this)
  Widget _buildTransactionsPanel(double w, double h) {
    final txIcons   = [Icons.restaurant, Icons.local_gas_station, Icons.shopping_bag];
    final txColors  = [Colors.purple, Colors.blue, Colors.orange];

    return Container(
      width: w, height: h,
      color: const Color(0xFF0F1632),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBar(130, 12, color: Colors.white60),
              _shimmerBar(55, 12, color: Colors.purple.withOpacity(0.7)),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: txColors[i].withOpacity(0.22),
                  ),
                  child: Icon(txIcons[i], color: Colors.white70, size: 18),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBar(100, 11, color: Colors.white70),
                    const SizedBox(height: 5),
                    _shimmerBar(65, 9, color: Colors.white30),
                  ],
                ),
                const Spacer(),
                _shimmerBar(50, 14),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Bottom Action Bar (cash → this)
  Widget _buildActionBar(double w, double h) {
    final items = [
      (_iconBtn(Icons.add_rounded,       'Add',      Colors.purpleAccent)),
      (_iconBtn(Icons.swap_horiz_rounded,'Transfer', Colors.blueAccent)),
      (_iconBtn(Icons.bar_chart_rounded, 'Stats',    Colors.greenAccent)),
      (_iconBtn(Icons.settings_rounded,  'Settings', Colors.white38)),
    ];
    return Container(
      width: w, height: h,
      color: const Color(0xFF16213E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items,
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────
  Widget _shimmerBar(double w, double h, {Color? color}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
  );

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBar(40, 7, color: Colors.white30),
              const SizedBox(height: 4),
              _shimmerBar(58, 11, color: Colors.white.withOpacity(0.8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label,
          style: TextStyle(
            color: color, fontSize: 9,
            fontWeight: FontWeight.w600, letterSpacing: 0.8,
          )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EMV Chip line detail painter
// ─────────────────────────────────────────────────────────────────
class _ChipLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.amber.shade600
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx, 0),        Offset(cx, size.height), p);
    canvas.drawLine(Offset(0, cy),        Offset(size.width, cy),  p);
    canvas.drawLine(Offset(0, 0),         Offset(0, cy * 0.6),     p);
    canvas.drawLine(Offset(size.width, 0),Offset(size.width, cy * 0.6), p);
  }
  @override
  bool shouldRepaint(_ChipLinePainter o) => false;
}
