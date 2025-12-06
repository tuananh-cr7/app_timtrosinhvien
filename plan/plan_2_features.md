## Plan 2 – Tính năng chính (Ứng với cấp độ 🟡 Trung bình: mục 4.x – 10.x)

### Phase 1 – Xác thực & quản lý phiên (mục 4.1 – 4.2)
- Đăng ký/Đăng nhập:
  - API đăng ký trả về email verification link → gửi email với CTA “Xác nhận tài khoản”.
  - App có màn hình “Xác thực email” (như mock): nút “Gửi lại email”, “Đăng xuất”.  
  - Khi người dùng bấm “Tôi đã xác nhận” → gọi API verify, nếu OK chuyển thẳng vào Trang chủ.
  - Đăng nhập chuẩn với email/mật khẩu, lưu JWT + refresh token (Secure Storage).
  - Đăng nhập Google (Google Sign-In), xử lý các trạng thái thành công/thất bại giống screenshot (hiển thị snackbar lỗi khi người dùng hủy).
- Quên mật khẩu:
  - Form nhập email → gọi API gửi link reset password, hiển thị thông báo như UI.
  - Sau khi đặt lại mật khẩu trên web, quay lại app để đăng nhập bình thường.
- Middleware bảo vệ màn hình yêu cầu login; auto refresh token khi hết hạn; logout khi token invalid.

### Phase 2 – Quản lý dữ liệu & API cơ bản (mục 5.1 – 5.2)
- Repository layer kết nối backend (Rooms, Users, Favorites...).
- Local cache (Hive/SQLite) cho danh sách phòng, tin đã xem.
- Loading/error state chuẩn; retry mechanism.

### Phase 3 – Đăng tin phòng trọ (mục 7.1)
- Flow 4 bước y hệt spec:
  1. Thông tin cơ bản (loại tin, loại phòng, giá, diện tích, tiện ích).
  2. Địa chỉ (dropdown TP/Quận/Phường, mô tả, lấy vị trí hiện tại, map preview).
  3. Hình ảnh (tối đa 15 ảnh, upload progress, reorder, xóa).
  4. Xác nhận (tiêu đề, mô tả chi tiết, liên hệ, đồ dùng có sẵn, tóm tắt).
- Lưu nháp từng bước (local) + submit lên server + xử lý lỗi/validation từ backend.

### Phase 4 – Quản lý tin đã đăng (mục 7.2)
- Màn hình “Tin đã đăng” theo thiết kế:
  - Tabs/trạng thái (Đang hiển thị, Đang chờ duyệt, Đã ẩn, Đã cho thuê).
  - Thống kê: lượt xem, lượt liên hệ.
  - Action: Chỉnh sửa, Ẩn/Hiện, Xóa, Gia hạn, Ghim.
- Flow chỉnh sửa tin (reopen 4 bước, load data từ server).

### Phase 5 – Tương tác người dùng (mục 8.x)
- Đồng bộ Yêu thích lên server, badge thay đổi giá.
- Chat: tạm thời chỉ cần API list conversations + detail (cho Plan 3 real-time).
- Thông báo trong app (tab Thông báo, mark read/unread).

### Phase 6 – Tìm kiếm nâng cao + Filter (mục 3.x + 6.1)
- Màn hình “Tìm kiếm phòng trọ” đầy đủ:
  - Search bar, quick filter chips.
  - Bottom sheet bộ lọc: Giá, Tiện ích, Loại phòng, Số người, Diện tích, Đồ dùng, Chọn địa điểm.
- Gửi filter lên backend qua query params; kết hợp local filter (client-side) khi cần.

### Phase 7 – Bản đồ OpenStreetMap (mục 6.2 + phần map trong 7.1/2.2)
- Tích hợp `flutter_map` cho màn hình “Tìm bằng bản đồ”:
  - Marker list, cluster, info window, nút vị trí hiện tại.
  - Radius filter basic.
- Bản đồ preview ở bước Địa chỉ (Đăng tin) và trong màn hình Chi tiết phòng.



