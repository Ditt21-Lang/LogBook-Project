import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  int _loginAttemps = 0;
  bool _isLoginDisabled = false;
  bool _isPasswordHidden = true;

  // ── Brand palette (shared with LogView & LogEditorPage) ──────────────
  static const _brand     = Color(0xFFD4956A);
  static const _brandDark = Color(0xFFB87343);
  static const _surface   = Color(0xFFFFF8F0);
  static const _border    = Color(0xFFE8C99A);
  static const _textDark  = Color(0xFF3D2B1F);
  static const _textMuted = Color(0xFF9C7B5E);

  void _handleLogin() {
    String user = _userController.text.trim();
    String pass = _passController.text;
    final appUser = _controller.login(user, pass);

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username/Password tidak boleh kosong')),
      );
    } else if (appUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LogView(
            currentUsername: appUser.username,
            currentRole: appUser.role,
            currentTeamId: appUser.teamId,
          ),
        ),
      );
    } else {
      _loginAttemps++;
      if (_loginAttemps < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username/Password Salah! Coba cek ulang lagi'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kamu sudah melakukan kesalahan login sebanyak 3 kali, silahkan tunggu 10 detik',
            ),
          ),
        );
      }
    }

    if (_loginAttemps == 3) {
      setState(() => _isLoginDisabled = true);
      Future.delayed(const Duration(seconds: 10), () {
        setState(() {
          _isLoginDisabled = false;
          _loginAttemps = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      // No AppBar — cleaner login feel
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo / header ─────────────────────────────────────
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: _brand,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _brand.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.book_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Center(
                  child: Text(
                    "Logbook",
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    "Masuk untuk melanjutkan",
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Username field ────────────────────────────────────
                _buildField(
                  controller: _userController,
                  label: "Username",
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),

                // ── Password field ────────────────────────────────────
                _buildField(
                  controller: _passController,
                  label: "Password",
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _isPasswordHidden,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _isPasswordHidden = !_isPasswordHidden),
                    icon: Icon(
                      _isPasswordHidden
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: _textMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Login button ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: _isLoginDisabled
                            ? [const Color(0xFFDDDDDD), const Color(0xFFCCCCCC)]
                            : [_brand, _brandDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: _isLoginDisabled
                          ? []
                          : [
                              BoxShadow(
                                color: _brand.withOpacity(0.40),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _isLoginDisabled ? null : _handleLogin,
                        child: Center(
                          child: Text(
                            "Masuk",
                            style: TextStyle(
                              color: _isLoginDisabled
                                  ? const Color(0xFFAAAAAA)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Lockout hint ──────────────────────────────────────
                if (_isLoginDisabled) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.timer_outlined, color: _textMuted, size: 14),
                        SizedBox(width: 5),
                        Text(
                          "Tunggu 10 detik sebelum mencoba lagi",
                          style: TextStyle(color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _brand.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 15, color: _textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
          floatingLabelStyle: const TextStyle(
            color: _brandDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          prefixIcon: Icon(prefixIcon, color: _brandDark, size: 20),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}