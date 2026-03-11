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

  @override
  void initState() {
    _selectedCategory = widget.log?.category ?? LogCategory.software;
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );

    _isPublic = widget.log?.isPublic ?? false;

    // Listener agar Pratinjau terupdate otomatis
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
      // Tambah Baru
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
      // Update
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
      if (ok){
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
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<LogCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      prefixIcon: Icon(Icons.category_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: LogCategory.values.map((category) {
                      Color categoryColor;
                      IconData categoryIcon;

                      switch (category) {
                        case LogCategory.mechanical:
                          categoryColor = Colors.green;
                          categoryIcon = Icons.settings_rounded;
                          break;
                        case LogCategory.electronic:
                          categoryColor = Colors.blue;
                          categoryIcon = Icons.electric_bolt_rounded;
                          break;
                        case LogCategory.software:
                          categoryColor = Colors.indigo;
                          categoryIcon = Icons.code_rounded;
                          break;
                      }

                      return DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(categoryIcon, color: categoryColor, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              category.name.toUpperCase(),
                              style: TextStyle(
                                  color: categoryColor,
                                  fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 8),

                  SwitchListTile(
                    title: const Text("Public"),
                    subtitle: Text(_isPublic ? "Catatan dapat dilihat oleh semua anggota": "Catatan bersifat private"), 
                    value: _isPublic,
                    onChanged: (value){
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Markdown Preview
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}
