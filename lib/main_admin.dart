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

List<String> _mergeImages(String? thumb, List<String>? images) {
  final all = <String>[
    if (thumb != null && thumb.isNotEmpty) thumb,
    if (images != null) ...images.where((e) => e.isNotEmpty),
  ];
  return all.toSet().toList();
}

// Chuẩn hóa tiếng Việt: bỏ dấu + chữ thường để tìm kiếm không dấu
String normalizeVietnamese(String text) {
  text = text.toLowerCase();
  text = text
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll(RegExp(r'[đ]'), 'd');
  return text;
}

void _showImagesDialog(BuildContext context, List<String> urls) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: SizedBox(
        width: 500,
        height: 400,
        child: _ReportImagePager(urls: urls),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

Future<void> _openImages(
  BuildContext context,
  List<String> mergedImages,
  String roomId,
) async {
  var urls = mergedImages;
  // Nếu chưa có ảnh hoặc chỉ có 1 ảnh, thử lấy thêm từ rooms để lướt được nhiều hơn
  if (roomId.isNotEmpty && urls.length < 2) {
    // Fallback: fetch ảnh từ rooms nếu report không lưu kèm
    try {
      final doc =
          await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
      final data = doc.data();
      if (data != null) {
        final thumb = data['thumbnailUrl'] as String?;
        final images = (data['images'] as List<dynamic>?)?.cast<String>();
        final photos = (data['photos'] as List<dynamic>?)?.cast<String>();
        final imageUrls = (data['imageUrls'] as List<dynamic>?)?.cast<String>();
        urls = _mergeImages(thumb, [
          ...?images,
          ...?photos,
          ...?imageUrls,
        ]);
      }
    } catch (_) {
      // ignore fetch errors, sẽ show "Không có ảnh"
    }
  }
  _showImagesDialog(context, urls);
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
    final isSuperAdmin = widget.role == 'super_admin';
    final pages = [
      const _DashboardPage(),
      _UsersPage(isSuperAdmin: isSuperAdmin),
      _RoomsPage(isSuperAdmin: isSuperAdmin),
      _ReviewsPage(isSuperAdmin: isSuperAdmin),
      _ReportsPage(isSuperAdmin: isSuperAdmin),
      const _DashboardPage(), // Trang Thống kê riêng (đặt cuối)
    ];
    final titles = [
      'Dashboard',
      'Người dùng',
      'Quản lý tin',
      'Đánh giá',
      'Báo cáo',
      'Thống kê'
    ];
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

class _DashboardPage extends StatefulWidget {
  const _DashboardPage();

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;

  int _userCount = 0;
  int _roomsActive = 0;
  int _roomsPending = 0;
  int _roomsHiddenRejected = 0;
  int _reportsPending = 0;
  int _reviewsCount = 0;
  double _avgRating = 0;
  int _reviewsLast7d = 0;

  List<_BarData> _roomsPerDay = [];
  List<_BarData> _usersPerDay = [];
  List<_BarData> _reviewStars = [];
  List<_BarData> _reportTypes = [];
  List<_AdminLogItem> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMessage = null;
    });
    try {
      final fs = FirebaseFirestore.instance;

      // Tổng quan
      final usersCountSnap = await fs.collection('users').count().get();
      final activeRoomsSnap =
          await fs.collection('rooms').where('status', isEqualTo: 'active').count().get();
      final pendingRoomsSnap =
          await fs.collection('rooms').where('status', isEqualTo: 'pending').count().get();
      final hiddenRejectedSnap = await fs
          .collection('rooms')
          .where('status', whereIn: ['hidden', 'rejected']).count().get();
      final reportsPendingSnap =
          await fs.collection('reports').where('status', isEqualTo: 'pending').count().get();
      // Reviews: tổng số và điểm TB (lấy tối đa 500 review để tính)
      final reviewsSnap =
          await fs.collectionGroup('reviews').limit(500).get(); // giới hạn để tránh tải lớn
      int reviewsCount = 0;
      double ratingSum = 0;
      for (final doc in reviewsSnap.docs) {
        final rating = (doc.data()['rating'] as num?)?.toDouble();
        if (rating != null) {
          reviewsCount++;
          ratingSum += rating;
        }
      }
      final avgRating = reviewsCount > 0 ? ratingSum / reviewsCount : 0;

      // Biểu đồ đơn giản: số tin đăng / user mới 7 ngày gần đây
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final roomsRecentSnap = await fs
          .collection('rooms')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .get();
      final usersRecentSnap = await fs
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .get();
      QuerySnapshot<Map<String, dynamic>> reviewsRecentSnap;
      try {
        reviewsRecentSnap = await fs
            .collectionGroup('reviews')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
            .get();
      } catch (e) {
        // Nếu thiếu index, fallback lấy tối đa 200 review (không filter thời gian)
        print('⚠️ reviewsRecentSnap fallback do index: $e');
        reviewsRecentSnap = await fs.collectionGroup('reviews').limit(200).get();
      }
      QuerySnapshot<Map<String, dynamic>> reportsRecentSnap;
      try {
        reportsRecentSnap = await fs
            .collection('reports')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
            .get();
      } catch (e) {
        // Fallback nếu thiếu index cho reports (hiếm gặp)
        print('⚠️ reportsRecentSnap fallback do index: $e');
        reportsRecentSnap = await fs.collection('reports').limit(200).get();
      }

      final Map<String, int> roomsPerDay = {};
      final Map<String, int> usersPerDay = {};
      final Map<int, int> reviewStarCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      final Map<String, int> reportTypeCount = {};
      for (int i = 0; i < 7; i++) {
        final day = from.add(Duration(days: i));
        final key = '${day.month}/${day.day}';
        roomsPerDay[key] = 0;
        usersPerDay[key] = 0;
      }

      for (final doc in roomsRecentSnap.docs) {
        final ts = doc.data()['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final d = ts.toDate();
        final key = '${d.month}/${d.day}';
        if (roomsPerDay.containsKey(key)) {
          roomsPerDay[key] = (roomsPerDay[key] ?? 0) + 1;
        }
      }
      for (final doc in usersRecentSnap.docs) {
        final ts = doc.data()['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final d = ts.toDate();
        final key = '${d.month}/${d.day}';
        if (usersPerDay.containsKey(key)) {
          usersPerDay[key] = (usersPerDay[key] ?? 0) + 1;
        }
      }
      for (final doc in reviewsRecentSnap.docs) {
        final rating = (doc.data()['rating'] as num?)?.toInt();
        if (rating != null && rating >= 1 && rating <= 5) {
          reviewStarCount[rating] = (reviewStarCount[rating] ?? 0) + 1;
        }
      }
      for (final doc in reportsRecentSnap.docs) {
        final type = (doc.data()['type'] as String? ?? 'Khác').toLowerCase();
        reportTypeCount[type] = (reportTypeCount[type] ?? 0) + 1;
      }

      final roomsBars = roomsPerDay.entries
          .map((e) => _BarData(label: e.key, value: e.value.toDouble()))
          .toList();
      final usersBars = usersPerDay.entries
          .map((e) => _BarData(label: e.key, value: e.value.toDouble()))
          .toList();
      final reviewStarBars = reviewStarCount.entries
          .map((e) => _BarData(label: '${e.key}★', value: e.value.toDouble()))
          .toList();
      final reportTypeBars = reportTypeCount.entries
          .map((e) => _BarData(label: e.key, value: e.value.toDouble()))
          .toList();

      // Hoạt động gần đây: lấy 10 log mới nhất
      final logsSnap = await fs
          .collection('adminLogs')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      final logs = logsSnap.docs.map((doc) {
        final data = doc.data();
        return _AdminLogItem(
          action: data['action'] as String? ?? '',
          adminId: data['adminId'] as String? ?? '',
          targetType: data['targetType'] as String? ?? '',
          targetId: data['targetId'] as String? ?? '',
          note: data['note'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        );
      }).toList();

      setState(() {
        _userCount = usersCountSnap.count ?? 0;
        _roomsActive = activeRoomsSnap.count ?? 0;
        _roomsPending = pendingRoomsSnap.count ?? 0;
        _roomsHiddenRejected = hiddenRejectedSnap.count ?? 0;
        _reportsPending = reportsPendingSnap.count ?? 0;
        _reviewsCount = reviewsCount;
        _avgRating = avgRating.toDouble();
        _reviewsLast7d = reviewsRecentSnap.docs.length;
        _roomsPerDay = roomsBars;
        _usersPerDay = usersBars;
        _reviewStars = reviewStarBars;
        _reportTypes = reportTypeBars;
        _recentLogs = logs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            const Text('Lỗi tải Dashboard'),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(title: 'Tổng user', value: '$_userCount'),
                _StatCard(title: 'Tin đang hiển thị', value: '$_roomsActive'),
                _StatCard(title: 'Tin chờ duyệt', value: '$_roomsPending'),
                _StatCard(title: 'Tin ẩn / từ chối', value: '$_roomsHiddenRejected'),
                _StatCard(title: 'Báo cáo mới', value: '$_reportsPending'),
                _StatCard(title: 'Tổng đánh giá', value: '$_reviewsCount'),
                _StatCard(
                  title: 'Điểm TB',
                  value: _avgRating.toStringAsFixed(1),
                ),
                _StatCard(title: 'Đánh giá 7 ngày', value: '$_reviewsLast7d'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SimpleBarChart(
                    title: 'Tin đăng 7 ngày gần đây',
                    subtitle: 'Số tin mới mỗi ngày',
                    bars: _roomsPerDay,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SimpleBarChart(
                    title: 'User mới 7 ngày gần đây',
                    subtitle: 'Số user đăng ký mỗi ngày',
                    bars: _usersPerDay,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SimpleBarChart(
                    title: 'Phân bố đánh giá (7 ngày)',
                    subtitle: 'Số lượt theo sao',
                    bars: _reviewStars,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SimpleBarChart(
                    title: 'Báo cáo theo loại (7 ngày)',
                    subtitle: 'Đếm theo trường type',
                    bars: _reportTypes,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _RecentActivityCard(logs: _recentLogs),
          ],
        ),
      ),
    );
  }
}

/// Trang quản lý người dùng: list + ban/unban.
class _UsersPage extends StatefulWidget {
  const _UsersPage({required this.isSuperAdmin});

  final bool isSuperAdmin;

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  final _searchController = TextEditingController();

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
    final keyword = normalizeVietnamese(_searchController.text.trim());
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
                  final name =
                      normalizeVietnamese(data['displayName'] as String? ?? '');
                  final email =
                      normalizeVietnamese(data['email'] as String? ?? '');
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
      await _addAdminLog(
        action: isBanned ? 'unban_user' : 'ban_user',
        targetType: 'user',
        targetId: uid,
      );
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
  const _RoomsPage({required this.isSuperAdmin});

  final bool isSuperAdmin;

  @override
  State<_RoomsPage> createState() => _RoomsPageState();
}

/// Trang quản lý báo cáo: pending/resolved/rejected + xử lý.
class _ReportsPage extends StatefulWidget {
  const _ReportsPage({required this.isSuperAdmin});

  final bool isSuperAdmin;

  @override
  State<_ReportsPage> createState() => _ReportsPageState();
}

/// Trang quản lý đánh giá phòng: xem và xóa review (collectionGroup reviews).
class _ReviewsPage extends StatefulWidget {
  const _ReviewsPage({required this.isSuperAdmin});

  final bool isSuperAdmin;

  @override
  State<_ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<_ReviewsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collectionGroup('reviews')
        // Thêm orderBy phụ để composite index rõ ràng, tránh cảnh báo single-field
        .orderBy('createdAt', descending: true)
        .orderBy('userId')
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
                    labelText: 'Tìm theo roomId / email / nội dung',
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
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi tải đánh giá: $err',
                      style: const TextStyle(color: Colors.red)),
                );
              }
              var docs = snapshot.data?.docs ?? [];
              if (keyword.isNotEmpty) {
                final normalizedKeyword = normalizeVietnamese(keyword);
                docs = docs.where((doc) {
                  final data = doc.data();
                  final email = (data['userEmail'] as String? ?? '').toLowerCase();
                  final comment =
                      (data['comment'] as String? ?? '').toLowerCase();
                  final emailNorm = normalizeVietnamese(email);
                  final commentNorm = normalizeVietnamese(comment);
                  return emailNorm.contains(normalizedKeyword) ||
                      commentNorm.contains(normalizedKeyword);
                }).toList();
              }
              if (docs.isEmpty) {
                return const Center(child: Text('Không có đánh giá.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  return _ReviewCard(
                    docId: doc.id,
                    rating: (data['rating'] as num?)?.toInt() ?? 0,
                    comment: data['comment'] as String? ?? '',
                    roomId: data['roomId'] as String? ?? '',
                    userEmail: data['userEmail'] as String? ?? '',
                    userId: data['userId'] as String? ?? '',
                    createdAt: data['createdAt']?.toDate(),
                    onDelete: () => _deleteReview(doc.reference),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteReview(DocumentReference<Map<String, dynamic>> ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đánh giá?'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final snap = await ref.get();
      final data = snap.data();
      final reviewerId = (data?['userId'] as String? ?? '').isNotEmpty
          ? (data?['userId'] as String)
          : ref.id; // fallback docId = userId
      final roomId = (data?['roomId'] as String? ?? '').isNotEmpty
          ? (data?['roomId'] as String)
          : (ref.parent.parent?.id ?? '');
      var roomTitle = '';
      if (roomId.isNotEmpty) {
        try {
          final roomSnap =
              await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
          roomTitle = roomSnap.data()?['title'] as String? ?? '';
        } catch (_) {}
      }

      await ref.delete();
      await _addAdminLog(
        action: 'delete_review',
        targetType: 'review',
        targetId: ref.path,
      );
      if (reviewerId.isNotEmpty && roomId.isNotEmpty) {
        try {
          await _sendReviewDeletedNotification(
            reviewerId: reviewerId,
            roomId: roomId,
            roomTitle: roomTitle,
          );
          print(
              '✅ Sent review_removed notification to uid=$reviewerId roomId=$roomId title="$roomTitle"');
        } catch (e) {
          print('❌ Send review_removed notification failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gửi thông báo gỡ đánh giá lỗi: $e')),
            );
          }
        }
      } else {
        print(
            '⚠️ Skip review_removed notification, reviewerId="$reviewerId", roomId="$roomId"');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa đánh giá.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _sendReviewDeletedNotification({
    required String reviewerId,
    required String roomId,
    required String roomTitle,
  }) async {
    print('🔔 _sendReviewDeletedNotification -> reviewerId=$reviewerId roomId=$roomId title="$roomTitle"');
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': reviewerId,
      'type': 'review_removed',
      'title': 'Đánh giá của bạn bị gỡ',
      'body': roomTitle.isNotEmpty
          ? 'Đánh giá cho "$roomTitle" đã bị gỡ bởi quản trị viên.'
          : 'Một đánh giá của bạn đã bị gỡ bởi quản trị viên.',
      'roomId': roomId,
      'roomTitle': roomTitle,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'roomId': roomId,
        'roomTitle': roomTitle,
      },
    });
  }
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
                    roomThumbnailUrl: data['roomThumbnailUrl'] as String?,
                    roomPriceMillion:
                        (data['roomPriceMillion'] as num?)?.toDouble(),
                    roomArea: (data['roomArea'] as num?)?.toDouble(),
                    roomIsShared: data['roomIsShared'] as bool?,
                    roomType: data['roomType'] as String?,
                    reporterEmail: data['reporterEmail'] as String? ?? '—',
                    reporterId: data['reporterId'] as String? ?? '—',
                    status: data['status'] as String? ?? 'pending',
                    type: data['type'] as String? ?? 'general',
                    createdAt: data['createdAt']?.toDate(),
                    canDelete: widget.isSuperAdmin,
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
      await _addAdminLog(
        action: 'update_report_status_$newStatus',
        targetType: 'report',
        targetId: reportId,
      );
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
      await _addAdminLog(
        action: 'delete_report',
        targetType: 'report',
        targetId: reportId,
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

class _ReportImagePager extends StatefulWidget {
  const _ReportImagePager({required this.urls});

  final List<String> urls;

  @override
  State<_ReportImagePager> createState() => _ReportImagePagerState();
}

class _ReportImagePagerState extends State<_ReportImagePager> {
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

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.isEmpty) {
      return const Center(child: Text('Không có ảnh'));
    }
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  final url = urls[index];
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) =>
                        const Center(child: Icon(Icons.image_not_supported)),
                  );
                },
              ),
              if (urls.length > 1) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _NavArrow(
                    icon: Icons.chevron_left,
                    enabled: _page > 0,
                    onTap: () {
                      if (_page > 0) _goTo(_page - 1);
                    },
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _NavArrow(
                    icon: Icons.chevron_right,
                    enabled: _page < urls.length - 1,
                    onTap: () {
                      if (_page < urls.length - 1) _goTo(_page + 1);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(urls.length, (i) {
            final selected = i == _page;
            return GestureDetector(
              onTap: () => _goTo(i),
              child: Container(
                width: selected ? 10 : 8,
                height: selected ? 10 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? Colors.indigo : Colors.grey.shade400,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String docId;
  final int rating;
  final String comment;
  final String roomId;
  final String userEmail;
  final String userId;
  final DateTime? createdAt;
  final VoidCallback onDelete;

  const _ReviewCard({
    required this.docId,
    required this.rating,
    required this.comment,
    required this.roomId,
    required this.userEmail,
    required this.userId,
    required this.createdAt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('rooms').doc(roomId).get(),
      builder: (context, snapshot) {
        final roomData = snapshot.data?.data();
        final roomTitle = (roomData?['title'] as String?) ?? roomId;
        final thumb = roomData?['thumbnailUrl'] as String?;
        final images =
            (roomData?['images'] as List<dynamic>?)?.cast<String>();
        final photos =
            (roomData?['photos'] as List<dynamic>?)?.cast<String>();
        final imageUrls =
            (roomData?['imageUrls'] as List<dynamic>?)?.cast<String>();
        final mergedImages = _mergeImages(thumb, [
          ...?images,
          ...?photos,
          ...?imageUrls,
        ]);
        final price = (roomData?['priceMillion'] as num?)?.toDouble();
        final area = (roomData?['area'] as num?)?.toDouble();
        final isShared = roomData?['isShared'] as bool?;
        final type = roomData?['roomType'] as String?;

        final priceText =
            price != null ? '${price.toStringAsFixed(1)} triệu/tháng' : null;
        final areaText =
            area != null ? '${area.toStringAsFixed(0)} m²' : null;
        final isSharedText =
            isShared == true ? 'Ở ghép' : (type ?? '').toString();

        final hasThumb = thumb != null && thumb.isNotEmpty;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail phòng (nếu có)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: hasThumb
                      ? InkWell(
                          onTap: () =>
                              _openImages(context, mergedImages, roomId),
                          child: CachedNetworkImage(
                            imageUrl: thumb!,
                            width: 110,
                            height: 90,
                            fit: BoxFit.cover,
                            memCacheWidth: 320,
                            placeholder: (_, __) => Container(
                              width: 110,
                              height: 90,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 110,
                              height: 90,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        )
                      : Container(
                          width: 110,
                          height: 90,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                const SizedBox(width: 12),
                // Nội dung đánh giá
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            roomTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Xóa đánh giá',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Thông tin phòng (giá, diện tích, loại) đặt lên trên cho dễ nhìn
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (priceText != null)
                            _StatusChip(
                              label: priceText,
                              color: Colors.indigo,
                            ),
                          if (areaText != null)
                            _StatusChip(
                              label: areaText,
                              color: Colors.teal,
                            ),
                          if (isSharedText.isNotEmpty)
                            _StatusChip(
                              label: isSharedText,
                              color: Colors.deepOrange,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Đánh giá:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ...List.generate(5, (i) {
                              return Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (comment.isNotEmpty) Text(comment),
                      const SizedBox(height: 6),
                      Text(
                        'Người viết: ${userEmail.isNotEmpty ? userEmail : userId}',
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 12),
                      ),
                      if (createdAt != null)
                        Text(
                          'Ngày: ${createdAt!.day}/${createdAt!.month}/${createdAt!.year}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11),
                        ),
                      Text(
                        'Doc: $docId',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.3,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 48,
            color: Colors.black.withOpacity(0.08),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.id,
    required this.title,
    required this.content,
    required this.roomId,
    required this.roomTitle,
    this.roomThumbnailUrl,
    this.roomPriceMillion,
    this.roomArea,
    this.roomIsShared,
    this.roomType,
    this.roomImages,
    required this.reporterEmail,
    required this.reporterId,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.canDelete,
    required this.onResolve,
    required this.onReject,
    required this.onDelete,
  });

  final String id;
  final String title;
  final String content;
  final String roomId;
  final String roomTitle;
  final String? roomThumbnailUrl;
  final double? roomPriceMillion;
  final double? roomArea;
  final bool? roomIsShared;
  final String? roomType;
  final List<String>? roomImages;
  final String reporterEmail;
  final String reporterId;
  final String status;
  final String type;
  final DateTime? createdAt;
  final bool canDelete;
  final VoidCallback onResolve;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasThumb = roomThumbnailUrl != null && roomThumbnailUrl!.isNotEmpty;
    final mergedImages = _mergeImages(roomThumbnailUrl, roomImages);
    final priceText = roomPriceMillion != null
        ? '${roomPriceMillion!.toStringAsFixed(1)} triệu/tháng'
        : null;
    final areaText =
        roomArea != null ? '${roomArea!.toStringAsFixed(0)} m²' : null;
    final isSharedText =
        roomIsShared == true ? 'Ở ghép' : (roomType ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail phòng giống bên Quản lý tin
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: hasThumb
                        ? InkWell(
                            onTap: () => _openImages(context, mergedImages, roomId),
                            child: CachedNetworkImage(
                              imageUrl: roomThumbnailUrl!,
                              width: 110,
                              height: 90,
                              fit: BoxFit.cover,
                              memCacheWidth: 320,
                              placeholder: (_, __) => Container(
                                width: 110,
                                height: 90,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                width: 110,
                                height: 90,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          )
                        : Container(
                            width: 110,
                            height: 90,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported),
                          ),
                  ),
            const SizedBox(width: 12),
            // Thông tin báo cáo + phòng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _StatusChip(
                        label: _statusText(status),
                        color: status == 'pending'
                            ? Colors.orange
                            : status == 'resolved'
                                ? Colors.green
                                : Colors.red,
                      ),
                      _StatusChip(label: type, color: Colors.teal),
                      _StatusChip(
                        label: roomTitle.isNotEmpty ? roomTitle : roomId,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (priceText != null || areaText != null || isSharedText.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (priceText != null)
                          _StatusChip(
                            label: priceText,
                            color: Colors.indigo,
                          ),
                        if (areaText != null)
                          _StatusChip(
                            label: areaText,
                            color: Colors.teal,
                          ),
                        if (isSharedText.isNotEmpty)
                          _StatusChip(
                            label: isSharedText,
                            color: Colors.deepOrange,
                          ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
                  Text(
                    'Người báo cáo: $reporterEmail (UID: $reporterId)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  if (createdAt != null)
                    Text(
                      'Thời gian: ${_formatDate(createdAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
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
                      if (canDelete)
                        TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Xóa',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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
                  // Fallback: nếu thiếu ownerId (dữ liệu cũ), thử lấy userId
                  final ownerId =
                      (data['ownerId'] as String?) ?? (data['userId'] as String?) ?? '—';
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
                                    child: _buildActions(
                                      context,
                                      doc.id,
                                      ownerId,
                                      title,
                                      status,
                                    ),
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

  Widget _buildActions(
    BuildContext context,
    String roomId,
    String ownerId,
    String roomTitle,
    String status,
  ) {
    return Wrap(
      spacing: 10,
      children: [
        if (status == 'pending' || status == 'rejected' || status == 'hidden')
          TextButton(
            onPressed: () => _updateStatus(roomId, ownerId, 'active', roomTitle),
            child: const Text('Duyệt'),
          ),
        if (status == 'pending' || status == 'active')
          TextButton(
            onPressed: () => _updateStatus(roomId, ownerId, 'rejected', roomTitle),
            child: const Text('Từ chối'),
          ),
        if (status == 'active')
          TextButton(
            onPressed: () => _updateStatus(roomId, ownerId, 'hidden', roomTitle),
            child: const Text('Ẩn'),
          ),
        if (widget.isSuperAdmin)
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

  Future<void> _updateStatus(
    String roomId,
    String ownerId,
    String newStatus,
    String roomTitle,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Admin updateStatus: roomId=$roomId status=$newStatus ownerId=$ownerId');
      await _addAdminLog(
        action: 'update_room_status_$newStatus',
        targetType: 'room',
        targetId: roomId,
      );

      // Gửi thông báo cho chủ tin khi duyệt / từ chối / ẩn
      if (newStatus == 'active' || newStatus == 'rejected' || newStatus == 'hidden') {
        try {
          await _sendRoomNotification(
            userId: ownerId,
            roomId: roomId,
            roomTitle: roomTitle,
            status: newStatus,
          );
          print('✅ Sent room notification type=$newStatus userId=$ownerId roomId=$roomId');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã gửi thông báo cho chủ tin')),
            );
          }
        } catch (e) {
          print('❌ Send room notification error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi gửi thông báo: $e')),
            );
          }
        }
      }

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

  Future<void> _sendRoomNotification({
    required String userId,
    required String roomId,
    required String roomTitle,
    required String status,
  }) async {
    // Nếu thiếu userId từ list, thử đọc lại doc phòng để lấy ownerId/userId
    var targetUserId = userId;
    if (targetUserId.isEmpty || targetUserId == '—') {
      try {
        final roomSnap = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
        final data = roomSnap.data();
        final fallbackOwner = data?['ownerId'] as String? ?? '';
        final fallbackUser = data?['userId'] as String? ?? '';
        targetUserId = fallbackOwner.isNotEmpty ? fallbackOwner : fallbackUser;
        print('⚠️ _sendRoomNotification: ownerId missing, fallback uid="$targetUserId" from room doc');
      } catch (e) {
        print('❌ _sendRoomNotification: cannot fetch room for fallback: $e');
      }
    }
    if (targetUserId.isEmpty || targetUserId == '—') {
      print('⚠️ _sendRoomNotification: still missing userId, skip create notification');
      return;
    }
    final type = status == 'active'
        ? 'room_approved'
        : status == 'rejected'
            ? 'room_rejected'
            : status == 'hidden'
                ? 'room_hidden'
                : null;
    if (type == null) return;

    final title =
        type == 'room_approved'
            ? 'Tin của bạn đã được duyệt'
            : type == 'room_rejected'
                ? 'Tin của bạn bị từ chối'
                : 'Tin của bạn đã bị ẩn';
    final body = type == 'room_approved'
        ? 'Tin "$roomTitle" đã được duyệt và hiển thị.'
        : type == 'room_rejected'
            ? 'Tin "$roomTitle" đã bị từ chối. Vui lòng kiểm tra và chỉnh sửa.'
            : 'Tin "$roomTitle" đã bị ẩn bởi quản trị viên.';

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': targetUserId,
      'type': type,
      'title': title,
      'body': body,
      'roomId': roomId,
      'roomTitle': roomTitle,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'userId': targetUserId,
        'roomId': roomId,
        'roomTitle': roomTitle,
      },
    });
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
      await _addAdminLog(
        action: 'delete_room',
        targetType: 'room',
        targetId: roomId,
      );
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
      _NavItem('Đánh giá', Icons.reviews_outlined),
      _NavItem('Báo cáo', Icons.report_problem_outlined),
      _NavItem('Thống kê', Icons.stacked_bar_chart_outlined),
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

class _BarData {
  _BarData({required this.label, required this.value});

  final String label;
  final double value;
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({
    required this.title,
    required this.subtitle,
    required this.bars,
    this.color = const Color(0xFF1976D2),
  });

  final String title;
  final String subtitle;
  final List<_BarData> bars;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = bars.fold<double>(0, (prev, e) => e.value > prev ? e.value : prev);
    return Container(
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
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: bars.isEmpty || maxValue <= 0
                ? Center(
                    child: Text(
                      'Chưa có dữ liệu',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: bars.map((bar) {
                      final h = (bar.value / maxValue) * 120.0;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              bar.value.toInt().toString(),
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: h,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bar.label,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminLogItem {
  _AdminLogItem({
    required this.action,
    required this.adminId,
    required this.targetType,
    required this.targetId,
    required this.note,
    required this.createdAt,
  });

  final String action;
  final String adminId;
  final String targetType;
  final String targetId;
  final String note;
  final DateTime? createdAt;
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.logs});

  final List<_AdminLogItem> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động gần đây',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '10 thao tác gần nhất của admin',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Text(
              'Chưa có hoạt động nào.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            )
          else
            Column(
              children: logs.map((log) {
                final timeStr = log.createdAt != null
                    ? '${log.createdAt!.day}/${log.createdAt!.month} '
                        '${log.createdAt!.hour.toString().padLeft(2, '0')}:${log.createdAt!.minute.toString().padLeft(2, '0')}'
                    : '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(
                    _formatLogTitle(log),
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    'Admin: ${log.adminId.isEmpty ? 'unknown' : log.adminId} • $timeStr',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  static String _formatLogTitle(_AdminLogItem log) {
    switch (log.action) {
      case 'ban_user':
        return 'Khóa tài khoản user ${log.targetId}';
      case 'unban_user':
        return 'Mở khóa tài khoản user ${log.targetId}';
      case 'update_room_status_active':
        return 'Duyệt tin phòng ${log.targetId}';
      case 'update_room_status_rejected':
        return 'Từ chối tin phòng ${log.targetId}';
      case 'update_room_status_hidden':
        return 'Ẩn tin phòng ${log.targetId}';
      case 'delete_room':
        return 'Xóa tin phòng ${log.targetId}';
      case 'update_report_status_pending':
        return 'Đặt lại báo cáo ${log.targetId} về chờ xử lý';
      case 'update_report_status_resolved':
        return 'Đánh dấu báo cáo ${log.targetId} đã xử lý';
      case 'update_report_status_rejected':
        return 'Từ chối báo cáo ${log.targetId}';
      case 'delete_report':
        return 'Xóa báo cáo ${log.targetId}';
      default:
        return log.note.isNotEmpty ? log.note : log.action;
    }
  }
}

Future<void> _addAdminLog({
  required String action,
  required String targetType,
  required String targetId,
  String? note,
}) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance.collection('adminLogs').add({
      'adminId': uid,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'note': note ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Không crash nếu log lỗi
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Đăng nhập Admin',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        textAlign: TextAlign.center,
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
      ),
    );
  }
}

