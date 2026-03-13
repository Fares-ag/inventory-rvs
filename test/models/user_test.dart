import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_system/models/user.dart';

void main() {
  group('User', () {
    test('fromMap and toMap round-trip', () {
      final map = {
        'id': 'u1',
        'username': 'jane',
        'email': 'jane@example.com',
        'password_hash': 'hash',
        'role': 'admin',
        'full_name': 'Jane Doe',
        'created_at': '2024-01-01T00:00:00.000Z',
      };
      final user = User.fromMap(map);
      expect(user.id, 'u1');
      expect(user.username, 'jane');
      expect(user.email, 'jane@example.com');
      expect(user.role, UserRole.admin);
      expect(user.fullName, 'Jane Doe');

      final out = user.toMap();
      expect(out['username'], 'jane');
      expect(out['role'], 'admin');
    });

    test('role parsing', () {
      final staffMap = {
        'username': 'a',
        'email': 'a@b.com',
        'password_hash': '',
        'role': 'staff',
        'created_at': '2024-01-01T00:00:00.000Z',
      };
      expect(User.fromMap(staffMap).role, UserRole.staff);
      final viewerMap = Map<String, dynamic>.from(staffMap)..['role'] = 'viewer';
      expect(User.fromMap(viewerMap).role, UserRole.viewer);
    });

    test('canEdit and canManageUsers', () {
      final admin = User(
        id: '1',
        username: 'a',
        email: 'a@b.com',
        passwordHash: '',
        role: UserRole.admin,
      );
      final staff = User(
        id: '2',
        username: 'b',
        email: 'b@b.com',
        passwordHash: '',
        role: UserRole.staff,
      );
      final viewer = User(
        id: '3',
        username: 'c',
        email: 'c@b.com',
        passwordHash: '',
        role: UserRole.viewer,
      );
      expect(admin.canEdit, true);
      expect(admin.canManageUsers, true);
      expect(staff.canEdit, true);
      expect(staff.canManageUsers, false);
      expect(viewer.canEdit, false);
      expect(viewer.canManageUsers, false);
    });
  });
}
