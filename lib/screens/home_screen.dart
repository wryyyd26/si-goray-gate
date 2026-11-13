import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/gate_api.dart';
import '../services/token_vault.dart';
import '../ui/maja_theme.dart';
import 'auth_screens.dart';
import 'scanner_screen.dart';

/// Beranda minimalis petugas. Tidak mengklaim status server maupun akun
/// secara real-time karena belum ada endpoint profil/health khusus gate.
class GateHomeScreen extends StatefulWidget {
  const GateHomeScreen({
    super.key,
    required this.token,
    required this.identity,
    this.previewMode = false,
  });

  final String token;
  final String identity;
  final bool previewMode;

  @override
  State<GateHomeScreen> createState() => _GateHomeScreenState();
}

class _GateHomeScreenState extends State<GateHomeScreen> {
  bool _loggingOut = false;

  void _openScanner() {
    if (_loggingOut) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScannerScreen(
        token: widget.token,
        identity: widget.identity,
        previewMode: widget.previewMode,
      ),
    ));
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    if (widget.previewMode) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _loggingOut = true);
    try {
      await GateAuthApi.logout(widget.token);
      await GateTokenVault.instance.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on GateApiError catch (error) {
      if (error.statusCode == 401) {
        await GateTokenVault.instance.clear();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }
      if (mounted) _showMessage('Logout server gagal: ${error.message}');
    } catch (_) {
      if (mounted) _showMessage('Tidak dapat logout karena koneksi bermasalah. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showGuide() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 10, 26, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Panduan Scan Tiket', style: GoogleFonts.poppins(
                fontSize: 19, fontWeight: FontWeight.w700, color: MajaColors.ink,
              )),
              const SizedBox(height: 16),
              for (final item in const [
                '1. Tekan Scan Tiket dan izinkan penggunaan kamera.',
                '2. Arahkan kamera ke kode QR tiket pengunjung.',
                '3. Berikan akses hanya jika muncul AKSES DITERIMA.',
                '4. Jika DITOLAK atau TIDAK TERVERIFIKASI, jangan beri akses.',
                '5. Tekan Coba pindai lagi untuk memeriksa tiket berikutnya.',
              ]) ...[
                Text(item, style: GoogleFonts.poppins(
                  color: MajaColors.muted, fontSize: 13, height: 1.6,
                )),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              MajaPillButton(label: 'Mengerti', onPressed: () => Navigator.of(sheetContext).pop()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final identity = widget.previewMode ? 'petugas@contoh.go.id' : widget.identity;
    return PhoneStage(
      background: const Color(0xFFFFEEE7),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEEE7), Color(0xFFFFF7F4)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(27, 34, 27, 52),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [MajaColors.navy, MajaColors.navy2],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MajaBrand(compact: true),
                    const SizedBox(height: 4),
                    Text('P E T U G A S   G E R B A N G',
                      style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFFCDD5E8))),
                    const SizedBox(height: 33),
                    Text('Selamat Bertugas!',
                      style: GoogleFonts.poppins(fontSize: 27, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('SI-GORAY · Pemeriksaan tiket GOR',
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFC7D0E5))),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -21),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SoftCard(
                        child: Row(children: [
                          Container(
                            width: 62, height: 62,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE3D9), borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.badge_outlined, size: 32, color: MajaColors.ink),
                          ),
                          const SizedBox(width: 15),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Akun petugas', style: GoogleFonts.poppins(fontSize: 12, color: MajaColors.muted)),
                              const SizedBox(height: 4),
                              Text(identity, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: MajaColors.ink)),
                            ],
                          )),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _loggingOut ? null : _openScanner,
                          borderRadius: BorderRadius.circular(28),
                          child: Ink(
                            height: 116,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5B4F), Color(0xFFDA1F29)],
                              ),
                              boxShadow: const [BoxShadow(color: Color(0x3ADD3237), blurRadius: 19, offset: Offset(0, 10))],
                            ),
                            child: Row(children: [
                              const SizedBox(width: 25),
                              const Icon(Icons.qr_code_scanner_rounded, size: 42, color: Colors.white),
                              const SizedBox(width: 20),
                              Expanded(child: Text('Scan Tiket', style: GoogleFonts.poppins(
                                fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white))),
                              const Icon(Icons.chevron_right_rounded, size: 35, color: Colors.white),
                              const SizedBox(width: 17),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Row(children: [
                        Expanded(child: _ActionTile(
                          icon: Icons.menu_book_rounded, title: 'Panduan Scan', onTap: _showGuide)),
                        const SizedBox(width: 11),
                        Expanded(child: _ActionTile(
                          icon: Icons.logout_rounded,
                          title: _loggingOut ? 'Keluar...' : 'Logout',
                          onTap: _loggingOut ? null : _logout)),
                      ]),
                      const SizedBox(height: 19),
                      _SoftCard(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.lock_outline_rounded, color: MajaColors.ink),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Sesi petugas', style: GoogleFonts.poppins(
                              fontSize: 13.5, fontWeight: FontWeight.w600, color: MajaColors.ink))),
                            Text('Login berhasil', style: GoogleFonts.poppins(
                              color: const Color(0xFF147C58), fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                          const Divider(height: 24),
                          Row(children: [
                            const Icon(Icons.wifi_rounded, color: MajaColors.ink),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Validasi tiket', style: GoogleFonts.poppins(
                              fontSize: 13.5, fontWeight: FontWeight.w600, color: MajaColors.ink))),
                            Flexible(child: Text('Melalui server', textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(fontSize: 11, color: MajaColors.muted))),
                          ]),
                        ],
                      )),
                      const SizedBox(height: 19),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: const Color(0xFFFFE4DB),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFDA3B3C), size: 26),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Scan hanya tiket QR resmi SI-GORAY', style: GoogleFonts.poppins(
                              fontSize: 12.5, fontWeight: FontWeight.w700, color: MajaColors.ink)),
                            const SizedBox(height: 5),
                            Text('Jika hasil tidak terverifikasi, jangan berikan akses masuk.',
                              style: GoogleFonts.poppins(fontSize: 11, height: 1.55, color: MajaColors.muted)),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [BoxShadow(color: Color(0x160E193B), blurRadius: 18, offset: Offset(0, 7))],
    ),
    child: child,
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 17),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD5DBE9)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: MajaColors.ink, size: 21),
          const SizedBox(width: 7),
          Flexible(child: Text(title, maxLines: 2, textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11.2, fontWeight: FontWeight.w600, color: MajaColors.ink))),
        ]),
      ),
    ),
  );
}
