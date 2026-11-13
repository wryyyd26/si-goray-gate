import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MajaColors {
  static const navy = Color(0xFF0C1737);
  static const navy2 = Color(0xFF192855);
  static const ink = Color(0xFF142349);
  static const muted = Color(0xFF516079);
  static const gold = Color(0xFFF8B43C);
  static const coral = Color(0xFFFF7858);
  static const red = Color(0xFFE9282D);
  static const border = Color(0xFFB9C5DD);
}

ThemeData majaTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    // textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: MajaColors.ink),
  );
}

// The PDF mockup is a portrait phone design (roughly 390 x 844).
// Keep that composition on desktop Chrome rather than stretching it to 1300 px.
class PhoneStage extends StatelessWidget {
  const PhoneStage({super.key, required this.child, this.background = MajaColors.navy});
  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222737),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ColoredBox(color: background, child: child),
          ),
        ),
      ),
    );
  }
}

class MajaBrand extends StatelessWidget {
  const MajaBrand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF705C), Color(0xFFFFAF42)],
          ).createShader(bounds),
          child: Text(
            'MAJA-TIX',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 23 : 34,
              letterSpacing: compact ? 1.2 : 2.1,
              height: 1.20,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 13),
          Text(
            'GOR SENI MAJAPAHIT · KOTA MOJOKERTO',
            maxLines: 1,
            style: GoogleFonts.poppins(
              color: const Color(0xFFC1CBE2),
              fontSize: 10.5,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class MajaPillButton extends StatelessWidget {
  const MajaPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.outline = false,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool outline;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: outline || onPressed == null ? null : const LinearGradient(
            colors: [Color(0xFFF13D40), Color(0xFFD21821)],
          ),
          color: outline ? Colors.white : (onPressed == null ? Colors.grey.shade400 : null),
          border: outline ? Border.all(color: MajaColors.ink, width: 1.4) : null,
          boxShadow: !outline && onPressed != null
              ? const [BoxShadow(color: Color(0x48C93636), blurRadius: 17, offset: Offset(0, 9))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(50),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: outline ? MajaColors.ink : Colors.white),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: outline ? MajaColors.ink : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.title, required this.subtitle, required this.form});
  final String title;
  final String subtitle;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return PhoneStage(
      background: const Color(0xFFF6D8D5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 430.0);
          final scale = width / 390.0;
          final minHeight = 780.0 * scale;
          final height = math.max(constraints.maxHeight, minHeight);
          final isOtp = title == 'Masukkan kode OTP';
          return SingleChildScrollView(
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE8ECF9), Color(0xFFF3DEE0), Color(0xFFFFD4C7)],
                          stops: [0, .48, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: (isOtp ? 233 : 296) * scale,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(27 * scale, 45 * scale, 16, 0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [MajaColors.navy, MajaColors.navy2],
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MajaBrand(),
                          SizedBox(height: (isOtp ? 17 : 47) * scale),
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 23 * scale,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFC8D2E5),
                              fontSize: 13 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: (isOtp ? 188 : 248) * scale,
                    left: 20 * scale,
                    right: 20 * scale,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 23 * scale, vertical: 26 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26 * scale),
                        boxShadow: const [
                          BoxShadow(color: Color(0x241C2648), blurRadius: 27, offset: Offset(0, 20)),
                        ],
                      ),
                      child: form,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 12,
                    right: 12,
                    child: Text(
                      title == 'Portal Petugas Gerbang'
                          ? 'Khusus petugas resmi · Dinas Kominfo Kota Mojokerto'
                          : 'Batas 5 percobaan verifikasi per 15 menit',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: MajaColors.muted, fontSize: 11 * scale),
                    ),
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

class CornersPainter extends CustomPainter {
  const CornersPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MajaColors.gold
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const segment = 47.0;
    const r = 28.0;
    final w = size.width;
    final h = size.height;
    final paths = [
      Path()..moveTo(0, segment)..lineTo(0, r)..quadraticBezierTo(0, 0, r, 0)..lineTo(segment, 0),
      Path()..moveTo(w - segment, 0)..lineTo(w - r, 0)..quadraticBezierTo(w, 0, w, r)..lineTo(w, segment),
      Path()..moveTo(0, h - segment)..lineTo(0, h - r)..quadraticBezierTo(0, h, r, h)..lineTo(segment, h),
      Path()..moveTo(w - segment, h)..lineTo(w - r, h)..quadraticBezierTo(w, h, w, h - r)..lineTo(w, h - segment),
    ];
    for (final p in paths) { canvas.drawPath(p, paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
