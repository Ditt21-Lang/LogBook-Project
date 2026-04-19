import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'vision_controller.dart';

class PreviewPage extends StatefulWidget {
  final String imagePath;
  final VisionController controller;
  const PreviewPage({super.key, required this.imagePath, required this.controller});
  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  // ── Brand palette (shared with LoginView) ────────────────────────────
  static const _brand     = Color(0xFFD4956A);
  static const _brandDark = Color(0xFFB87343);
  static const _surface   = Color(0xFFFFF8F0);
  static const _border    = Color(0xFFE8C99A);
  static const _textDark  = Color(0xFF3D2B1F);
  static const _textMuted = Color(0xFF9C7B5E);

  img.Image? originalImage;
  img.Image? displayedImage;
  String selectedFilter = "Original";
  late VisionController _visionController;

  final List<Map<String, dynamic>> _filters = [
    {"label": "Original",  "icon": Icons.image_outlined},
    {"label": "Low Pass",  "icon": Icons.blur_on_rounded},
    {"label": "Gaussian",  "icon": Icons.grain_rounded},
    {"label": "High Pass", "icon": Icons.auto_fix_high_rounded},
    {"label": "Mean",      "icon": Icons.grid_view_rounded},
     {"label": "Histogram Equalization",  "icon": Icons.bar_chart_rounded},
     {"label": "Band Pass",      "icon": Icons.grid_view_rounded},
     {"label": "Sharpening",      "icon": Icons.grid_view_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _visionController = widget.controller;
    _loadImage();
  }

  void _loadImage() {
    final bytes = File(widget.imagePath).readAsBytesSync();
    originalImage = img.decodeImage(bytes);
    displayedImage = originalImage;
    setState(() {});
  }

  void applyFilter(String filter) {
    if (originalImage == null) return;
    final result = _visionController.applyFilter(originalImage!, filter);
    setState(() {
      selectedFilter = filter;
      displayedImage = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (displayedImage == null) {
      return Scaffold(
        backgroundColor: _surface,
        body: const Center(
          child: CircularProgressIndicator(color: _brand),
        ),
      );
    }

    final bytes = img.encodeJpg(displayedImage!);

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Text(
          "Preview Filter",
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: Column(
        children: [
          // ── Image preview ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          // ── Filter chip selector ───────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    "Filter",
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final label = f["label"] as String;
                      final icon  = f["icon"] as IconData;
                      final isSelected = selectedFilter == label;

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => applyFilter(label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? _brand : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? _brand : _border,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _brand.withOpacity(0.30),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : _textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : _textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Save button ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                    onTap: () async {
                      final path =
                          '/storage/emulated/0/DCIM/filtered_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      await File(path).writeAsBytes(bytes);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Tersimpan ke galeri"),
                          backgroundColor: _brandDark,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_alt_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Simpan ke Galeri",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}