import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/gate_api.dart';
import '../services/token_vault.dart';
import '../ui/maja_theme.dart';
import 'auth_screens.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.token, required this.identity, this.previewMode = false});
  final String token;
  final String identity;
  final bool previewMode;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _camera = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handling = false;
  bool _loggingOut = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || widget.previewMode || _loggingOut) return;
    String? payload;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) { payload = raw; break; }
    }
    if (payload == null) return;

    // Immediately lock before any await to prevent double POST /api/gate/scan.
    setState(() => _handling = true);
    try {
      await _camera.stop();
      final result = await GateScanApi.scan(widget.token, payload);
      if (!mounted) return;
      if (result.unauthorized) {
        await GateTokenVault.instance.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => ScanResultScreen(result: result)),
      );
    } catch (_) {
      if (mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const ScanResultScreen(
            result: ScanDecision(
              decision: AccessDecision.uncertain,
              reason: 'JARINGAN / TIMEOUT',
              message: 'Tidak dapat memverifikasi tiket. Periksa koneksi, lalu pindai ulang. Jangan beri akses dulu.',
            ),
          )),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _handling = false);
        try { await _camera.start(); } catch (_) { /* camera permission can be rejected */ }
      }
    }
  }

  Future<void> _logout() async {
    if (_handling || _loggingOut) return;
    if (widget.previewMode) { Navigator.of(context).pop(); return; }
    setState(() => _loggingOut = true);
    try {
      await _camera.stop();
      await GateAuthApi.logout(widget.token);
      await GateTokenVault.instance.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on GateApiError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout server gagal: ${error.message}')),
      );
      try { await _camera.start(); } catch (_) {}
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _torch() async {
    if (widget.previewMode || kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lampu tersedia pada perangkat Android yang mendukung.')));
      return;
    }
    try {
      await _camera.toggleTorch();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lampu kamera tidak tersedia.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhoneStage(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1633), Color(0xFF172654)],
          ),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final scale = width / 390;
          final scanSize = width * .70;
          return Stack(
            children: [
              Positioned(
                left: 25 * scale,
                right: 22 * scale,
                top: 31 * scale,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MajaBrand(compact: true),
                          const SizedBox(height: 5),
                          Text(
                            'Petugas: ${widget.previewMode ? 'Nama Petugas' : widget.identity}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFBDC6E2)),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _handling || _loggingOut ? null : _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF8995B4)),
                        minimumSize: const Size(90, 43),
                        shape: const StadiumBorder(),
                      ),
                      child: Text('Keluar', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 149 * scale,
                left: (width - scanSize) / 2,
                width: scanSize,
                height: scanSize * .90,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: widget.previewMode
                            ? Container(
                                color: const Color(0xFF1A294F),
                                alignment: Alignment.center,
                                child: Text('[pratinjau kamera]', style: GoogleFonts.poppins(color: const Color(0xFFA6B0CB), fontSize: 12)),
                              )
                            : MobileScanner(
                                controller: _camera,
                                onDetect: _onDetect,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error) => Container(
                                  color: const Color(0xFF1A294F),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(18),
                                  child: Text('Kamera tidak tersedia.\nPeriksa izin kamera.', textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                      ),
                    ),
                    const Positioned(
                      left: 22,
                      right: 22,
                      top: 0,
                      bottom: 0,
                      child: Center(child: SizedBox(height: 2,
                        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFFF7358), Colors.transparent]))))),
                    ),
                    Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: const CornersPainter()))),
                  ],
                ),
              ),
              Positioned(
                top: (149 + scanSize * .90 / scale + 30) * scale,
                left: 65 * scale,
                right: 65 * scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  decoration: BoxDecoration(color: const Color(0xFF354264), borderRadius: BorderRadius.circular(28)),
                  child: Text('Arahkan kamera ke QR tiket',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ),
              Positioned(
                left: 24 * scale,
                right: 24 * scale,
                bottom: 90 * scale,
                child: Container(
                  height: 53,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFF144561),
                    border: Border.all(color: const Color(0xFF27BBAF), width: 1.4),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2EC8B7))),
                      const SizedBox(width: 10),
                      Text(_handling ? 'Memverifikasi tiket...' : 'Siap memindai', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 24 * scale,
                right: 24 * scale,
                bottom: 27 * scale,
                child: OutlinedButton(
                  onPressed: _handling ? null : _torch,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF8495BA), width: 1.2),
                    minimumSize: const Size.fromHeight(51),
                    shape: const StadiumBorder(),
                  ),
                  child: Text('Nyalakan lampu', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, required this.result, this.previewMode = false});
  final ScanDecision result;
  final bool previewMode;

  @override
  Widget build(BuildContext context) {
    final granted = result.decision == AccessDecision.granted;
    final denied = result.decision == AccessDecision.denied;
    final warning = result.decision == AccessDecision.uncertain;
    final title = granted ? 'AKSES DIBERIKAN' : (denied ? 'AKSES DITOLAK' : 'TIDAK TERVERIFIKASI');
    final colors = granted
        ? const [Color(0xFF179884), Color(0xFF0B554E)]
        : denied
            ? const [Color(0xFFEF3634), Color(0xFF88120F)]
            : const [Color(0xFFFFE8AC), Color(0xFFFFDA7B)];
    final fg = warning ? const Color(0xFF432C05) : Colors.white;
    final icon = granted ? Icons.check_rounded : (denied ? Icons.close_rounded : Icons.error_outline_rounded);
    return PhoneStage(
      background: colors.last,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)),
        child: LayoutBuilder(builder: (context, constraints) {
          final scale = constraints.maxWidth / 390;
          return Stack(
            children: [
              Positioned(
                top: 102 * scale,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 170 * scale,
                    height: 170 * scale,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: fg.withValues(alpha: .12)),
                    padding: EdgeInsets.all(20 * scale),
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: fg.withValues(alpha: .19)),
                      child: Icon(icon, size: 75 * scale, color: fg),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 304 * scale,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Text(title, textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: fg, fontSize: 25 * scale, fontWeight: FontWeight.w800, height: 1.2)),
                    SizedBox(height: 19 * scale),
                    Text(result.message, textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: fg, fontSize: 15.3 * scale, height: 1.65)),
                    SizedBox(height: 21 * scale),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 290),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: .16), borderRadius: BorderRadius.circular(22)),
                      child: Text(result.reason, textAlign: TextAlign.center,
                        style: TextStyle(color: fg, fontFamily: 'monospace', fontSize: 10.5 * scale, letterSpacing: 1.2)),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 29 * scale,
                left: 24 * scale,
                right: 24 * scale,
                child: Container(
                  height: 52 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    color: warning ? const Color(0xFF3D2A03) : Colors.white,
                    boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 10))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(48),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Text(warning ? 'Coba pindai lagi' : 'Pindai tiket berikutnya',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: warning ? const Color(0xFFFFECC6) : (granted ? const Color(0xFF075C52) : const Color(0xFF9B1E1E)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (previewMode)
                Positioned(top: 18, right: 15, child: Text('PRATINJAU UI', style: GoogleFonts.poppins(color: fg.withValues(alpha:.65), fontSize: 9))),
            ],
          );
        }),
      ),
    );
  }
}
