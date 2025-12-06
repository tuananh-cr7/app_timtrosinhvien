## Plan 3 – Tính năng nâng cao (ứng với cấp độ 🟠 & 🔴: mục 11.x trở đi)

### Phase 1 – Thông báo & real-time (mục 9.x + 18.x)
- Firebase Cloud Messaging:
  - Đăng ký token, gửi lên server.
  - Nhận thông báo foreground/background, mở đúng màn hình.
- Thông báo theo use case: chat mới, tin được duyệt, giá phòng yêu thích thay đổi.
- Real-time updates cơ bản (WebSocket connection manager).

### Phase 2 – Chat/Messaging hoàn chỉnh (mục 10.x + phần Chat detail)
- Hoàn thiện backend real-time (Socket/Firestore).
- Toàn bộ feature Chat box như đã mô tả (gửi ảnh nhiều, file, trạng thái gửi/đọc, mute, báo cáo, block, admin join chat).
- Push notification sync với chat.

### Phase 3 – Performance & Offline (mục 14.x + 24.x)
- Caching thông minh (danh sách phòng, ảnh, API response) + invalidation strategy.
- Lazy loading/Infinite scroll (màn hình danh sách, tìm kiếm, tin đã đăng).
- Offline mode:
  - Lưu danh sách phòng gần nhất.
  - Queue thao tác (favorite, lịch sử) -> sync khi online.
  - UI báo offline.

### Phase 4 – Tính năng thông minh & mở rộng (mục 11.1/11.2/12.x/17.x)
- Tìm kiếm nâng cao với voice search (Speech-to-Text) và filter theo bản đồ nâng cao (radius, draw polygon – optional).
- Gợi ý phòng trọ (Recommendation basic – collaborative filtering hoặc rule-based).
- So sánh phòng trọ (chọn tối đa 3 phòng, hiển thị bảng so sánh).
- Đặt lịch xem phòng (calendar + thông báo cho chủ trọ).
- Tùy thời gian: AI/ML (phát hiện gian lận, dự đoán giá), Chatbot hỗ trợ.


