## Plan 1 – MVP (Tương ứng cấp độ 🟢 Dễ trong `DANH_SACH_CHUC_NANG.md`)

> Mục tiêu: Bao phủ toàn bộ nhóm chức năng 1.x – 3.x (Giao diện cơ bản, Hiển thị dữ liệu cơ bản, Tìm kiếm cơ bản) bằng mock data hoặc API đơn giản.

### Phase 1 – Nền tảng & Giao diện cơ bản (liên quan mục 1.1 – 1.4)
- Khởi tạo dự án Flutter, cài đặt packages nền tảng (routing, state mgmt, local storage).
- Thiết lập theme, typography, icon set.

#### 1.1. Màn hình Splash Screen ⭐
- Tạo màn hình splash với logo thương hiệu.
- Hiển thị trong 2-3 giây (dùng `Future.delayed` hoặc `Timer`).
- Tự động điều hướng tới màn hình tiếp theo (Onboarding hoặc Login tùy trạng thái).
- **Dependencies**: Không cần thêm.

#### 1.2. Màn hình Onboarding/Intro ⭐
- 3-4 màn hình giới thiệu có hình ảnh + text ngắn.
- Nút "Bỏ qua" và "Tiếp theo" (PageView + indicator dots).
- Lưu trạng thái đã xem bằng `shared_preferences` để không hiện lại.
- **Dependencies**: `shared_preferences`.

- Sau Onboarding chuyển thẳng vào app (Trang chủ + Bottom Navigation Bar).  
- **Không cần** làm đăng nhập/đăng ký mock ở Plan 1 (đăng nhập/đăng ký thật đã được xử lý ở `plan_2_features` – Phase 1).

### Phase 2 – Trang chủ & card phòng (mục 1.5 + 2.1)
- Dựng màn hình Trang chủ theo thiết kế “Nhà Trọ 360”, có các section “Phòng mới đăng”, “Phòng ở ghép”, “Tất cả phòng”.
- Tạo `Room` model, sample data (JSON local).
- Component card phòng (overlay giá, icon diện tích, địa chỉ).

### Phase 3 – Chi tiết phòng & nội dung tĩnh (mục 2.2)
- Màn hình chi tiết phòng: carousel hình ảnh, thông tin giá/địa chỉ/diện tích/tiện ích/đồ dùng.
- Nút Gọi ngay, Gửi SMS, Lưu yêu thích (local state).  
- Section Mô tả, Vị trí (map placeholder), Tiện ích, Đồ dùng.

### Phase 4 – Yêu thích & Lịch sử xem (mục 8.1 + 8.2 trong tương tác người dùng, nhưng triển khai phiên bản local)
- Lưu yêu thích bằng SharedPreferences/Hive.
- Màn hình “Yêu thích” với empty state như thiết kế.
- Tự động log lịch sử xem khi vào chi tiết phòng; màn hình “Lịch sử xem”.

### Phase 5 – Tài khoản cơ bản (mục 2.3)
- Màn hình “Tài khoản”: card thông tin user (mock), menu “Chỉnh sửa hồ sơ, Đổi mật khẩu, Phòng đã lưu, Lịch sử xem, Tin đã đăng, Đăng xuất”.
- Màn hình “Chỉnh sửa hồ sơ” và “Đổi mật khẩu” hoạt động nội bộ (chưa cần API).



