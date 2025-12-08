## Plan Admin (web) – phù hợp đồ án hiện tại

> Làm admin dạng web (Flutter Web hoặc React), dùng chung Firestore/Storage/Firebase Auth.

### Kiến trúc & bảo mật
- Auth: Firebase Auth + custom claims `admin=true`, guard toàn bộ trang admin.
- Deploy: Firebase Hosting; dùng Cloud Functions nếu cần batch/cron.
- RBAC đơn giản: super-admin / admin / moderator (nếu cần).

### Phase A – Khởi tạo & đăng nhập
- Thiết lập dự án web admin, kết nối Firestore/Storage/Firebase Auth.
- Màn Đăng nhập Admin (Email/Password), kiểm tra custom claims.
- Dashboard cơ bản: số user, số tin, tin chờ duyệt, báo cáo mới; hoạt động gần đây.

### Phase B – Quản lý tin đăng
- Quy trình trạng thái: pending → active → rented/hidden/rejected.
- Bảng tin với filter: trạng thái, chủ tin, ngày đăng, giá, diện tích, loại phòng.
- Chi tiết tin: ảnh, mô tả, stats, action (Duyệt/Từ chối/Ẩn/Xóa/Gia hạn/Ghim), lý do từ chối + gửi thông báo cho người đăng.

### Phase C – Quản lý người dùng
- Danh sách user (role, trạng thái, số tin đã đăng).
- Chi tiết user: info, thống kê, danh sách tin, lịch sử hoạt động.
- Actions: Ban/Unban, Reset password, gửi thông báo, xác thực email thủ công.

### Phase D – Báo cáo & Nhật ký
- Báo cáo: danh sách, chi tiết, xử lý (Chấp nhận/Từ chối), khóa tin/khoá user nếu cần.
- Activity logs: ghi thao tác admin (duyệt/ẩn/xóa tin, ban user, gửi thông báo).

### Phase E – Thống kê & Cấu hình
- Thống kê: đếm tin mới/bị từ chối/đã cho thuê theo thời gian; lượt báo cáo.
- Cấu hình: danh mục tiện ích/đồ dùng, giới hạn giá/diện tích, loại phòng, thông báo.

### Phase F – Quản trị admin
- Quản lý tài khoản admin (tạo/sửa/xóa, phân quyền).
- Log đăng nhập admin, 2FA (nếu kịp).

### Ưu tiên triển khai
1) Đăng nhập + guard admin (custom claims).
2) Quản lý tin: list + duyệt/ẩn/xóa + filter cơ bản.
3) Báo cáo: list + đánh dấu xử lý.
4) Thông báo trạng thái tin (duyệt/từ chối).
5) Thống kê đếm đơn giản.
6) Quản lý user (ban/unban).
7) Activity logs.
8) Cấu hình danh mục & giới hạn (tiện ích, đồ dùng, giá/diện tích, loại phòng).


