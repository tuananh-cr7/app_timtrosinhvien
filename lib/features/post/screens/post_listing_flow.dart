import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/room_draft.dart';
import '../services/draft_service.dart';
import '../../home/data/repositories/rooms_repository.dart';
import '../../home/models/room.dart';
import '../../../core/models/api_result.dart';
import 'steps/step1_basic_info_screen.dart';
import 'steps/step2_address_screen.dart';
import 'steps/step3_images_screen.dart';
import 'steps/step4_confirm_screen.dart';

/// Flow đăng tin phòng trọ 4 bước.
class PostListingFlow extends StatefulWidget {
  final String? roomId; // Nếu có thì là edit mode
  final bool loadDraft; // Có load draft cũ không (mặc định false)

  const PostListingFlow({
    super.key,
    this.roomId,
    this.loadDraft = false, // Mặc định không load draft cũ
  });

  @override
  State<PostListingFlow> createState() => _PostListingFlowState();
}

class _PostListingFlowState extends State<PostListingFlow> {
  final _draftService = DraftService();
  final _roomsRepository = RoomsRepository();
  int _currentStep = 0;
  RoomDraft? _draft;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    RoomDraft draft;
    
    if (widget.loadDraft) {
      // Nếu được yêu cầu load draft, kiểm tra có draft cũ không
      final existingDraft = await RoomDraft.loadDraft();
      if (existingDraft != null && _hasDraftData(existingDraft)) {
        // Có draft cũ, hỏi người dùng
        if (mounted) {
          final shouldContinue = await _showDraftDialog();
          if (shouldContinue == true) {
            draft = existingDraft;
            // Cập nhật vào service
            await _draftService.updateDraft(draft);
          } else if (shouldContinue == false) {
            // Bắt đầu mới, xóa draft cũ
            await _draftService.clearDraft();
            draft = RoomDraft();
          } else {
            // User cancelled, pop
            if (mounted) Navigator.of(context).pop();
            return;
          }
        } else {
          draft = RoomDraft();
        }
      } else {
        // Không có draft cũ, bắt đầu mới
        draft = RoomDraft();
      }
    } else {
      // Không load draft, bắt đầu mới (form trống)
      draft = RoomDraft();
    }
    
