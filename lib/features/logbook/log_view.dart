import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'dart:ui';

import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:lottie/lottie.dart';

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
      final isOnline = await _controller.loadLogs(_username, _teamId);
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
          const SnackBar(
            content: Text("Offline Mode: Tidak Terhubung ke Cloud"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    try {
      final isOnline = await _controller.loadLogs(_username, _teamId);
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
        const SnackBar(
          content: Text("Gagal mengambil data dari Cloud"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Category accent color — for icon, badge text, and left border
  Color _getCategoryAccent(LogCategory category) {
    switch (category) {
      case LogCategory.electronic: return Colors.blue.shade600;
      case LogCategory.mechanical: return Colors.green.shade600;
      case LogCategory.software:   return Colors.indigo.shade600;
    }
  }

  // Category soft background — unchanged as requested
  Color _getCategoryBg(LogCategory category) {
    switch (category) {
      case LogCategory.electronic: return Colors.blue.shade50;
      case LogCategory.mechanical: return Colors.green.shade50;
      case LogCategory.software:   return Colors.indigo.shade50;
    }
  }

  IconData _getCategoryIcon(LogCategory category) {
    switch (category) {
      case LogCategory.electronic: return Icons.electric_bolt_rounded;
      case LogCategory.mechanical: return Icons.settings_rounded;
      case LogCategory.software:   return Icons.code_rounded;
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
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4956A),
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFFD4956A),
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text(
          "Hello, $_username ($_role)",
          style: const TextStyle(
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: Colors.orange.shade600,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Keluar dari akun?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yakin ingin keluar? Data yang belum disimpan mungkin akan hilang.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade50,
                              foregroundColor: Colors.orange.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Ya, Keluar',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
                },
              );
            },
            icon: const Icon(Icons.logout_rounded),
            color: Colors.white,
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFD4956A),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ── Offline banner ──────────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isOffline
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4956A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD4956A).withOpacity(0.40),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.cloud_off_rounded,
                                      color: Color(0xFFB87343), size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
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

                  // ── Search bar ──────────────────────────────────────
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
                            onChanged: (value) =>
                                _controller.searchLog(value, _username, _teamId),
                            style: const TextStyle(
                                color: Color(0xFF3D2B1F), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Cari catatan...',
                              hintStyle: TextStyle(
                                color:
                                    const Color(0xFF9C7B5E).withOpacity(0.7),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: Color(0xFFB5825A), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 18),
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

            // ── Loading state ─────────────────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFD4956A)),
                      SizedBox(height: 16),
                      Text(
                        "Menghubungkan ke MongoDB Atlas...",
                        style: TextStyle(color: Color(0xFF9C7B5E)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ValueListenableBuilder(
                valueListenable: _controller.filteredLogs,
                builder: (context, currentLogs, child) {
                final allLogs = _controller.logs.where((log) {
                  return log.teamId == _teamId &&
                      (log.authorId == _username || log.isPublic == true);
                }).toList();

                final displayLogs = currentLogs.where((log) {
                  return log.teamId == _teamId &&
                      (log.authorId == _username || log.isPublic == true);
                }).toList();

                  if (displayLogs.isEmpty) {
                    final isSearchEmpty = allLogs.isNotEmpty;
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Lottie.asset(
                              isSearchEmpty 
                                ? 'assets/images/emptyState.json'
                                : 'assets/images/empty_search.json',
                              width: 250,
                              height: 250,
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isSearchEmpty
                                ? 'Catatan Tidak ditemukan'
                                : 'Belum ada aktivitas hari ini?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3D2B1F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSearchEmpty
                              ? 'Coba kata kunci yang lain.'
                              : 'Mulai catat kemajuan proyek Anda!',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF9C7B5E)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final log = displayLogs[index];
                          final isOwner = log.authorId == _username;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LogCard(
                              log: log,
                              isOwner: isOwner,
                              categoryAccent: _getCategoryAccent(log.category),
                              categoryBg: _getCategoryBg(log.category),
                              categoryIcon: _getCategoryIcon(log.category),
                              onEdit: () => _goToEditor(log: log, index: index),
                              onDelete: () {
                                _controller.removeLog(log, index, _role, _username);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Catatan Dihapus')),
                                );
                              },
                              onDismissed: () {
                                _controller.removeLog(log, index, _role, _username);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Catatan Dihapus')),
                                );
                              },
                            ),
                          );
                        },
                        childCount: displayLogs.length,
                      ),
                    ),
                  );
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(),
        backgroundColor: const Color(0xFFD4956A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Extracted card widget ─────────────────────────────────────────────────
class _LogCard extends StatelessWidget {
  final LogModel log;
  final bool isOwner;
  final Color categoryAccent;
  final Color categoryBg;
  final IconData categoryIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDismissed;

  const _LogCard({
    required this.log,
    required this.isOwner,
    required this.categoryAccent,
    required this.categoryBg,
    required this.categoryIcon,
    required this.onEdit,
    required this.onDelete,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(log.date.toIso8601String()),
      direction:
          isOwner ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: BorderSide(color: categoryAccent, width: 10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: categoryBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(categoryIcon, color: categoryAccent, size: 18),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge + public indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: categoryBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            log.category.name.toUpperCase(),
                            style: TextStyle(
                              color: categoryAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (log.isPublic) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.public_rounded,
                              size: 13, color: Color(0xFF9C7B5E)),
                        ],
                        const Spacer(),
                        Text(
                          LogHelper.formatRelativeTime(log.date),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9C7B5E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      log.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF3D2B1F),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description — max 2 lines
                    Text(
                      log.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9C7B5E),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (isOwner)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: Color(0xFFD4956A), size: 18),
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded,
                          color: Colors.red.shade300, size: 18),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red.shade600,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Hapus item ini?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tindakan ini tidak dapat dibatalkan. Item akan dihapus secara permanen.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                            actions: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Batal'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        onDelete();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        foregroundColor: Colors.red.shade700,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Ya, Hapus',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                          },
                        );
                      },
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
