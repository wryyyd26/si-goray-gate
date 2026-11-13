import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/gate_api.dart';
import '../services/token_vault.dart';
import '../ui/maja_theme.dart';
import 'scanner_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.previewMode = false});
  final bool previewMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    final email = _email.text.trim();
    if (widget.previewMode) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: email, previewMode: true)));
      return;
    }
    setState(() => _busy = true);
    try {
      await GateAuthApi.requestOtp(email);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: email)));
    } on GateApiError catch (e) {
      if (mounted) _toast(context, e.message);
    } catch (_) {
      if (mounted) _toast(context, 'Permintaan OTP gagal. Periksa koneksi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackdrop(
      title: 'Portal Petugas Gerbang',
      subtitle: 'Masuk untuk memindai tiket pengunjung',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Email petugas', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: MajaColors.ink)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              style: GoogleFonts.poppins(fontSize: 17, color: MajaColors.ink),
              decoration: InputDecoration(
                hintText: 'nama@contoh.go.id',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF92949C), fontSize: 17),
                filled: true,
                fillColor: const Color(0xFFF6F7FB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 19, vertical: 18),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: MajaColors.border, width: 1.4)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: MajaColors.ink, width: 2)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: MajaColors.red)),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Email wajib diisi';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                  return 'Masukkan email yang valid';
                }
                return null;
              },
              onFieldSubmitted: (_) => _requestOtp(),
            ),
            const SizedBox(height: 20),
            MajaPillButton(label: 'Kirim kode OTP', onPressed: _busy ? null : _requestOtp, loading: _busy),
            const SizedBox(height: 17),
            Text(
              'Kode 6 digit dikirim ke email dan berlaku 5 menit.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: MajaColors.muted, fontSize: 12.3, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email, this.previewMode = false});
  final String email;
  final bool previewMode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    if (widget.previewMode) _code.text = '482'; // Visual reference only; never sent to API.
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (widget.previewMode) { _toast(context, 'Mode pratinjau UI — bukan login petugas.'); return; }
    if (_code.text.length != 6 || _busy) {
      _toast(context, 'Masukkan kode OTP 6 digit.');
      return;
    }
    setState(() => _busy = true);
    try {
      final token = await GateAuthApi.verifyOtp(widget.email, _code.text);
      await GateTokenVault.instance.save(token);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ScannerScreen(token: token, identity: widget.email)),
        (_) => false,
      );
    } on GateApiError catch (e) {
      if (mounted) _toast(context, e.message);
    } catch (_) {
      if (mounted) _toast(context, 'Verifikasi gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _busy) return;
    if (widget.previewMode) { _toast(context, 'Mode pratinjau — OTP tidak dikirim.'); return; }
    setState(() => _resending = true);
    try {
      final message = await GateAuthApi.requestOtp(widget.email);
      if (mounted) _toast(context, message);
    } on GateApiError catch (e) {
      if (mounted) _toast(context, e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackdrop(
      title: 'Masukkan kode OTP',
      subtitle: 'Kami mengirim kode ke email petugas Anda',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 59,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TextField(
                    controller: _code,
                    focusNode: _focus,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    cursorColor: Colors.transparent,
                    style: const TextStyle(color: Colors.transparent, fontSize: 1),
                    decoration: const InputDecoration(counterText: '', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IgnorePointer(
                  child: Row(
                    children: List.generate(6, (i) {
                      final active = i == _code.text.length && _focus.hasFocus;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i == 5 ? 0 : 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: active ? MajaColors.ink : MajaColors.border, width: active ? 2.1 : 1.25),
                            boxShadow: active ? const [BoxShadow(color: Color(0x24202D52), blurRadius: 0, spreadRadius: 3)] : null,
                          ),
                          child: Text(
                            i < _code.text.length ? _code.text[i] : '',
                            style: GoogleFonts.poppins(color: MajaColors.ink, fontSize: 23, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Berlaku 5 menit. Jangan bagikan kode ini.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: MajaColors.muted, fontSize: 11.6)),
          const SizedBox(height: 22),
          MajaPillButton(label: 'Verifikasi dan masuk', onPressed: _busy ? null : _verify, loading: _busy),
          const SizedBox(height: 11),
          MajaPillButton(label: 'Kirim ulang kode', onPressed: _resending ? null : _resend, outline: true, loading: _resending),
        ],
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