    if (mounted) {
      setState(() {
        _draft = draft;
      });
    }
  }

  bool _hasDraftData(RoomDraft draft) {
    // Kiểm tra xem draft có dữ liệu thực sự không
    return draft.price > 0 ||
        draft.area > 0 ||
        draft.city.isNotEmpty ||
        draft.title.isNotEmpty ||
        draft.images.isNotEmpty;
  }

  Future<bool?> _showDraftDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tiếp tục nháp?'),
        content: const Text(
          'Bạn có tin đăng đang lưu nháp. Bạn muốn tiếp tục hay bắt đầu mới?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Bắt đầu mới
            child: const Text('Bắt đầu mới'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Tiếp tục
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_draft != null) {
      await _draftService.updateDraft(_draft!);
    }
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  Future<void> _onStepComplete(int step, RoomDraft updatedDraft) async {
    setState(() {
      _draft = updatedDraft;
    });
    await _saveDraft();

    if (step < 3) {
      _goToStep(step + 1);
    } else {
      // Bước 4 hoàn thành, submit lên server
      _goToStep(step + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_draft == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Lưu nháp khi back
          await _saveDraft();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _saveDraft();
              if (mounted) Navigator.of(context).pop();
            },
          ),
          title: const Text('Đăng tin phòng trọ'),
          actions: [
            TextButton(
              onPressed: () async {
                await _saveDraft();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu nháp')),
                  );
                }
              },
              child: const Text('Lưu nháp'),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: _buildStepContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    const steps = [
      'Thông tin',
      'Địa chỉ',
      'Hình ảnh',
      'Xác nhận',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // Progress line với các bước
          Row(
            children: List.generate(4, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              final primaryColor = Theme.of(context).colorScheme.primary;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted || (isActive && index > 0)
                            ? primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isCompleted
                            ? primaryColor
                            : Colors.white,
                        border: Border.all(
                          color: isActive || isCompleted
                              ? primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive || isCompleted
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (index < 3)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Text labels dưới mỗi bước
          Row(
            children: List.generate(4, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              final primaryColor = Theme.of(context).colorScheme.primary;

              return Expanded(
                child: Center(
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      color: isActive || isCompleted
                          ? primaryColor
                          : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Step1BasicInfoScreen(
          draft: _draft!,
          onNext: (updatedDraft) => _onStepComplete(0, updatedDraft),
        );
      case 1:
        return Step2AddressScreen(
          draft: _draft!,
          onNext: (updatedDraft) => _onStepComplete(1, updatedDraft),
          onBack: () => _goToStep(0),
        );
      case 2:
        return Step3ImagesScreen(
          draft: _draft!,
          onNext: (updatedDraft) => _onStepComplete(2, updatedDraft),
          onBack: () => _goToStep(1),
        );
      case 3:
        return Step4ConfirmScreen(
          draft: _draft!,
          onBack: () => _goToStep(2),
          onComplete: (updatedDraft) async {
            // Cập nhật draft với thông tin từ Step 4
            setState(() {
              _draft = updatedDraft;
            });
            await _saveDraft();
            // Submit lên server
            await _submitRoom();
          },
        );
      default:
        return const Center(child: Text('Hoàn thành'));
    }
  }

  Future<void> _submitRoom() async {
    if (_draft == null) return;

    // Validation tổng thể
    if (!_draft!.isStep1Complete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng hoàn thành bước 1: Thông tin cơ bản'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _goToStep(0);
      return;
    }

    if (!_draft!.isStep2Complete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng hoàn thành bước 2: Địa chỉ'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _goToStep(1);
      return;
    }

    if (!_draft!.isStep3Complete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng thêm ít nhất 1 hình ảnh'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _goToStep(2);
      return;
    }

    if (!_draft!.isStep4Complete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng hoàn thành bước 4: Xác nhận'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _goToStep(3);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để đăng tin'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Hiển thị loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Tạo address từ các field (hợp lý hơn)
      final addressParts = <String>[];
      if (_draft!.houseNumber.isNotEmpty) {
        addressParts.add(_draft!.houseNumber);
      }
      if (_draft!.streetName.isNotEmpty) {
        addressParts.add(_draft!.streetName);
      }
      if (_draft!.ward.isNotEmpty) {
        addressParts.add(_draft!.ward);
      }
      if (_draft!.district.isNotEmpty) {
        addressParts.add(_draft!.district);
      }
      if (_draft!.city.isNotEmpty) {
        addressParts.add(_draft!.city);
      }
      final address = addressParts.isNotEmpty
          ? addressParts.join(', ')
          : '${_draft!.district}, ${_draft!.city}';

      // Tạo room data từ draft
      final roomData = {
        'title': _draft!.title.trim(),
        'address': address,
        'district': _draft!.district,
        'city': _draft!.city,
        'priceMillion': _draft!.price / 1000000, // Convert VND to million
        'area': _draft!.area,
        'thumbnailUrl': _draft!.images.isNotEmpty ? _draft!.images[0] : '',
        'isShared': _draft!.postType == PostType.findRoommate,
        'description': _draft!.description.trim(),
        'ownerId': user.uid,
        'ownerName': _draft!.contactName.trim(),
        'ownerPhone': _draft!.contactPhone,
        'images': _draft!.images,
        'amenities': _draft!.amenities,
        'availableItems': _draft!.availableItems,
        'status': 'pending', // Mặc định chờ duyệt
        'latitude': _draft!.latitude,
        'longitude': _draft!.longitude,
      };
      
      // Debug: Kiểm tra dữ liệu trước khi lưu
      print('📝 Post Listing - amenities: ${_draft!.amenities}');
      print('📝 Post Listing - availableItems: ${_draft!.availableItems}');

      final result = await _roomsRepository.createRoom(roomData: roomData);

      // Đóng loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      switch (result) {
        case ApiError<Room>(message: final message):
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: $message'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        case ApiSuccess<Room>(data: final room):
          // Xóa draft sau khi submit thành công
          await _draftService.clearDraft();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đăng tin thành công! Tin đăng đang chờ duyệt.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(true); // Trả về true để refresh
          }
          break;
        case ApiLoading<Room>():
          // Should not happen here
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

