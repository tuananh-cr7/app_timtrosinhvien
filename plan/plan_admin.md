## Plan Admin – Tương ứng cụm chức năng 11.1 – 11.9 (Admin riêng)

> Thực hiện sau khi app chính ổn định. Có thể dùng Flutter Web/React/Next.js.  

### Phase A – Cơ bản (mục 11.1 – 11.2)
- Thiết lập dự án web admin, kết nối API chung.
- Màn hình Đăng nhập Admin (JWT, phân quyền Super Admin/Admin/Moderator).
- Dashboard cơ bản:
  - Thống kê tổng: người dùng, tin đăng, tin chờ duyệt, báo cáo mới.
  - Hoạt động gần đây (tin đăng mới, user mới).
  - Sidebar nav + header user info, notifications.

### Phase B – Quản lý tin đăng (mục 11.3)
- **Quy trình duyệt tin:**
  - User đăng tin → Status: `pending` (chờ duyệt) → Hiển thị trong "Tin đã đăng" của user (tab "Đang chờ duyệt")
  - Admin duyệt → Status: `active` → Tin hiển thị ở trang chủ
  - Admin từ chối → Status: `rejected` → Hiển thị trong "Tin đã đăng" của user (tab "Đã từ chối")
  - User có thể ẩn tin → Status: `hidden` → Không hiển thị ở trang chủ
  - Tin đã cho thuê → Status: `rented` → Không hiển thị ở trang chủ
- Bảng danh sách tin với filter trạng thái/khu vực/loại tin.
- Chi tiết tin đăng với carousel, stats, action (Duyệt/Từ chối/Ẩn/Xóa/Gia hạn/Ghim).
- Bulk actions + lý do từ chối + gửi thông báo cho người đăng.
- **Trang chủ chỉ hiển thị tin có status = 'active'**

### Phase C – Quản lý người dùng (mục 11.4)
- Danh sách user (vai trò, trạng thái, số tin đã đăng).
- Chi tiết user: thông tin cá nhân, thống kê, danh sách tin, lịch sử hoạt động.
- Actions: Khóa/Mở khóa, Reset password, Gửi thông báo, Xác thực email thủ công.

### Phase D – Báo cáo & Nhật ký (mục 11.5 + 11.8)
- Module báo cáo: danh sách, chi tiết, xử lý (Chấp nhận/Từ chối, yêu cầu thêm info).
- Thống kê báo cáo (loại, tỷ lệ xử lý, top user bị báo cáo).
- Activity logs: ghi lại thao tác admin/user quan trọng, filter theo loại hành động.

### Phase E – Thống kê & Cài đặt (mục 11.6 + 11.7)
- Trang “Thống kê & Báo cáo”: biểu đồ user/tin/tương tác, export CSV/PDF, lịch gửi email báo cáo.
- Trang “Cài đặt hệ thống”: cấu hình tin đăng (ảnh tối đa, thời gian hiển thị), thông báo, bảo mật, backup.

### Phase F – Quản lý Admin & nâng cao (phần còn lại của 11.7 + 11.9)
- Quản lý tài khoản admin: danh sách, tạo mới, phân quyền chi tiết (RBAC).
- Log đăng nhập admin, khóa/mở khóa admin, 2FA (nếu cần).
- Module hỗ trợ chat takeover (admin tham gia cuộc chat) – optional.


