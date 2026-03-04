import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak dan Controller input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  int _loginAttemps = 0;
  bool _isLoginDisabled = false;
  bool _isPasswordHidden = true;

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    bool isSuccess = _controller.login(user, pass);

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username/Password tidak boleh kosong')),
      );
    } else if (isSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LogView()),
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
      setState(() {
        _isLoginDisabled = true;
      });

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
      appBar: AppBar(title: const Text('Login Gatekeeper')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildFloatingField(controller: _userController, label: "Username"),
            const SizedBox(height: 16),
            _buildFloatingField(
              controller: _passController,
              label: "Password",
              obscureText: _isPasswordHidden,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _isPasswordHidden = !_isPasswordHidden),
                icon: Icon(
                  _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),

            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: _isLoginDisabled
                      ? [Color(0xFFDDDDDD), Color(0xFFCCCCCC)]
                      : [Color(0xFF237227), Color(0xFF519A66)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: _isLoginDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: Color(0xFF6C63FF).withOpacity(0.35),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isLoginDisabled ? null : _handleLogin,
                  child: Center(
                    child: Text(
                      "Masuk",
                      style: TextStyle(
                        color: _isLoginDisabled
                            ? Color(0xFFAAAAAA)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this reusable widget at the bottom of your file
  Widget _buildFloatingField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF6C63FF), // accent on focus
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // no border line, shadow does the work
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
