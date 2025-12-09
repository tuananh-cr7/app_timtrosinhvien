import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

/// Entry point dành cho Admin app.
/// Chạy: flutter run -d chrome --target lib/main_admin.dart
/// Build: flutter build web --target lib/main_admin.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
        useMaterial3: true,
      ),
      home: const AdminGate(),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.black.withOpacity(0.3),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Kiểm tra đăng nhập và quyền admin (custom claim "admin": true).
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  User? _user;
  bool _checkingClaims = false;
  bool _isAllowed = false;
  String? _role;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((u) {
      setState(() {
        _user = u;
        _isAllowed = false;
        _role = null;
      });
      if (u != null) _checkClaims(u);
    });
  }

  Future<void> _checkClaims(User user) async {
    setState(() => _checkingClaims = true);
    try {
      final token = await user.getIdTokenResult(true);
      final claims = token.claims ?? {};
      final adminFlag = claims['admin'] == true;
      final role = claims['role'] as String?;
      final allowRole = role == 'admin' || role == 'super_admin';
      setState(() {
        _isAllowed = adminFlag || allowRole;
        _role = role;
      });
    } catch (_) {
      setState(() {
        _isAllowed = false;
        _role = null;
      });
    } finally {
      if (mounted) setState(() => _checkingClaims = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const AdminLoginPage();
    }

    if (_checkingClaims) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAllowed) {
      return _MessageScaffold(
        title: 'Không có quyền admin',
        message:
            'Tài khoản hiện tại không có quyền admin/role phù hợp (admin/super_admin).',
        onSignOut: _signOut,
      );
    }

    return AdminHome(role: _role);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

class AdminHome extends StatefulWidget {
  final String? role;
  const AdminHome({super.key, this.role});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardPlaceholder(),
      const _UsersPage(),
      const _RoomsPage(),
      const _ReportsPage(),
    ];
    final titles = ['Dashboard', 'Người dùng', 'Quản lý tin', 'Báo cáo'];
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            role: widget.role,
            isWide: isWide,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titles[_selectedIndex],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          if (widget.role != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Role: ${widget.role}',
                                style: const TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            tooltip: 'Đăng xuất',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F7FB),
                    child: pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _StatCard(title: 'Tổng user', value: '—'),
              _StatCard(title: 'Tổng tin đăng', value: '—'),
              _StatCard(title: 'Tin chờ duyệt', value: '—'),
              _StatCard(title: 'Báo cáo mới', value: '—'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              'Hoạt động gần đây (sẽ cập nhật sau).',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trang quản lý người dùng: list + ban/unban.
class _UsersPage extends StatefulWidget {
  const _UsersPage();

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  final _searchController = TextEditingController();

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _baseQuery() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();
    final keyword = _normalize(_searchController.text.trim());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Tìm theo tên hoặc email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              var docs = snapshot.data?.docs ?? [];
              if (keyword.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data();
                  final name = _normalize(data['displayName'] as String? ?? '');
                  final email = _normalize(data['email'] as String? ?? '');
                  return name.contains(keyword) || email.contains(keyword);
                }).toList();
              }
              if (docs.isEmpty) {
                return const Center(child: Text('Không có người dùng.'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final displayName = data['displayName'] as String? ?? 'Chưa có tên';
                  final email = data['email'] as String? ?? '';
                  final phone = data['phoneNumber'] as String? ?? '';
                  final role = data['role'] as String?;
                  final banned = data['banned'] == true;
                  final uid = doc.id;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (displayName.isNotEmpty ? displayName[0] : '?').toUpperCase(),
                      ),
                    ),
                    title: Text(displayName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (email.isNotEmpty) Text(email),
                        if (phone.isNotEmpty) Text(phone),
                        Row(
                          children: [
                            _StatusChip(
                              label: banned ? 'Đã khóa' : 'Hoạt động',
                              color: banned ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(
                              label: role != null ? 'Role: $role' : 'Role: user',
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 8),
                            _StatusChip(
                              label: 'UID: $uid',
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: banned ? Colors.green : Colors.red,
                      ),
                      onPressed: () => _toggleBan(uid, banned),
                      child: Text(banned ? 'Mở khóa' : 'Khóa'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Query<Map<String, dynamic>> _buildQuery() {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return _baseQuery().limit(50);
    // Với Firestore client-side filter: lấy 100 docs rồi filter tạm.
    return _baseQuery().limit(100);
  }

  Future<void> _toggleBan(String uid, bool isBanned) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'banned': !isBanned,
        'bannedAt': !isBanned ? FieldValue.serverTimestamp() : null,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(!isBanned ? 'Đã khóa user' : 'Đã mở khóa user')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}

/// Trang quản lý tin đăng: pending/active/rejected/hidden + duyệt/từ chối/ẩn/xóa.
class _RoomsPage extends StatefulWidget {
  const _RoomsPage();

  @override
  State<_RoomsPage> createState() => _RoomsPageState();
}

/// Trang quản lý báo cáo: pending/resolved/rejected + xử lý.
class _ReportsPage extends StatefulWidget {
  const _ReportsPage();

  @override
  State<_ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<_ReportsPage> {
  final _searchController = TextEditingController();
  final List<String> _statusFilters = ['pending', 'resolved', 'rejected'];
  String _currentStatus = 'pending';
  bool _indexError = false;
  String? _indexLink;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: _currentStatus)
        .orderBy('createdAt', descending: true)
        .limit(100);
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _searchController.text.trim().toLowerCase();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm theo tiêu đề/room/reporter',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: keyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: _statusFilters.map((s) {
                  final selected = _currentStatus == s;
                  return ChoiceChip(
                    label: Text(_statusText(s)),
                    selected: selected,
                    onSelected: (_) => setState(() => _currentStatus = s),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _query().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final err = snapshot.error.toString();
                final link = _extractIndexLink(err);
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lỗi tải báo cáo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(err, style: const TextStyle(color: Colors.red)),
                      if (link != null) ...[
                        const SizedBox(height: 8),
                        SelectableText('Tạo index tại: $link',
                            style: const TextStyle(color: Colors.blue)),
                        const SizedBox(height: 4),
                        const Text(
                          'Hoặc vào Firestore Console > Indexes, tạo index cho collection "reports": status (ASC), createdAt (DESC).',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                );
              }
              var docs = snapshot.data?.docs ?? [];
              if (keyword.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data();
                  final title = (data['title'] as String? ?? '').toLowerCase();
                  final roomId = (data['roomId'] as String? ?? '').toLowerCase();
                  final reporter = (data['reporterEmail'] as String? ?? '')
                      .toLowerCase();
                  return title.contains(keyword) ||
                      roomId.contains(keyword) ||
                      reporter.contains(keyword);
                }).toList();
              }
              if (docs.isEmpty) {
                return const Center(child: Text('Không có báo cáo.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  return _ReportCard(
                    id: doc.id,
                    title: data['title'] as String? ?? 'Báo cáo',
                    content: data['content'] as String? ?? '',
                    roomId: data['roomId'] as String? ?? '—',
                    roomTitle: data['roomTitle'] as String? ?? '',
                    reporterEmail: data['reporterEmail'] as String? ?? '—',
                    reporterId: data['reporterId'] as String? ?? '—',
                    status: data['status'] as String? ?? 'pending',
                    type: data['type'] as String? ?? 'general',
                    createdAt: data['createdAt']?.toDate(),
                    onResolve: () => _updateStatus(doc.id, 'resolved'),
                    onReject: () => _updateStatus(doc.id, 'rejected'),
                    onDelete: () => _deleteReport(doc.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(String reportId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật báo cáo: $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _deleteReport(String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa báo cáo?'),
        content:
            const Text('Bạn có chắc muốn xóa báo cáo này? Hành động không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa báo cáo')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String? _extractIndexLink(String err) {
    final idx = err.indexOf('https://console.firebase.google.com');
    if (idx == -1) return null;
    final space = err.indexOf(' ', idx);
    return err.substring(idx, space == -1 ? err.length : space);
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'resolved':
        return 'Đã xử lý';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return status;
    }
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.id,
    required this.title,
    required this.content,
    required this.roomId,
    required this.roomTitle,
    required this.reporterEmail,
    required this.reporterId,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.onResolve,
    required this.onReject,
    required this.onDelete,
  });

  final String id;
  final String title;
  final String content;
  final String roomId;
  final String roomTitle;
  final String reporterEmail;
  final String reporterId;
  final String status;
  final String type;
  final DateTime? createdAt;
  final VoidCallback onResolve;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _StatusChip(
                    label: 'Trạng thái: ${_statusText(status)}',
                    color: Colors.blueGrey),
                _StatusChip(label: 'Loại: $type', color: Colors.teal),
                _StatusChip(
                  label: 'Phòng: ${roomTitle.isNotEmpty ? roomTitle : roomId}',
                  color: Colors.indigo,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Text('Room ID: $roomId',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text('Người báo cáo: $reporterEmail (UID: $reporterId)',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            if (createdAt != null)
              Text('Thời gian: ${_formatDate(createdAt!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onResolve,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Đã xử lý'),
                ),
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.block_outlined),
                  label: const Text('Từ chối'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Xóa',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'resolved':
        return 'Đã xử lý';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return status;
    }
  }
}

class _RoomsPageState extends State<_RoomsPage> {
  final _searchController = TextEditingController();
  final List<String> _statusFilters = ['pending', 'active', 'rejected', 'hidden'];
  String _currentStatus = 'pending';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _query() {
    var q = FirebaseFirestore.instance
        .collection('rooms')
        .where('status', isEqualTo: _currentStatus)
        .orderBy('createdAt', descending: true)
        .limit(100);
    return q;
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _searchController.text.trim().toLowerCase();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Tìm theo tiêu đề hoặc chủ tin',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: keyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: _statusFilters.map((s) {
                  final selected = _currentStatus == s;
                  return ChoiceChip(
                    label: Text(_statusText(s)),
                    selected: selected,
                    onSelected: (_) => setState(() => _currentStatus = s),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _query().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              var docs = snapshot.data?.docs ?? [];
              if (keyword.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data();
                  final title = (data['title'] as String? ?? '').toLowerCase();
                  final owner = (data['ownerName'] as String? ?? '').toLowerCase();
                  return title.contains(keyword) || owner.contains(keyword);
                }).toList();
              }
              if (docs.isEmpty) {
                return const Center(child: Text('Không có tin phù hợp.'));
              }
              return ListView.builder(
                itemCount: docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final title = data['title'] as String? ?? '—';
                  final ownerName = data['ownerName'] as String? ?? '—';
                  final ownerId = data['ownerId'] as String? ?? '—';
                  final status = data['status'] as String? ?? 'pending';
                  final price = (data['priceMillion'] ?? 0).toDouble();
                  final area = (data['area'] ?? 0).toDouble();
                  final createdAt = data['createdAt']?.toDate();
                  final thumb = data['thumbnailUrl'] as String? ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openDetail(context, title, data),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: thumb.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: thumb,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 480,
                                      memCacheHeight: 480,
                                      placeholder: (_, __) => Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.image_not_supported),
                                      ),
                                    )
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _StatusChip(
                                          label: 'Trạng thái: ${_statusText(status)}',
                                          color: Colors.blueGrey),
                                      _StatusChip(
                                        label: '${price.toStringAsFixed(1)} triệu/tháng',
                                        color: Colors.indigo,
                                      ),
                                      _StatusChip(
                                        label: '${area.toStringAsFixed(1)} m²',
                                        color: Colors.teal,
                                      ),
                                      if (data['isShared'] == true)
                                        _StatusChip(label: 'Ở ghép', color: Colors.orange),
                                      if (data['roomType'] != null)
                                        _StatusChip(label: 'Loại: ${data['roomType']}', color: Colors.teal),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    title,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  if (data['address'] != null)
                                    Text(
                                      data['address'],
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  const SizedBox(height: 4),
                                  Text('Chủ tin: $ownerName  •  UID: $ownerId',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  if (createdAt != null)
                                    Text(
                                      'Ngày đăng: ${_formatDate(createdAt)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildActions(context, doc.id, status),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, String roomId, String status) {
    return Wrap(
      spacing: 10,
      children: [
        if (status == 'pending' || status == 'rejected' || status == 'hidden')
          TextButton(
            onPressed: () => _updateStatus(roomId, 'active'),
            child: const Text('Duyệt'),
          ),
        if (status == 'pending' || status == 'active')
          TextButton(
            onPressed: () => _updateStatus(roomId, 'rejected'),
            child: const Text('Từ chối'),
          ),
        if (status == 'active')
          TextButton(
            onPressed: () => _updateStatus(roomId, 'hidden'),
            child: const Text('Ẩn'),
          ),
        TextButton(
          onPressed: () => _deleteRoom(roomId),
          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, String title, Map<String, dynamic> data) {
    final thumb = data['thumbnailUrl'] as String? ?? '';
    final images = (data['images'] as List<dynamic>? ?? []).cast<String>();
    final photos = (data['photos'] as List<dynamic>? ?? []).cast<String>();
    final imageUrls = (data['imageUrls'] as List<dynamic>? ?? []).cast<String>();
    // Gộp thumbnail + images, bỏ trùng rỗng
    final merged = <String>[
      if (thumb.isNotEmpty) thumb,
      ...images.where((e) => e.isNotEmpty),
      ...photos.where((e) => e.isNotEmpty),
      ...imageUrls.where((e) => e.isNotEmpty),
    ].toSet().toList();
    final desc = data['description'] as String? ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 500,
          height: merged.isNotEmpty ? 420 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (merged.isNotEmpty)
                Expanded(
                  child: _ImagePager(urls: merged),
                ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(desc),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'active':
        return 'Đang hiển thị';
      case 'rejected':
        return 'Từ chối';
      case 'hidden':
        return 'Ẩn';
      default:
        return status;
    }
  }

  Future<void> _updateStatus(String roomId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái: $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin?'),
        content: const Text('Bạn có chắc muốn xóa tin này? Hành động không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa tin')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}

class _ImagePager extends StatefulWidget {
  const _ImagePager({required this.urls});
  final List<String> urls;

  @override
  State<_ImagePager> createState() => _ImagePagerState();
}

class _ImagePagerState extends State<_ImagePager> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final url = urls[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            memCacheWidth: 1280,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined, size: 40),
                            ),
                          ),
                        ),
                    ),
                    if (urls.length > 1) ...[
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: _NavBtn(
                          icon: Icons.chevron_left,
                          onTap: () => _goTo(_page - 1, urls.length),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: _NavBtn(
                          icon: Icons.chevron_right,
                          onTap: () => _goTo(_page + 1, urls.length),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        if (urls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              urls.length,
              (i) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page ? Colors.blueAccent : Colors.grey.shade400,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _goTo(int index, int len) {
    if (len <= 1) return;
    int next = index;
    if (next < 0) next = len - 1;
    if (next >= len) next = 0;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
    setState(() => _page = next);
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String? role;
  final bool isWide;

  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.role,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem('Dashboard', Icons.dashboard_outlined),
      _NavItem('Người dùng', Icons.people_alt_outlined),
      _NavItem('Quản lý tin', Icons.home_work_outlined),
      _NavItem('Báo cáo', Icons.report_problem_outlined),
    ];
    return Container(
      width: isWide ? 240 : 90,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2E8BC0),
            Color(0xFF145DA0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 16 : 8,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment:
                    isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_moon, color: Colors.white, size: 28),
                  if (isWide) ...[
                    const SizedBox(width: 10),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return InkWell(
                    onTap: () => onSelect(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isWide ? 12 : 8,
                        vertical: 6,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 14 : 0,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: isWide
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Icon(item.icon,
                              color: Colors.white,
                              size: selected ? 22 : 20),
                          if (isWide) ...[
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isWide && role != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Role: $role',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  _NavItem(this.label, this.icon);
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF145DA0),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageScaffold extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onSignOut;

  const _MessageScaffold({
    required this.title,
    required this.message,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onSignOut != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: onSignOut,
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Form đăng nhập email/password cho admin app.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập Admin')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đăng nhập'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

