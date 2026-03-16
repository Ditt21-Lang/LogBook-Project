import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late bool _isPublic;
  late LogCategory _selectedCategory;

  // Brand color — matches LogView
  static const _brand = Color(0xFFD4956A);
  static const _brandDark = Color(0xFFB87343);
  static const _surface = Color(0xFFFFF8F0);
  static const _border = Color(0xFFE8C99A);
  static const _textDark = Color(0xFF3D2B1F);
  static const _textMuted = Color(0xFF9C7B5E);

  @override
  void initState() {
    _selectedCategory = widget.log?.category ?? LogCategory.software;
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _isPublic = widget.log?.isPublic ?? false;

    _descController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _save() async {
    final userId = (widget.currentUser['uid'] ??
            widget.currentUser['id'] ??
            widget.currentUser['username'] ??
            '')
        .toString();
    final userRole = (widget.currentUser['role'] ?? 'Anggota').toString();
    final teamId = (widget.currentUser['teamId'] ?? 'no_team').toString();

    if (widget.log == null) {
      await widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory,
        authorId: userId,
        teamId: teamId,
        isPublic: _isPublic,
      );
      if (mounted) Navigator.pop(context);
    } else {
      final ok = await widget.controller.updateLog(
        widget.log!.copyWith(
          isPublic: _isPublic,
          category: _selectedCategory,
        ),
        _titleController.text,
        _descController.text,
        _selectedCategory,
        widget.index!,
        userRole,
        userId,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update Gagal'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Returns category accent color for badge and icon
  Color _categoryColor(LogCategory cat) {
    switch (cat) {
      case LogCategory.mechanical:
        return Colors.green.shade600;
      case LogCategory.electronic:
        return Colors.blue.shade600;
      case LogCategory.software:
        return Colors.indigo.shade600;
    }
  }

  IconData _categoryIcon(LogCategory cat) {
    switch (cat) {
      case LogCategory.mechanical:
        return Icons.settings_rounded;
      case LogCategory.electronic:
        return Icons.electric_bolt_rounded;
      case LogCategory.software:
        return Icons.code_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.log == null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          backgroundColor: _brand,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            isNew ? "Catatan Baru" : "Edit Catatan",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                label: const Text(
                  "Simpan",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            // ── Tab 1: Editor ──────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: "Judul",
                      labelStyle: const TextStyle(color: _textMuted),
                      prefixIcon: const Icon(Icons.title_rounded, color: _brandDark),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _brand, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category dropdown
                  DropdownButtonFormField<LogCategory>(
                    value: _selectedCategory,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: _textDark, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      labelStyle: const TextStyle(color: _textMuted),
                      prefixIcon: Icon(
                        _categoryIcon(_selectedCategory),
                        color: _categoryColor(_selectedCategory),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _brand, width: 1.8),
                      ),
                    ),
                    items: LogCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(_categoryIcon(category),
                                color: _categoryColor(category), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              category.name.toUpperCase(),
                              style: TextStyle(
                                color: _categoryColor(category),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedCategory = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Public toggle — card style
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: const Text(
                        "Public",
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _isPublic
                            ? "Catatan dapat dilihat oleh semua anggota"
                            : "Catatan bersifat private",
                        style: const TextStyle(color: _textMuted, fontSize: 12),
                      ),
                      secondary: Icon(
                        _isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                        color: _isPublic ? _brand : _textMuted,
                      ),
                      activeColor: _brand,
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Markdown editor area — fixed height container
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small header bar inside the container
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _border.withOpacity(0.3),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.edit_note_rounded,
                                  color: _textMuted, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "Markdown",
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Actual text field
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: TextField(
                              controller: _descController,
                              maxLines: null,
                              expands: true,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 14,
                                height: 1.6,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    "Tulis laporan dengan format Markdown...",
                                hintStyle: TextStyle(
                                    color: _textMuted, fontSize: 14),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live char count
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${_descController.text.length} karakter",
                        style: const TextStyle(
                            color: _textMuted, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab 2: Markdown Preview ────────────────────────────────
            _descController.text.trim().isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.article_outlined,
                            color: _textMuted, size: 48),
                        SizedBox(height: 12),
                        Text(
                          "Belum ada konten untuk ditampilkan",
                          style:
                              TextStyle(color: _textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : Markdown(
                    data: _descController.text,
                    padding: const EdgeInsets.all(20),
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                          color: _textDark, fontSize: 14, height: 1.7),
                      h1: const TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 22),
                      h2: const TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                      code: TextStyle(
                        backgroundColor: _border.withOpacity(0.3),
                        color: _brandDark,
                        fontSize: 13,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: _brand.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: const Border(
                          left: BorderSide(color: _brand, width: 3),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}