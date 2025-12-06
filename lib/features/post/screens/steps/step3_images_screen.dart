import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/room_draft.dart';
import '../../services/storage_service.dart';

class Step3ImagesScreen extends StatefulWidget {
  final RoomDraft draft;
  final Function(RoomDraft) onNext;
  final VoidCallback onBack;

  const Step3ImagesScreen({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step3ImagesScreen> createState() => _Step3ImagesScreenState();
}

class _Step3ImagesScreenState extends State<Step3ImagesScreen> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final List<String> _images = []; // Lưu URLs từ Firebase Storage
  final int _maxImages = 15;
  bool _isUploading = false;
  final Map<String, double> _uploadProgress = {}; // Track upload progress

  @override
  void initState() {
    super.initState();
    _images.addAll(widget.draft.images);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= _maxImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tối đa $_maxImages hình ảnh')),
        );
      }
      return;
    }

    if (_isUploading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang upload ảnh, vui lòng đợi...')),
        );
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Hiển thị placeholder trong khi upload
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _images.add('uploading_$tempId'); // Placeholder
        _uploadProgress[tempId] = 0.0;
      });

      // Upload lên Firebase Storage
      final downloadUrl = await _storageService.uploadImage(imageFile);

      // Thay thế placeholder bằng URL thực tế
      setState(() {
        final index = _images.indexOf('uploading_$tempId');
        if (index != -1) {
          _images[index] = downloadUrl;
        }
        _uploadProgress.remove(tempId);
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload ảnh thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Xóa placeholder nếu upload thất bại
      setState(() {
        _images.removeWhere((img) => img.startsWith('uploading_'));
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ảnh: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    final imageUrl = _images[index];
    
    // Nếu là URL từ Firebase Storage, xóa khỏi Storage
    if (imageUrl.startsWith('http') && !imageUrl.startsWith('uploading_')) {
      try {
        await _storageService.deleteImage(imageUrl);
      } catch (e) {
        print('⚠️  Lỗi xóa ảnh từ Storage: $e');
        // Vẫn xóa khỏi list dù có lỗi
      }
    }
    
    setState(() {
      _images.removeAt(index);
    });
  }

  void _reorderImage(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  void _handleNext() {
    // Lọc bỏ các ảnh đang upload (chưa hoàn thành)
    final completedImages = _images.where((img) => !img.startsWith('uploading_')).toList();
    
    if (completedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 hình ảnh')),
      );
      return;
    }

    if (_isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đợi upload ảnh hoàn tất')),
      );
      return;
    }

    final updatedDraft = RoomDraft(
      postType: widget.draft.postType,
      roomType: widget.draft.roomType,
      price: widget.draft.price,
      area: widget.draft.area,
      amenities: widget.draft.amenities,
      city: widget.draft.city,
      district: widget.draft.district,
      ward: widget.draft.ward,
      streetName: widget.draft.streetName,
      houseNumber: widget.draft.houseNumber,
      directions: widget.draft.directions,
      latitude: widget.draft.latitude,
      longitude: widget.draft.longitude,
      images: completedImages,
      title: widget.draft.title,
      description: widget.draft.description,
      contactName: widget.draft.contactName,
      contactPhone: widget.draft.contactPhone,
      availableItems: widget.draft.availableItems,
    );

    widget.onNext(updatedDraft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Hình ảnh phòng trọ',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tối đa $_maxImages hình, hiện có ${_images.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid images
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _images.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _images.length) {
                        // Add button
                        if (_images.length >= _maxImages) {
                          return const SizedBox.shrink();
                        }
                        return InkWell(
                          onTap: () => _showImageSourceDialog(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 32,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Thêm ảnh',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Image item
                      final imageUrl = _images[index];
                      final isUploading = imageUrl.startsWith('uploading_');
                      
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isUploading
                                ? Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                          ),
                          if (!isUploading)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          if (index == 0)
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Ảnh đại diện',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: widget.onBack,
                    child: const Text('Quay lại'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _handleNext,
                    child: const Text('Tiếp theo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

