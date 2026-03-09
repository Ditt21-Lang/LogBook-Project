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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );

    // TAMBAHKAN INI: Listener agar Pratinjau terupdate otomatis
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
        LogCategory.pribadi,
        authorId: userId,
        teamId: teamId,
      );
    } else {
      // Update
      final ok = await widget.controller.updateLog(
        widget.log!,
        _titleController.text,
        _descController.text,
        widget.log!.category,
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
