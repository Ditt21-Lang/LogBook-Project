import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'dart:ui';

import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/access_control_services.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';

class LogView extends StatefulWidget {
  final String currentUsername;
  final String currentRole;
  final String currentTeamId;

  const LogView({
    super.key,
    required this.currentUsername,
    this.currentRole = 'Anggota',
    this.currentTeamId = 'no_team',
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  bool _isLoading = true;
  bool _isOffline = true;
  String get _username => widget.currentUsername;
  String get _role => widget.currentRole;
  String get _teamId => widget.currentTeamId;

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    try {
      await LogHelper.writeLog("UI: Memulai Inisialisasi Database...", source: "log_view.dart");
      final isOnline = await _controller.loadLogs();

      await LogHelper.writeLog("UI: Data berhasil dimuat ke notifier", source: "log_view.dart");
      _isOffline = !isOnline;
      if (!isOnline && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offline Mode: Tidak Terhubung ke Cloud"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _isOffline = true;
      await LogHelper.writeLog("UI: error - $e", source: "log_view.dart", level: 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Offline Mode: Tidak Terhubung ke Cloud"), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    try {
      final isOnline = await _controller.loadLogs();
      setState(() => _isOffline = !isOnline);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOnline
                ? "Data berhasil diperbarui dari Cloud"
                : "Offline Mode: Tidak Terhubung ke Cloud",
          ),
          backgroundColor: isOnline ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isOffline = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data dari Cloud"), backgroundColor: Colors.red),
      );
    }
  }

  Color _getCategoryColor(LogCategory category) {
    switch (category) {
      case LogCategory.pekerjaan: return Colors.blue.shade100;
      case LogCategory.pribadi:   return Colors.green.shade100;
      case LogCategory.urgent:    return Colors.red.shade100;
    }
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: {
            'uid': _username,
            'role': _role,
            'teamId': _teamId,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4956A),
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFD4956A),
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text(
          "Log View: Hello, $_username ($_role)",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Konfirmasi logout'),
                    content: const Text(
                      'Yakin ingin keluar? Data yang disimpan mungkin akan hilang',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginView(),
                            ),
                            (routes) => false,
                          );
                        },
                        child: const Text(
                          'Ya, keluar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Single RefreshIndicator at the top level
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFD4956A),
        child: CustomScrollView(
          // AlwaysScrollable so pull works even when content is short
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Offline banner
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isOffline
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4956A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD4956A).withOpacity(0.40),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cloud_off_rounded, color: Color(0xFFB87343), size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Center(
                                      child: Text(
                                        "Offline Mode - Data Tidak Sinkron",
                                        style: TextStyle(
                                          color: Color(0xFF8B5E35),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Search bar
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F0).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE8C99A).withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4956A).withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: TextField(
                            onChanged: (value) => _controller.searchLog(value),
                            style: const TextStyle(color: Color(0xFF3D2B1F), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Cari catatan...',
                              hintStyle: TextStyle(
                                color: const Color(0xFF9C7B5E).withOpacity(0.7),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFB5825A), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Loading state
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Menghubungkan ke MongoDB Atlas..."),
                    ],
                  ),
                ),
              )
            else
              ValueListenableBuilder(
                valueListenable: _controller.filteredLogs,
                builder: (context, currentLogs, child) {
                  if (currentLogs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/noLogPicture.png',
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            const Text('Belum Ada Catatan', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  }

                  // SliverList — no nested scroll, parent handles everything
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final log = currentLogs[index];
                        final canUpdate = AccessControlServices.canPerform(
                          _role,
                          'update',
                          isOwner: log.authorId == widget.currentUsername,
                        );
                        final canDelete = AccessControlServices.canPerform(
                          _role,
                          'delete',
                          isOwner: log.authorId == widget.currentUsername,
                        );
                        return Dismissible(
                          key: Key(log.date.toIso8601String()),
                          direction: canDelete
                              ? DismissDirection.endToStart
                              : DismissDirection.none,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            _controller.removeLog(log, index, _role, _username);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Catatan Dihapus')),
                            );
                          },
                          child: Card(
                            color: _getCategoryColor(log.category),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _getCategoryColor(log.category), width: 2),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.note),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(log.category),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      log.category.name.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(log.description),
                                  const SizedBox(height: 4),
                                  Text(
                                    LogHelper.formatRelativeTime(log.date),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (canUpdate)
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _goToEditor(log: log, index: index),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (canDelete)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _controller.removeLog(log, index, _role, _username);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Catatan Dihapus')),
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: currentLogs.length,
                    ),
                  );
                },
              ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(),
        backgroundColor: const Color(0xFFD4956A),
        child: const Icon(Icons.add),
      ),
    );
  }
}
