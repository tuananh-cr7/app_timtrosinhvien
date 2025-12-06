import '../models/room.dart';

// Sample data local cho MVP – sau này sẽ thay bằng API/Firestore.

final List<Room> mockLatestRooms = [
  Room(
    id: 'r1',
    title: 'Phòng trọ full nội thất gần ĐH Công Nghệ',
    address: 'Nhân Hòa, Nhân Chính, Thanh Xuân',
    district: 'Thanh Xuân',
    city: 'Hà Nội',
    priceMillion: 4.6,
    area: 30,
    thumbnailUrl:
        'https://images.pexels.com/photos/271639/pexels-photo-271639.jpeg',
  ),
  Room(
    id: 'r3',
    title: 'Căn hộ mini mới xây, vào ở ngay',
    address: 'Ngõ 7, Phú Diễn, Bắc Từ Liêm',
    district: 'Bắc Từ Liêm',
    city: 'Hà Nội',
    priceMillion: 3.5,
    area: 25,
    thumbnailUrl:
        'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg',
  ),
  Room(
    id: 'r4',
    title: 'Phòng trọ gần ĐH Kinh Tế Quốc Dân',
    address: 'Trần Đại Nghĩa, Hai Bà Trưng',
    district: 'Hai Bà Trưng',
    city: 'Hà Nội',
    priceMillion: 3.0,
    area: 22,
    thumbnailUrl:
        'https://images.pexels.com/photos/271639/pexels-photo-271639.jpeg',
  ),
];

final List<Room> mockSharedRooms = [
  Room(
    id: 'r2',
    title: 'Tìm người ở ghép gần ĐH Xây Dựng',
    address: '8, 288 Phú Diễn, Bắc Từ Liêm',
    district: 'Bắc Từ Liêm',
    city: 'Hà Nội',
    priceMillion: 2.0,
    area: 20,
    // Ảnh cũ bị 404, dùng ảnh placeholder khác
    thumbnailUrl:
        'https://images.pexels.com/photos/1643383/pexels-photo-1643383.jpeg',
    isShared: true,
  ),
];

final List<Room> mockAllRooms = [
  // Bao gồm tất cả phòng nhưng không bị trùng
  ...mockLatestRooms,
  ...mockSharedRooms,
  Room(
    id: 'r5',
    title: 'Căn hộ dịch vụ 1 ngủ, full nội thất',
    address: 'Láng Hạ, Đống Đa',
    district: 'Đống Đa',
    city: 'Hà Nội',
    priceMillion: 5.2,
    area: 35,
    thumbnailUrl:
        'https://images.pexels.com/photos/262048/pexels-photo-262048.jpeg',
  ),
  Room(
    id: 'r6',
    title: 'Phòng trọ giá rẻ cho sinh viên',
    address: 'Xuân Thủy, Cầu Giấy',
    district: 'Cầu Giấy',
    city: 'Hà Nội',
    priceMillion: 2.3,
    area: 18,
    thumbnailUrl:
        'https://images.pexels.com/photos/271639/pexels-photo-271639.jpeg',
  ),
];


