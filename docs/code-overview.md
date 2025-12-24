# Tổng quan mã nguồn (app_timtrosinhvien)

## 1. Khởi động & điều hướng gốc
- `lib/main.dart`
  - Khởi tạo Firebase, Supabase, Hive, FCM, Presence, ServiceLocator.
  - Lắng nghe `authStateChanges` và quyết định flow qua `_RootDecider`:
    - Splash → Onboarding (nếu chưa xem) → Login/Email verification/Home.
    - Chặn admin claim (`_checkAdminClaim`) không cho vào app người dùng.
    - Kiểm tra khóa tài khoản từ Firestore (`_checkBan`, source: server); nếu bị khóa hiển thị màn cảnh báo + nút đăng xuất (dùng `AuthService.signOut()` để sign out cả Firebase & Google).
  - Không còn nghe realtime `users/{uid}`; kiểm tra khóa mỗi lần auth state thay đổi.

## 2. Xác thực
- `lib/features/auth/services/auth_service.dart`
  - Email sign in/up, Google sign-in (GoogleSignIn), reset password, resend verify, signOut (xóa FCM token, presence, FirebaseAuth.signOut, Google sign out).
  - Mapping lỗi Firebase Auth sang tiếng Việt; có xử lý code mới `invalid-credential`/`invalid-login-credentials`.
- `lib/features/auth/screens/login_screen.dart`
  - Form login email/password; Google login.
  - Không tự kiểm tra khóa hay điều hướng; chỉ `signIn...`, phần còn lại do `main.dart` quyết định.
  - Nếu email chưa verify → chuyển `EmailVerificationScreen`.

## 3. Tài khoản & hồ sơ
- `lib/features/account/account_screen.dart`
  - Hiển thị thông tin user (ưu tiên dữ liệu Firestore), menu: chỉnh sửa hồ sơ, đổi mật khẩu, phòng đã lưu, lịch sử xem, tin nhắn, tin đã đăng, đăng xuất, giới thiệu ứng dụng. (Đã bỏ mục “Liên hệ hỗ trợ”.)
  - Đăng xuất gọi `AuthService.signOut()` rồi điều hướng về `LoginScreen`.
- `lib/features/account/...` khác: edit profile, đổi mật khẩu, v.v.

## 4. Tìm kiếm & lọc
- `lib/features/search/screens/search_screen.dart`
  - Nút lọc nhanh: giá, tiện ích, loại phòng, “Số người” (maxPeople), diện tích, đồ dùng.
  - Lọc local: `maxPeople` giữ lại phòng `room.maxPeople <= filter.maxPeople` (nếu phòng không có maxPeople thì không lọc).
- `lib/features/search/widgets/people_filter_sheet.dart`
  - Bottom sheet slider 1–6 người.
- `lib/features/search/models/search_filter.dart`
  - Model filter, `maxPeople` tùy chọn, `hasFilters` tính gộp.

## 5. Phòng & đánh giá
- `lib/features/home/room_detail_screen.dart`
  - Hiển thị chi tiết phòng, hình ảnh fullscreen zoom, báo cáo phòng, đánh giá sao 1–5 + bình luận.
  - Gửi thông báo khi tạo review (`_sendReviewCreatedNotification`).
  - Đã sửa crash dialog báo cáo (dispose controller).

## 6. Chat & chặn/ẩn
- `lib/features/chat/screens/conversation_detail_screen.dart`
  - Chat, gửi ảnh, mở phòng.
  - Mute/unmute: trạng thái `_isMuted`, toggle theo Firestore.
  - Chặn/mở chặn: lưu `isBlocked`, `blockedBy`, ẩn thanh nhập khi bị chặn, chỉ người chặn thấy nút mở chặn; kiểm tra hai chiều qua repo.
- `lib/features/chat/data/repositories/conversations_repository.dart`
  - `toggleMuteConversation`, `toggleBlockUser`, `checkBlockStatus`, `getOtherParticipantId`.
- `lib/features/chat/screens/conversations_list_screen.dart`
  - Sửa hiển thị tên/ảnh participant khác (không hiển thị tên chính mình), cập nhật `otherUserId` sai.

## 7. Quản trị (Admin)
- `lib/main_admin.dart`
  - Trang web Admin: đăng nhập, sidebar Dashboard/Người dùng/Quản lý tin/Đánh giá/Báo cáo/Thống kê.
  - Người dùng: nút Khóa/Mở khóa cập nhật `users/{uid}.banned`.
  - Báo cáo & Đánh giá: viewer ảnh slideshow (có mũi tên, dots), merge ảnh từ room khi thiếu; xem review, xóa review, gửi thông báo khi xóa.
  - Thống kê: nhiều chỉ số (đánh giá, báo cáo), fallback tránh lỗi thiếu index.
  - Chuẩn hóa tìm kiếm tiếng Việt bằng `normalizeVietnamese`.

## 8. Thông báo
- `lib/features/notifications/models/notification.dart`
  - Enum `NotificationType` có `room_hidden`, `review_new`, `review_removed`.
- `lib/features/notifications/screens/notifications_screen.dart`
  - Điều hướng theo loại: ẩn phòng, review mới/bị xóa → mở `RoomDetailScreen`.

## 9. Bảo mật Firestore
- `firestore.rules`
  - `users/{userId}/blockedUsers`: chỉ chủ sở hữu được đọc/ghi/xóa.
  - `rooms/{roomId}/reviews`: ai cũng đọc; tạo/sửa/xóa chỉ chủ `userId` với rating 1–5.
  - `messages` create chặn khi `conversations/{convId}.isBlocked == true`.
  - `notifications` cho phép type `room_hidden`, `review_new`, `review_removed`.

## 10. Khác
- Hình ảnh: dùng `CachedNetworkImage`, `InteractiveViewer`, page view có điều khiển.
- Thông báo: gửi in-app khi review tạo/xóa, phòng bị ẩn.
- Local search: dùng `normalizeVietnamese` để bỏ dấu cho lọc email/bình luận.

## Gợi ý kiểm thử nhanh
- Đăng nhập email/Google với tài khoản bị khóa → phải vào màn “Tài khoản đã bị khóa”, nút Đăng xuất (Google cũng sign out).
- Mở khóa tài khoản → login vào Home bình thường.
- Chat: chặn → ẩn thanh nhập, chỉ người chặn thấy nút mở chặn; mở chặn → cả hai chat lại được.
- Admin: Khóa/Mở khóa user cập nhật `users/{uid}.banned`; báo cáo/review: xem slideshow ảnh, xóa review gửi notif.

