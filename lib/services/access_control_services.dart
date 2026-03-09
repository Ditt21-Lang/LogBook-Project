import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlServices {
  static List<String> get availableRoles => 
    dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];
  
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  //Perizinan
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionDelete, actionUpdate],
    'Anggota': [actionCreate, actionRead],
    'Asisten': [actionRead, actionUpdate],
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // Permission decision is fully role-based.
    // `isOwner` is kept for API compatibility but does not override role rules.
    final permissions = _rolePermissions[role] ?? [];
    if (permissions.contains(action)) return true;

    return false;
  }
}
