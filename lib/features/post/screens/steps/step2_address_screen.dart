import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/room_draft.dart';
import '../../../map/widgets/map_preview_widget.dart';

class Step2AddressScreen extends StatefulWidget {
  final RoomDraft draft;
  final Function(RoomDraft) onNext;
  final VoidCallback onBack;

  const Step2AddressScreen({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step2AddressScreen> createState() => _Step2AddressScreenState();
}

class _Step2AddressScreenState extends State<Step2AddressScreen> {
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _directionsController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _cityController.text = widget.draft.city;
    _districtController.text = widget.draft.district;
    _wardController.text = widget.draft.ward;
    _houseNumberController.text = widget.draft.houseNumber;
    _directionsController.text = widget.draft.directions;
    _latitude = widget.draft.latitude;
    _longitude = widget.draft.longitude;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _houseNumberController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Kiểm tra dịch vụ định vị
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng bật dịch vụ định vị (GPS)'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Kiểm tra và yêu cầu quyền
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cần quyền truy cập vị trí để lấy vị trí hiện tại'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Lấy vị trí với độ chính xác cao nhất
      Position? position;
      
      try {
        // Thử lấy vị trí với độ chính xác cao nhất
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 10),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            // Nếu timeout, thử lấy vị trí với độ chính xác thấp hơn
            return Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 5),
            );
          },
        );
      } catch (e) {
        // Nếu vẫn lỗi, thử lấy vị trí cuối cùng đã biết
        print('⚠️ Không thể lấy vị trí mới, thử lấy vị trí cuối cùng: $e');
        position = await Geolocator.getLastKnownPosition();
        
        if (position == null) {
          throw Exception('Không thể lấy vị trí. Vui lòng đảm bảo GPS đã bật và có tín hiệu.');
        }
      }
      
      if (position != null && mounted) {
        setState(() {
          _latitude = position!.latitude;
          _longitude = position!.longitude;
        });
        
        // Reverse geocoding để lấy địa chỉ
        await _reverseGeocode(position!.latitude, position!.longitude);
        
        // Hiển thị thông tin về độ chính xác
        if (mounted) {
          final accuracy = position!.accuracy;
          if (accuracy > 50) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Đã lấy vị trí (độ chính xác: ${accuracy.toStringAsFixed(0)}m). '
                  'Vui lòng đợi GPS ổn định để có độ chính xác cao hơn.',
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Đã lấy vị trí (độ chính xác: ${accuracy.toStringAsFixed(0)}m)',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi lấy vị trí: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  /// Extract city từ address object
  String _extractCity(Map<String, dynamic> address) {
    // Thử nhiều field khác nhau theo thứ tự ưu tiên
    final candidates = [
      address['state'],
      address['province'],
      address['region'],
      address['state_district'],
      address['city'],
      address['town'],
    ];
    
    for (var candidate in candidates) {
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        return candidate.toString().trim();
      }
    }
    
    return '';
  }
  
  /// Extract district từ address object
  String _extractDistrict(Map<String, dynamic> address) {
    // Thử nhiều field khác nhau theo thứ tự ưu tiên
    final candidates = [
      address['county'],
      address['district'],
      address['municipality'],
      address['city_level2'],
      address['admin_level6'],
      address['state_district'], // Đôi khi state_district chứa quận/huyện
    ];
    
    for (var candidate in candidates) {
      if (candidate != null) {
        final value = candidate.toString().trim();
        // Bỏ qua nếu là số (postal code, admin code)
        if (value.isNotEmpty && !_isNumeric(value)) {
          print('✅ Tìm thấy district từ field: $value');
          return value;
        } else if (_isNumeric(value)) {
          print('⚠️ Bỏ qua giá trị số (có thể là postal code): $value');
        }
      }
    }
    
    // Nếu không tìm thấy, thử parse từ display_name hoặc formatted address
    // (sẽ được gọi từ _reverseGeocode nếu cần)
    
    print('⚠️ Không tìm thấy district từ các field thông thường');
    return '';
  }
  
  /// Kiểm tra xem string có phải là số không
  bool _isNumeric(String str) {
    // Kiểm tra nếu toàn bộ là số (có thể có dấu chấm, phẩy)
    return RegExp(r'^[\d.,]+$').hasMatch(str);
  }
  
  /// Extract ward từ address object
  String _extractWard(Map<String, dynamic> address, String city) {
    // Thử nhiều field khác nhau theo thứ tự ưu tiên
    final candidates = [
      address['suburb'],
      address['quarter'],
      address['city_district'],
      address['neighbourhood'],
      address['village'],
      address['hamlet'],
    ];
    
    for (var candidate in candidates) {
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        return candidate.toString().trim();
      }
    }
    
    // Nếu không có ward, thử lấy từ city/town
    final cityTown = (address['city'] ?? address['town'] ?? '').toString().trim();
    // Nếu city/town không trùng với city (tỉnh/thành phố), có thể là ward
    if (cityTown.isNotEmpty && cityTown != city && !cityTown.contains(city) && !city.contains(cityTown)) {
      return cityTown;
    }
    
    return '';
  }
  
  /// Loại bỏ tiền tố từ tên thành phố
  String _cleanCityName(String city) {
    if (city.isEmpty) return '';
    return city.replaceAll(RegExp(r'^(Tỉnh|Thành phố|TP\.?|Thành Phố)\s*', caseSensitive: false), '').trim();
  }
  
  /// Loại bỏ tiền tố từ tên quận/huyện
  String _cleanDistrictName(String district) {
    if (district.isEmpty) return '';
    return district.replaceAll(RegExp(r'^(Quận|Huyện|Q\.?|H\.?)\s*', caseSensitive: false), '').trim();
  }
  
  /// Loại bỏ tiền tố từ tên phường/xã
  String _cleanWardName(String ward) {
    if (ward.isEmpty) return '';
    return ward.replaceAll(RegExp(r'^(Phường|Xã|P\.?|X\.?)\s*', caseSensitive: false), '').trim();
  }
  
  /// Parse district từ display_name nếu không tìm thấy trong address fields
  String _parseDistrictFromDisplayName(String displayName, String city, String ward) {
    try {
      print('🔍 Bắt đầu parse district từ display_name: $displayName');
      print('🔍 City hiện tại: $city');
      
      // Display name thường có format: "Phường/Xã, Quận/Huyện, Tỉnh/Thành phố, ..."
      // Hoặc: "Địa chỉ, Phường/Xã, Quận/Huyện, Tỉnh/Thành phố, ..."
      // Hoặc: "Phường/Xã, Quận/Huyện, Hà Nội, Việt Nam"
      
      // Tách theo dấu phẩy
      final parts = displayName.split(',').map((e) => e.trim()).toList();
      print('🔍 Các phần sau khi tách: $parts');
      print('🔍 Ward: "$ward", City: "$city"');
      
      // Tìm vị trí của city trong parts
      int cityIndex = -1;
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].contains(city) || city.contains(parts[i])) {
          cityIndex = i;
          break;
        }
      }
      print('🔍 City index: $cityIndex');
      
      // Tìm vị trí của ward trong parts
      int wardIndex = -1;
      if (ward.isNotEmpty) {
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].contains(ward) || ward.contains(parts[i]) || 
              parts[i].contains('Phường') || parts[i].contains('Xã')) {
            wardIndex = i;
            break;
          }
        }
      }
      print('🔍 Ward index: $wardIndex');
      
      // Tìm phần chứa "Quận" hoặc "Huyện"
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        print('🔍 Đang kiểm tra phần $i: "$part"');
        
        // Kiểm tra nếu có chứa "Quận" hoặc "Huyện"
        if (part.contains('Quận') || part.contains('Huyện')) {
          print('✅ Tìm thấy "Quận" hoặc "Huyện" trong: "$part"');
          
          // Thử nhiều cách extract:
          // 1. Loại bỏ "Quận" hoặc "Huyện" ở đầu
          var district = part.replaceAll(RegExp(r'^(Quận|Huyện)\s+', caseSensitive: false), '').trim();
          
          // 2. Nếu vẫn còn "Quận" hoặc "Huyện" ở giữa, thử extract bằng regex
          if (district.contains('Quận') || district.contains('Huyện')) {
            // Thử extract: "Quận X" hoặc "Huyện Y"
            final match = RegExp(r'(?:Quận|Huyện)\s+([^,]+)').firstMatch(part);
            if (match != null && match.groupCount >= 1) {
              district = match.group(1)?.trim() ?? '';
            }
          }
          
          // 3. Nếu vẫn không được, thử lấy toàn bộ phần sau "Quận"/"Huyện"
          if (district.isEmpty || district == part) {
            final index = part.toLowerCase().indexOf('quận');
            if (index == -1) {
              final index2 = part.toLowerCase().indexOf('huyện');
              if (index2 != -1) {
                district = part.substring(index2 + 5).trim();
              }
            } else {
              district = part.substring(index + 4).trim();
            }
            // Loại bỏ dấu phẩy hoặc ký tự đặc biệt ở đầu
            district = district.replaceAll(RegExp(r'^[,.\s]+'), '').trim();
          }
          
          print('🔍 District sau khi loại bỏ tiền tố: "$district"');
          
          // Bỏ qua nếu là số, trùng với city, hoặc là "Việt Nam"
          if (district.isNotEmpty && 
              district != city && 
              district != 'Việt Nam' &&
              district != 'Vietnam' &&
              !_isNumeric(district) &&
              !district.contains('Vietnam') &&
              !district.contains('Việt Nam') &&
              district.length > 1) { // Ít nhất 2 ký tự
            print('✅ Parse được district từ display_name: "$district"');
            return district;
          } else {
            print('⚠️ Bỏ qua district "$district" (rỗng, số, Việt Nam, hoặc trùng với city)');
          }
        }
      }
      
      // Nếu không tìm thấy "Quận"/"Huyện", thử tìm phần giữa ward và city
      // Thường format: ward, district, city
      print('🔍 Không tìm thấy "Quận"/"Huyện", thử tìm phần giữa ward và city...');
      
      // Nếu có ward và city, phần giữa chúng có thể là district
      if (wardIndex >= 0 && cityIndex >= 0 && cityIndex > wardIndex + 1) {
        // Có ít nhất 1 phần giữa ward và city
        for (int i = wardIndex + 1; i < cityIndex; i++) {
          final part = parts[i];
          print('🔍 Kiểm tra phần giữa ward và city ($i): "$part"');
          
          // Nếu phần này không chứa city, không chứa ward keywords, không phải số, không phải "Việt Nam", có thể là district
          if (!part.contains(city) && 
              !part.contains('Phường') && 
              !part.contains('Xã') &&
              !part.contains('Tỉnh') &&
              !part.contains('Thành phố') &&
              !_isNumeric(part) &&
              part != 'Việt Nam' &&
              part != 'Vietnam' &&
              !part.contains('Vietnam') &&
              !part.contains('Việt Nam') &&
              part.length > 1 && // Ít nhất 2 ký tự
              part.isNotEmpty) {
            print('✅ Parse được district từ phần giữa ward và city: "$part"');
            return part;
          }
        }
      } else {
        print('⚠️ Không tìm được ward index ($wardIndex) hoặc city index ($cityIndex) hoặc chúng không cách nhau');
      }
      
      // Fallback: Thử tìm phần giữa bất kỳ (nếu không tìm được ward/city index)
      if (parts.length >= 3) {
        // Phần giữa có thể là district
        for (int i = 1; i < parts.length - 1; i++) {
          final part = parts[i];
          print('🔍 Kiểm tra phần giữa $i: "$part"');
          
          // Nếu phần này không chứa city, không chứa ward keywords, không phải số, không phải "Việt Nam", có thể là district
          if (!part.contains(city) && 
              !part.contains('Phường') && 
              !part.contains('Xã') &&
              !part.contains('Tỉnh') &&
              !part.contains('Thành phố') &&
              !_isNumeric(part) &&
              part != 'Việt Nam' &&
              part != 'Vietnam' &&
              !part.contains('Vietnam') &&
              !part.contains('Việt Nam') &&
              part.length > 1 && // Ít nhất 2 ký tự
              part.isNotEmpty) {
            print('✅ Parse được district từ phần giữa display_name: "$part"');
            return part;
          }
        }
      }
      
      // Fallback 1: Thử tìm bất kỳ phần nào có vẻ là tên quận/huyện
      // (không chứa "Phường", "Xã", "Tỉnh", "Thành phố", không phải số)
      print('🔍 Fallback 1: Thử tìm bất kỳ phần nào có vẻ là district...');
      for (var part in parts) {
        if (part.isNotEmpty &&
            part.length > 2 &&
            !_isNumeric(part) &&
            part != 'Việt Nam' &&
            part != 'Vietnam' &&
            !part.contains('Phường') &&
            !part.contains('Xã') &&
            !part.contains('Tỉnh') &&
            !part.contains('Thành phố') &&
            !part.contains('Vietnam') &&
            !part.contains('Việt Nam') &&
            part != city &&
            part != ward &&
            !part.contains(city) &&
            !part.contains(ward)) {
          // Kiểm tra xem có phải là tên địa danh không (có chữ cái)
          if (RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(part)) {
            print('✅ Fallback 1: Tìm thấy district có vẻ hợp lý: "$part"');
            return part;
          }
        }
      }
      
      // Fallback 2: Nếu có ward và city, thử lấy phần ngay sau ward (có thể là district)
      if (wardIndex >= 0 && wardIndex + 1 < parts.length) {
        final nextPart = parts[wardIndex + 1];
        print('🔍 Fallback 2: Thử lấy phần ngay sau ward: "$nextPart"');
        if (nextPart.isNotEmpty &&
            nextPart != city &&
            nextPart != ward &&
            nextPart != 'Việt Nam' &&
            nextPart != 'Vietnam' &&
            !nextPart.contains('Phường') &&
            !nextPart.contains('Xã') &&
            !nextPart.contains('Tỉnh') &&
            !nextPart.contains('Thành phố') &&
            !_isNumeric(nextPart) &&
            nextPart.length > 1) {
          print('✅ Fallback 2: Tìm thấy district ngay sau ward: "$nextPart"');
          return nextPart;
        }
      }
      
      // Fallback 3: Nếu có city, thử lấy phần ngay trước city (có thể là district)
      if (cityIndex >= 0 && cityIndex > 0) {
        final prevPart = parts[cityIndex - 1];
        print('🔍 Fallback 3: Thử lấy phần ngay trước city: "$prevPart"');
        if (prevPart.isNotEmpty &&
            prevPart != city &&
            prevPart != ward &&
            prevPart != 'Việt Nam' &&
            prevPart != 'Vietnam' &&
            !prevPart.contains('Phường') &&
            !prevPart.contains('Xã') &&
            !prevPart.contains('Tỉnh') &&
            !prevPart.contains('Thành phố') &&
            !_isNumeric(prevPart) &&
            prevPart.length > 1) {
          print('✅ Fallback 3: Tìm thấy district ngay trước city: "$prevPart"');
          return prevPart;
        }
      }
      
      print('❌ Không parse được district từ display_name');
    } catch (e) {
      print('❌ Lỗi khi parse district từ display_name: $e');
    }
    
    return '';
  }
  
  /// Parse district bằng logic đơn giản hơn
  String _simpleParseDistrict(String displayName, String city, String ward) {
    try {
      print('🔍 Simple parse: displayName="$displayName", city="$city", ward="$ward"');
      
      // Tách theo dấu phẩy
      final parts = displayName.split(',').map((e) => e.trim()).toList();
      
      // Tìm phần có chứa "Quận" hoặc "Huyện"
      for (var part in parts) {
        final lowerPart = part.toLowerCase();
        if (lowerPart.contains('quận') || lowerPart.contains('huyện')) {
          // Lấy phần sau "Quận" hoặc "Huyện"
          String? extracted;
          if (lowerPart.contains('quận')) {
            final index = lowerPart.indexOf('quận');
            extracted = part.substring(index + 4).trim();
          } else if (lowerPart.contains('huyện')) {
            final index = lowerPart.indexOf('huyện');
            extracted = part.substring(index + 5).trim();
          }
          
          if (extracted != null && extracted.isNotEmpty) {
            // Loại bỏ dấu phẩy, dấu chấm ở đầu
            extracted = extracted.replaceAll(RegExp(r'^[,.\s]+'), '').trim();
            // Loại bỏ phần sau dấu phẩy (nếu có)
            if (extracted.contains(',')) {
              extracted = extracted.split(',')[0].trim();
            }
            
            // Kiểm tra hợp lệ - LOẠI BỎ "Việt Nam" và "Vietnam"
            if (extracted.isNotEmpty &&
                extracted.length > 1 &&
                !_isNumeric(extracted) &&
                extracted != city &&
                extracted != ward &&
                extracted != 'Việt Nam' &&
                extracted != 'Vietnam' &&
                !extracted.contains('Vietnam') &&
                !extracted.contains('Việt Nam')) {
              print('✅ Simple parse tìm thấy: "$extracted"');
              return extracted;
            } else {
              print('⚠️ Bỏ qua "$extracted" (Việt Nam, số, hoặc trùng với city/ward)');
            }
          }
        }
      }
      
      // Nếu không tìm thấy, thử lấy phần giữa ward và city
      // Format thường: ward, district, city, ...
      if (parts.length >= 3 && ward.isNotEmpty && city.isNotEmpty) {
        for (var part in parts) {
          // Bỏ qua nếu là ward, city, hoặc các từ khóa không hợp lệ
          if (part != ward && 
              part != city && 
              part != 'Việt Nam' &&
              part != 'Vietnam' &&
              !part.contains('Phường') &&
              !part.contains('Xã') &&
              !part.contains('Tỉnh') &&
              !part.contains('Thành phố') &&
              !part.contains('Vietnam') &&
              !part.contains('Việt Nam') &&
              !_isNumeric(part) &&
              part.length > 2) {
            print('✅ Simple parse tìm thấy phần giữa: "$part"');
            return part;
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi simple parse: $e');
    }
    
    return '';
  }

  /// Reverse geocoding để lấy địa chỉ từ tọa độ GPS
  Future<void> _reverseGeocode(double latitude, double longitude) async {
    try {
      print('📍 Bắt đầu reverse geocoding: $latitude, $longitude');
      
      // Sử dụng OpenStreetMap Nominatim API (miễn phí, không cần key)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&addressdetails=1&accept-language=vi',
      );
      
      print('🌐 Gọi API: $url');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'NhaTro360App/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        
        print('📋 Address data: $address');
        
        if (address != null) {
          // Debug: In toàn bộ address để xem có gì
          print('📋 Full address keys: ${address.keys.toList()}');
          address.forEach((key, value) {
            print('  - $key: $value (${value.runtimeType})');
          });
          
          // Lấy display_name để parse nếu cần
          final displayName = data['display_name']?.toString() ?? '';
          print('📍 Display name: $displayName');
          
          // Lấy thông tin địa chỉ từ response
          // Nominatim cho Việt Nam có thể trả về nhiều format khác nhau
          String city = _extractCity(address);
          String district = _extractDistrict(address);
          String ward = _extractWard(address, city);
          
          print('🔍 Trước khi parse từ display_name:');
          print('  - City: $city');
          print('  - District: $district');
          print('  - Ward: $ward');
          
          // Nếu district vẫn rỗng, thử parse từ display_name
          if (district.isEmpty && displayName.isNotEmpty) {
            print('⚠️ District rỗng, thử parse từ display_name...');
            // Truyền cả ward vào để tìm phần giữa ward và city
            final parsedDistrict = _parseDistrictFromDisplayName(displayName, city, ward);
            if (parsedDistrict.isNotEmpty) {
              district = parsedDistrict;
              print('✅ Parse được district từ display_name: $district');
            } else {
              print('❌ Không parse được district từ display_name');
              // Thử một lần nữa với logic đơn giản hơn
              district = _simpleParseDistrict(displayName, city, ward);
              if (district.isNotEmpty) {
                print('✅ Parse được district bằng logic đơn giản: $district');
              }
            }
          }
          
          // Loại bỏ tiền tố
          city = _cleanCityName(city);
          district = _cleanDistrictName(district);
          ward = _cleanWardName(ward);
          
          print('🏙️ City (sau xử lý): $city');
          print('🏘️ District (sau xử lý): $district');
          print('🏠 Ward (sau xử lý): $ward');
          
          if (mounted) {
            setState(() {
              // Luôn điền nếu có giá trị (không cần kiểm tra trống)
              if (city.isNotEmpty) {
                _cityController.text = city;
                print('✅ Đã điền city: $city');
              } else {
                print('⚠️ City rỗng, không điền được');
              }
              if (district.isNotEmpty) {
                _districtController.text = district;
                print('✅ Đã điền district: $district');
              } else {
                print('⚠️ District rỗng, không điền được');
              }
              if (ward.isNotEmpty) {
                _wardController.text = ward;
                print('✅ Đã điền ward: $ward');
              } else {
                print('⚠️ Ward rỗng, không điền được');
              }
            });
            
            // Kiểm tra xem có điền được gì không
            final hasFilled = city.isNotEmpty || district.isNotEmpty || ward.isNotEmpty;
            
            if (hasFilled) {
              // Nếu district rỗng, hiển thị cảnh báo
              if (district.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Đã điền Tỉnh/Thành phố và Phường/Xã, nhưng không tìm thấy Quận/Huyện. Vui lòng nhập thủ công.'),
                    duration: Duration(seconds: 4),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã tự động điền địa chỉ từ vị trí GPS'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Không thể lấy địa chỉ từ vị trí này. Vui lòng nhập thủ công.'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          print('⚠️ Address data is null');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Không thể lấy địa chỉ từ vị trí này. Vui lòng nhập thủ công.'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        print('❌ Response status không phải 200: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Lỗi reverse geocoding: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi lấy địa chỉ: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFullMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullMapPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          onLocationSelected: (lat, lng) {
            setState(() {
              _latitude = lat;
              _longitude = lng;
            });
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã chọn vị trí từ bản đồ'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleNext() {
    if (_cityController.text.trim().isEmpty || _districtController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập thành phố và quận/huyện')),
      );
      return;
    }

    final updatedDraft = RoomDraft(
      postType: widget.draft.postType,
      roomType: widget.draft.roomType,
      price: widget.draft.price,
      area: widget.draft.area,
      amenities: widget.draft.amenities,
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      ward: _wardController.text.trim(),
      streetName: '', // TODO: Thêm field này nếu cần
      houseNumber: _houseNumberController.text.trim(),
      directions: _directionsController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      images: widget.draft.images,
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
                  // Tỉnh/Thành phố
                  Text(
                    'Tỉnh/Thành phố',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nhập tỉnh/thành phố',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quận/Huyện
                  Text(
                    'Quận/Huyện',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _districtController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nhập quận/huyện',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phường/Xã
                  Text(
                    'Phường/Xã',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _wardController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nhập phường/xã',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Số nhà, tên đường
                  Text(
                    'Số nhà, tên đường',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _houseNumberController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nhập số nhà, tên đường',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '(Lưu ý: Số nhà, tên đường chọn từ bản đồ có thể ko chính xác, nên bạn có thể chỉnh sửa, nhập lại thủ công.)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mô tả đường đi
                  Text(
                    'Mô tả đường đi (tuỳ chọn)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _directionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Mô tả đường đi đến phòng trọ',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút lấy vị trí hiện tại
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isGettingLocation ? 'Đang lấy vị trí...' : 'Lấy vị trí hiện tại'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  // Hiển thị tọa độ nếu đã có
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),

                  // Map preview
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Vị trí đã chọn',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _openFullMap,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(_latitude!, _longitude!),
                                  initialZoom: 15.0,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all,
                                  ),
                                  onTap: (tapPosition, point) {
                                    setState(() {
                                      _latitude = point.latitude;
                                      _longitude = point.longitude;
                                    });
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.app_timtrosinhvien',
                                    maxZoom: 19,
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(_latitude!, _longitude!),
                                        width: 50,
                                        height: 50,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Center crosshair
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Expand icon
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.open_in_full,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
}

/// Màn hình full screen để chọn vị trí trên bản đồ
class _FullMapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude) onLocationSelected;

  const _FullMapPickerScreen({
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<_FullMapPickerScreen> createState() => _FullMapPickerScreenState();
}

class _FullMapPickerScreenState extends State<_FullMapPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      _selectedLocation = const LatLng(21.0285, 105.8542); // Hà Nội mặc định
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  void _confirmSelection() {
    widget.onLocationSelected(_selectedLocation.latitude, _selectedLocation.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí từ bản đồ'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_timtrosinhvien',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Center crosshair
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vị trí đã chọn: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _confirmSelection,
                        child: const Text('Xác nhận vị trí'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

