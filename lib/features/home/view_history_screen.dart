import 'package:flutter/material.dart';

import 'data/repositories/view_history_repository.dart';
import 'history_manager.dart';
import 'room_detail_screen.dart';
import '../../core/models/api_result.dart';
import '../../core/widgets/loading_error_widget.dart';

class ViewHistoryScreen extends StatefulWidget {
  const ViewHistoryScreen({super.key});

  @override
  State<ViewHistoryScreen> createState() => _ViewHistoryScreenState();
}

class _ViewHistoryScreenState extends State<ViewHistoryScreen> {
  final _repository = ViewHistoryRepository();
  late Future<ApiResult<List<ViewHistoryEntry>>> _future;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _future = _repository.getHistory();
    });
  }

  Future<void> _reload() async {
    _loadHistory();
  }

  String _formatRelative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    final weeks = diff.inDays ~/ 7;
    return '$weeks tuần trước';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử xem phòng'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<ApiResult<List<ViewHistoryEntry>>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final result = snapshot.data!;
            final items = result.dataOrNull ?? [];

            return LoadingErrorWidget(
              result: result,
              onRetry: _reload,
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có lịch sử xem nào',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Các phòng bạn xem sẽ được lưu ở đây',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final entry = items[index];
                        final room = entry.room;

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              room.thumbnailUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            room.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatRelative(entry.viewedAt),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RoomDetailScreen(room: room),
                              ),
                            );
                            _reload();
                          },
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}



