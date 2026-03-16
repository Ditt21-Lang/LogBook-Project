import 'package:flutter/material.dart';
import '../auth/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // ── Brand palette ─────────────────────────────────────────────────────
  static const _brand     = Color(0xFFD4956A);
  static const _brandDark = Color(0xFFB87343);
  static const _surface   = Color(0xFFFFF8F0);
  static const _border    = Color(0xFFE8C99A);
  static const _textDark  = Color(0xFF3D2B1F);
  static const _textMuted = Color(0xFF9C7B5E);

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "LogBook Counter",
      "desc": "Aplikasi sederhana untuk mencatat setiap perubahan nilai dengan mudah.",
      "image": "assets/images/notesDocument.json",
      "icon": Icons.book_rounded,
    },
    {
      "title": "Riwayat Tersimpan",
      "desc": "Semua aktivitas tersimpan otomatis di perangkat kamu.",
      "image": "assets/images/saved.json",
      "icon": Icons.history_rounded,
    },
    {
      "title": "Siap Digunakan",
      "desc": "Login sekarang dan mulai gunakan aplikasi.",
      "image": "assets/images/smilingCoffee.json",
      "icon": Icons.rocket_launch_rounded,
    },
  ];

  void _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isOnboardingView", true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _goToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: _textMuted,
                  ),
                  child: const Text(
                    "Lewati",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),

            // ── PageView ──────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image with warm card backdrop
                        SizedBox(
                          width: double.infinity,
                          height: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Lottie.asset(
                              page["image"]!,
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Icon badge
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _brand.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page["icon"] as IconData,
                            color: _brandDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          page["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          page["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: _textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Dot indicators ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? _brand : _border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Next / Mulai button ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [_brand, _brandDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _brand.withOpacity(0.38),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (_currentIndex < _pages.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _goToLogin();
                        }
                      },
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentIndex == _pages.length - 1
                                  ? "Mulai"
                                  : "Lanjut",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentIndex == _pages.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}