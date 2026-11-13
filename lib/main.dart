import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth_screens.dart';
import 'screens/scanner_screen.dart';
import 'screens/home_screen.dart';
import 'services/gate_api.dart';
import 'services/token_vault.dart';
import 'ui/maja_theme.dart';

/// Pass --dart-define=UI_PREVIEW=true only to inspect the six mockup screens.
/// Preview mode never sends a real request or marks any ticket as valid.
const bool uiPreview = bool.fromEnvironment('UI_PREVIEW', defaultValue: false);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MajaGateApp());
}

class MajaGateApp extends StatelessWidget {
  const MajaGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAJA-TIX · Petugas Gerbang SI-GORAY',
      debugShowCheckedModeBanner: false,
      theme: majaTheme(),
      home: (uiPreview && kDebugMode) ? const PreviewGallery() : const GateStartup(),
    );
  }
}

class GateStartup extends StatelessWidget {
  const GateStartup({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: GateTokenVault.instance.read(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PhoneStage(child: Center(child: CircularProgressIndicator(color: Colors.white)));
        }
        final token = snapshot.data;
        if (token == null || token.isEmpty) return const LoginScreen();
        // Token may have expired; HTTP 401 on scan returns to login.
        return GateHomeScreen(token: token, identity: 'Sesi tersimpan');
      },
    );
  }
}

/// Developer-only screen gallery for visual comparison with PDF pages 1-6.
class PreviewGallery extends StatelessWidget {
  const PreviewGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <(String, Widget)>[
      ('1 · Login petugas', const LoginScreen(previewMode: true)),
      ('2 · Kode OTP', const OtpScreen(email: 'petugas@contoh.go.id', previewMode: true)),
      ('Beranda · Petugas gerbang', const GateHomeScreen(token: '', identity: 'petugas@contoh.go.id', previewMode: true)),
      ('3 · Scanner gerbang', const ScannerScreen(token: '', identity: '', previewMode: true)),
      ('4 · Akses diberikan', const ScanResultScreen(
        previewMode: true,
        result: ScanDecision(decision: AccessDecision.granted, message: 'QR valid. Akses diberikan.', reason: 'QR_VALID'),
      )),
      ('5 · Akses ditolak', const ScanResultScreen(
        previewMode: true,
        result: ScanDecision(decision: AccessDecision.denied, message: 'QR sudah tidak aktif atau sudah digunakan.', reason: 'QR_TIDAK_AKTIF'),
      )),
      ('6 · Tidak terverifikasi', const ScanResultScreen(
        previewMode: true,
        result: ScanDecision(decision: AccessDecision.uncertain,
          message: 'Tidak dapat memverifikasi tiket.\nPeriksa koneksi, lalu pindai ulang.\nJangan beri akses dulu.',
          reason: 'JARINGAN / TIMEOUT'),
      )),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0F0),
      appBar: AppBar(title: const Text('Pratinjau Mockup MAJA-TIX'), backgroundColor: Colors.white),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 490),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('MODE DESAIN SAJA', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 19, color: MajaColors.ink)),
              const SizedBox(height: 6),
              Text('Pilih halaman sesuai PDF. Tidak ada tiket yang benar-benar divalidasi di mode ini.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: MajaColors.muted)),
              const SizedBox(height: 15),
              for (final item in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    color: Colors.white,
                    child: ListTile(
                      title: Text(item.$1, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => item.$2)),
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
