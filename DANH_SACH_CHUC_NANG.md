# DANH SÁCH CHỨC NĂNG - ỨNG DỤNG TÌM KIẾM PHÒNG TRỌ SINH VIÊN

## 📋 MỤC LỤC
1. [Cấp độ Dễ (Beginner)](#cấp-độ-dễ-beginner)
2. [Cấp độ Trung bình (Intermediate)](#cấp-độ-trung-bình-intermediate)
3. [Cấp độ Khó (Advanced)](#cấp-độ-khó-advanced)
4. [Cấp độ Rất Khó (Expert)](#cấp-độ-rất-khó-expert)

---

## 🟢 CẤP ĐỘ DỄ (BEGINNER)

### 1. Giao diện cơ bản (UI/UX)
#### 1.1. Màn hình Splash Screen
- **Mô tả**: Hiển thị logo và tên ứng dụng khi khởi động
- **Chi tiết**:
  - Logo ứng dụng ở giữa màn hình
  - Tên ứng dụng phía dưới logo
  - Animation fade in/out
  - Thời gian hiển thị: 2-3 giây
  - Tự động chuyển sang màn hình tiếp theo

#### 1.2. Màn hình Onboarding/Intro
- **Mô tả**: Giới thiệu ứng dụng cho người dùng mới
- **Chi tiết**:
  - 3-4 màn hình giới thiệu với hình ảnh minh họa
  - Nút "Bỏ qua" và "Tiếp theo"
  - Indicator dots để hiển thị trang hiện tại
  - Lưu trạng thái đã xem (SharedPreferences)

#### 1.3. Màn hình Đăng nhập/Đăng ký
- **Mô tả**: Xác thực người dùng
- **Chi tiết**:
  - Form đăng nhập: Email/Số điện thoại + Mật khẩu
  - Form đăng ký: Họ tên, Email, Số điện thoại, Mật khẩu, Xác nhận mật khẩu
  - Validation cơ bản (email format, password length)
  - Nút "Quên mật khẩu"
  - Checkbox "Ghi nhớ đăng nhập"
  - Hiển thị/Ẩn mật khẩu

#### 1.4. Bottom Navigation Bar
- **Mô tả**: Điều hướng chính trong ứng dụng
- **Chi tiết**:
  - **5 tabs chính**:
    - **Trang chủ**: Icon nhà (home), text "Trang chủ"
    - **Tìm kiếm**: Icon kính lúp (search), text "Tìm kiếm"
    - **Yêu thích**: Icon trái tim (favorite), text "Yêu thích"
    - **Thông báo**: Icon chuông (notifications), text "Thông báo"
    - **Tài khoản**: Icon người (account), text "Tài khoản"
  - **Thiết kế**:
    - Background màu trắng
    - Border top nhẹ (màu xám nhạt) để phân cách
    - Tab active: Icon và text màu xanh dương (#2196F3 hoặc tương tự)
    - Tab không active: Icon và text màu xám
    - Icon size: ~24-28px
    - Text size: ~12px, font weight normal
    - Padding vertical và horizontal phù hợp
  - **Tính năng**:
    - Badge số thông báo chưa đọc trên tab "Thông báo" (nếu có)
    - Animation smooth khi chuyển tab
    - Tap feedback (ripple effect)
    - Fixed position ở bottom màn hình

#### 1.5. Màn hình Trang chủ (Home)
- **Mô tả**: Hiển thị các phòng trọ nổi bật và mới nhất
- **Chi tiết**:
  - **Header Section**:
    - Tiêu đề lớn: "Nhà Trọ 360" (font size lớn, bold)
    - Subtitle: "Phòng mới cập nhật tại [Tên thành phố]" (ví dụ: "Phòng mới cập nhật tại Hà Nội")
    - Nút "Đăng tin" màu xanh dương ở góc phải header (icon + và text "Đăng tin")
    - Background trắng, không có AppBar mặc định
  
  - **Section "Phòng mới đăng"**:
    - Tiêu đề section: "Phòng mới đăng"
    - Card phòng trọ lớn (full width hoặc gần full width):
      - Hình ảnh phòng trọ (aspect ratio ~16:9 hoặc 4:3)
      - Overlay giá ở góc dưới trái hình ảnh:
        - Background màu xanh dương với độ trong suốt
        - Text màu trắng: "[Giá] triệu /tháng" (ví dụ: "4,6 triệu /tháng")
        - Font size vừa, bold
      - Thông tin dưới hình ảnh:
        - Icon địa điểm (location pin) + Địa chỉ (ví dụ: "Nhân Hòa, Nhân Chính, Thanh Xuân...")
        - Icon sơ đồ (floor plan) + Diện tích (ví dụ: "30 m²")
        - Text màu xám, font size nhỏ
  
  - **Section "Phòng ở ghép"**:
    - Tiêu đề section: "Phòng ở ghép"
    - Hiển thị text "Chưa có tin ở ghép" khi chưa có dữ liệu
    - Khi có dữ liệu: Hiển thị danh sách card phòng ở ghép tương tự section "Phòng mới đăng"
  
  - **Section "Tất cả phòng"**:
    - Tiêu đề section: "Tất cả phòng"
    - Danh sách các card phòng trọ (scrollable):
      - Mỗi card tương tự card trong "Phòng mới đăng"
      - Layout dạng list vertical
      - Có thể scroll để xem thêm
  
  - **Bottom Navigation Bar** (5 tabs):
    - **Trang chủ** (active): Icon nhà, text "Trang chủ", màu xanh khi active
    - **Tìm kiếm**: Icon kính lúp, text "Tìm kiếm"
    - **Yêu thích**: Icon trái tim, text "Yêu thích"
    - **Thông báo**: Icon chuông, text "Thông báo"
    - **Tài khoản**: Icon người, text "Tài khoản"
    - Background trắng, border top nhẹ
    - Tab active có màu xanh dương, tab không active màu xám
  
  - **Tính năng bổ sung**:
    - Pull to refresh để làm mới danh sách
    - Scroll smooth, không lag
    - Click vào card phòng trọ để xem chi tiết
    - Click nút "Đăng tin" để chuyển sang màn hình đăng tin

### 2. Hiển thị dữ liệu cơ bản
#### 2.1. Danh sách phòng trọ
- **Mô tả**: Hiển thị danh sách các phòng trọ
- **Chi tiết**:
  - **Card phòng trọ**:
    - **Hình ảnh**:
      - Hình ảnh thumbnail phòng trọ (aspect ratio ~16:9 hoặc 4:3)
      - Full width card, bo góc nhẹ (border radius ~8-12px)
      - Shadow nhẹ để tạo độ sâu
    - **Overlay giá** (trên hình ảnh):
      - Vị trí: Góc dưới trái hình ảnh
      - Background: Màu xanh dương với độ trong suốt (~80% opacity)
      - Text: "[Giá] triệu /tháng" (ví dụ: "4,6 triệu /tháng")
      - Màu text: Trắng
      - Font size: 14-16px, font weight: bold
      - Padding: 8-12px
    - **Thông tin dưới hình ảnh**:
      - **Địa chỉ**:
        - Icon location pin (màu xám)
        - Text địa chỉ (màu xám đậm, font size 13-14px)
        - Truncate nếu quá dài (thêm "...")
      - **Diện tích**:
        - Icon sơ đồ/phòng (màu xám)
        - Text diện tích (ví dụ: "30 m²")
        - Màu xám, font size 13-14px
      - Layout: Row với spacing giữa các thông tin
      - Padding: 12-16px
    - **Tương tác**:
      - Click vào card để xem chi tiết
      - Tap feedback (ripple effect)
      - Có thể thêm icon yêu thích ở góc trên phải (optional)
  - **Layout danh sách**:
    - Vertical list (Column/ListView)
    - Spacing giữa các card: 12-16px
    - Padding horizontal: 16px
    - Scrollable, smooth scrolling
  - **Pagination**:
    - Infinite scroll hoặc nút "Xem thêm"
    - Loading indicator khi load thêm
  - **Loading state**:
    - Skeleton loading hoặc shimmer effect
    - Hiển thị khi đang tải dữ liệu

#### 2.2. Chi tiết phòng trọ
- **Mô tả**: Hiển thị thông tin chi tiết một phòng trọ khi người dùng click vào card phòng trọ
- **Chi tiết**:
  
  **Header:**
  - Icon mũi tên quay lại (back) ở góc trái
  - Nút yêu thích (icon trái tim) ở góc phải
    - Trái tim màu đỏ khi đã yêu thích
    - Trái tim outline khi chưa yêu thích
    - Click để thêm/xóa yêu thích
  - Nút 3 chấm (more options) ở góc phải trên, bên cạnh nút yêu thích
    - Click để mở bottom sheet với các tùy chọn
  
  **Hình ảnh phòng trọ:**
  - Hình ảnh lớn chiếm khoảng 2/3 chiều rộng màn hình ở phần trên
  - Hiển thị hình ảnh chính của phòng trọ
  - Có thể swipe để xem nhiều hình ảnh (carousel)
  - Indicator dots để hiển thị số lượng và vị trí hình ảnh hiện tại
  - Full width, aspect ratio ~16:9 hoặc 4:3
  
  **Thông tin giá thuê:**
  - Hiển thị nổi bật: "[Giá] triệu /tháng" (ví dụ: "4,6 triệu /tháng")
  - Font size lớn (18-24px), font weight bold
  - Màu đen hoặc màu chủ đạo của app
  - Có thể có icon trái tim nhỏ bên cạnh (nút yêu thích)
  
  **Thông tin địa chỉ:**
  - Icon location pin (màu xám hoặc màu chủ đạo)
  - Text địa chỉ đầy đủ: "[Số nhà], [Tên đường], [Phường/Xã], [Quận/Huyện], [Thành phố]"
  - Ví dụ: "Nhân Hòa, Nhân Chính, Thanh Xuân, Hà Nội"
  - Font size: 14-16px
  - Có thể click để mở bản đồ
  
  **Thông tin người đăng:**
  - Icon người (user icon)
  - Text: "Người đăng: [Tên]" hoặc "Người đăng: Chưa rõ"
  - Font size: 14px, màu xám
  
  **Thông tin liên hệ:**
  - Icon điện thoại
  - Text: "[Số điện thoại]" hoặc "Chưa có số liên hệ"
  - Font size: 14px, màu xám
  - Nếu có số điện thoại: Có thể click để gọi
  
  **Thông tin thời gian đăng:**
  - Icon đồng hồ
  - Text: "Đã đăng [thời gian]" (ví dụ: "Đã đăng 1 tuần trước")
  - Format: "X phút trước", "X giờ trước", "X ngày trước", "X tuần trước", "X tháng trước"
  - Font size: 14px, màu xám
  
  **Nút hành động chính:**
  - **Nút "Gọi ngay"** (Call now):
    - Background màu xám hoặc màu chủ đạo
    - Icon điện thoại bên trái
    - Text màu trắng
    - Bo góc, padding đầy đủ
    - Click để mở dialer với số điện thoại
  - **Nút "Gửi SMS"** (Send SMS):
    - Background trắng hoặc màu nhạt
    - Icon tin nhắn bên trái
    - Text màu xám hoặc màu chủ đạo
    - Bo góc, border nhẹ
    - Click để mở SMS app với số điện thoại
  
  **Tags thông tin nhanh:**
  - Hiển thị dạng chips/tags bo tròn:
    - **Diện tích**: Icon thước đo + "[Diện tích] m²" (ví dụ: "30 m²")
    - **Loại phòng**: Icon tòa nhà/phòng + "[Loại]" (ví dụ: "room", "Căn hộ")
    - **Loại cho thuê**: Icon người + "[Loại]" (ví dụ: "Cho thuê riêng", "Ở ghép")
  - Background màu xám nhạt hoặc màu nhạt
  - Text màu đen hoặc xám đậm
  - Font size: 12-14px
  - Spacing giữa các tags
  
  **Section "Mô tả":**
  - Title: "Mô tả" (bold, font size 16-18px)
  - Nội dung mô tả chi tiết phòng trọ
  - Text màu đen, font size 14px
  - Line height phù hợp để dễ đọc
  - Có thể expand/collapse nếu mô tả quá dài
  - Nếu chưa có mô tả: Hiển thị text "Chưa có mô tả" màu xám
  
  **Section "Vị trí":**
  - Title: "Vị trí" (bold, font size 16-18px)
  - **Bản đồ nhúng (Embedded Map):**
    - Tích hợp OpenStreetMap sử dụng flutter_map
    - Hiển thị bản đồ với marker đánh dấu vị trí phòng trọ
    - Marker màu đỏ (teardrop shape) hoặc custom icon
    - Có thể zoom in/out bằng pinch gesture
    - Có thể pan/drag để di chuyển bản đồ
    - Có thể click để mở bản đồ full screen
    - Hiển thị tên đường, phường, quận trên bản đồ từ OSM data
    - Hiển thị tọa độ GPS nếu có
    - Nút "Chỉ đường" để tính toán route đến vị trí này (sử dụng OSRM)
  - **Tọa độ GPS:**
    - Hiển thị "Lat: [latitude], Lng: [longitude]" nếu có
    - Hoặc text "Chưa có vị trí GPS" nếu chưa có tọa độ
    - Màu xám, font size nhỏ
  
  **Section "Tiện ích":**
  - Title: "Tiện ích" (bold)
  - Grid hiển thị các tiện ích có sẵn:
    - Wifi, WC riêng, Giữ xe, Điều hoà, Tủ lạnh, Máy giặt, Bếp riêng, Tự do giờ giấc...
  - Icon + text cho mỗi tiện ích
  - Layout grid 2-3 cột
  
  **Section "Đồ dùng có sẵn":**
  - Title: "Đồ dùng có sẵn" (bold)
  - Grid hiển thị các đồ dùng:
    - Giường, Tủ quần áo, Bàn ghế, Bếp, Máy lạnh, Máy giặt, Tủ lạnh, Nệm...
  - Icon + text cho mỗi đồ dùng
  - Layout grid 2-3 cột
  
  **Bottom Sheet - Menu tùy chọn (khi bấm nút 3 chấm):**
  - Bottom sheet trượt lên từ dưới khi click nút 3 chấm
  - Background trắng, bo góc ở phần trên
  - Có handle bar (thanh kéo) ở trên cùng để đóng/mở
  - Danh sách các tùy chọn với icon và text:
    - **"Gọi điện"** (Call):
      - Icon điện thoại
      - Text "Gọi điện"
      - Click để mở dialer
    - **"Gửi SMS"** (Send SMS):
      - Icon tin nhắn
      - Text "Gửi SMS"
      - Click để mở SMS app
    - **"Chỉ đường"** (Get directions):
      - Icon navigation/mũi tên
      - Text "Chỉ đường"
      - Click để mở bottom sheet với các tùy chọn:
        - **"Chỉ đường trong app"**: Sử dụng OSRM để tính toán và hiển thị route trên OpenStreetMap
        - **"Mở Google Maps"**: Mở Google Maps app với chỉ đường (nếu có cài đặt)
        - **"Mở Apple Maps"**: Mở Apple Maps app với chỉ đường (iOS, nếu có cài đặt)
        - **"Sao chép địa chỉ"**: Copy địa chỉ để paste vào ứng dụng khác
    - **"Chia sẻ"** (Share):
      - Icon chia sẻ (2 chữ V nối nhau)
      - Text "Chia sẻ"
      - Click để mở share sheet (chia sẻ qua Facebook, Zalo, SMS, Email...)
    - **"Chat với chủ trọ"** (Chat with landlord):
      - Icon chat bubble
      - Text "Chat với chủ trọ"
      - Click để mở màn hình chat
  - Mỗi option có padding đầy đủ, tap feedback
  - Có thể swipe down để đóng bottom sheet
  - Click ra ngoài bottom sheet để đóng
  
  **Tính năng bổ sung:**
  - Pull to refresh để làm mới thông tin
  - Scroll smooth để xem toàn bộ nội dung
  - Loading indicator khi đang tải dữ liệu
  - Error handling nếu không tải được dữ liệu
  - Share deep link để chia sẻ link đến phòng trọ này
  - Báo cáo tin đăng nếu có vấn đề (spam, sai thông tin...)

#### 2.3. Màn hình Tài khoản
- **Mô tả**: Màn hình quản lý tài khoản và thông tin cá nhân
- **Chi tiết**:
  
  **Thông tin tài khoản (Card trên cùng):**
  - Card trắng, bo góc, shadow nhẹ
  - **Avatar:**
    - Circular avatar màu xanh dương nhạt
    - Hiển thị chữ cái đầu của tên (ví dụ: "T" cho "Tuan Anh")
    - Màu chữ trắng hoặc xanh đậm
    - Size: ~60-80px
  - **Tên người dùng:**
    - Font size lớn, bold
    - Màu đen/xám đậm
    - Ví dụ: "Tuan Anh"
  - **Email:**
    - Font size nhỏ hơn, màu xám
    - Ví dụ: "cungdinhtuananh@gmail.com"
  - **Icon chỉnh sửa** (pencil) ở góc phải card:
    - Icon màu xanh dương
    - Click để mở màn hình "Chỉnh sửa hồ sơ"
  
  **Menu Section 1 - Cài đặt cá nhân:**
  - Card trắng, bo góc, chứa các menu items
  - Mỗi item có:
    - Icon bên trái (màu xám hoặc màu chủ đạo)
    - Text ở giữa
    - Icon mũi tên phải (>) ở bên phải
  - Các menu items:
    - **"Chỉnh sửa hồ sơ"** (Edit profile):
      - Icon: Người với bút chì
      - Click để mở màn hình chỉnh sửa hồ sơ
    - **"Đổi mật khẩu"** (Change password):
      - Icon: Khóa với mũi tên tròn
      - Click để mở màn hình đổi mật khẩu
    - **"Phòng đã lưu"** (Saved rooms):
      - Icon: Trái tim
      - Click để mở màn hình yêu thích (đã mô tả ở phần 8.1)
    - **"Lịch sử xem"** (View history):
      - Icon: Đồng hồ với mũi tên tròn
      - Click để mở màn hình lịch sử xem phòng
    - **"Tin đã đăng"** (Posted listings):
      - Icon: Danh sách/tài liệu với nhiều dòng
      - Click để mở màn hình quản lý tin đã đăng
    - **"Đăng xuất"** (Logout):
      - Icon: Cửa với mũi tên phải
      - Click để hiển thị dialog xác nhận đăng xuất
  
  **Menu Section 2 - Thông tin ứng dụng:**
  - Card trắng, bo góc, chứa các menu items
  - Các menu items:
    - **"Giới thiệu ứng dụng"** (About app):
      - Icon: Chữ "i" trong vòng tròn
      - Click để mở màn hình giới thiệu ứng dụng
    - **"Liên hệ hỗ trợ"** (Contact support):
      - Icon: Điện thoại với 2 mũi tên tròn
      - Click để mở màn hình liên hệ hỗ trợ
  
  **Dialog xác nhận đăng xuất:**
  - Hiển thị khi click "Đăng xuất"
  - Background overlay tối
  - Dialog trắng, bo góc, center màn hình
  - **Title**: "Xác nhận đăng xuất" (bold, font size lớn)
  - **Message**: "Bạn có chắc chắn muốn đăng xuất?" (font size vừa)
  - **Action Buttons**:
    - **"Hủy"** (Cancel): Text màu xanh, bên trái
    - **"Đăng xuất"** (Log out): Text màu xanh, bên phải
  - Click "Đăng xuất": Xóa token, clear local data, navigate về màn hình đăng nhập
  - Click "Hủy" hoặc click ra ngoài: Đóng dialog

#### 2.3.1. Chỉnh sửa hồ sơ
- **Mô tả**: Màn hình chỉnh sửa thông tin cá nhân
- **Chi tiết**:
  - **Header:**
    - Icon mũi tên quay lại (back) ở góc trái
    - Title "Chỉnh sửa hồ sơ" ở giữa
  
  - **Form fields:**
    - **Họ tên (Full name):**
      - Label "Họ tên" phía trên
      - Input field với underline
      - Pre-filled với tên hiện tại (ví dụ: "Tuan Anh")
      - Validation: Bắt buộc, tối thiểu 2 ký tự
    
    - **Số điện thoại (Phone number):**
      - Label "Số điện thoại" phía trên
      - Input field với underline
      - Pre-filled với số điện thoại hiện tại (ví dụ: "0336465426")
      - Validation: Format số điện thoại Việt Nam (10 số)
    
    - **Thành phố (City):**
      - Label "Thành phố" phía trên
      - Dropdown/Select field với underline
      - Icon dropdown arrow bên phải
      - Danh sách các thành phố: Hà Nội, TP.HCM, Đà Nẵng...
      - Có thể để trống
    
    - **Quận/Huyện (District):**
      - Label "Quận/Huyện" phía trên
      - Dropdown/Select field phụ thuộc vào thành phố đã chọn
      - Icon dropdown arrow bên phải
      - Có thể để trống
  
  - **Nút "Lưu thay đổi"** (Save changes):
    - Button lớn, bo góc, màu xanh dương nhạt
    - Text màu xanh dương đậm
    - Full width với padding 2 bên
    - Click để validate và lưu thay đổi
    - Hiển thị loading khi đang lưu
    - Thông báo thành công/lỗi sau khi lưu
    - Navigate back sau khi lưu thành công

#### 2.3.2. Đổi mật khẩu
- **Mô tả**: Màn hình thay đổi mật khẩu tài khoản
- **Chi tiết**:
  - **Header:**
    - Icon mũi tên quay lại (back) ở góc trái
    - Title "Đổi mật khẩu" ở giữa
  
  - **Form fields:**
    - **Mật khẩu hiện tại (Current password):**
      - Label "Mật khẩu hiện tại" phía trên
      - Input field password với underline
      - Icon hiển thị/ẩn mật khẩu
      - Validation: Bắt buộc, phải khớp với mật khẩu hiện tại
    
    - **Mật khẩu mới (New password):**
      - Label "Mật khẩu mới" phía trên
      - Input field password với underline
      - Icon hiển thị/ẩn mật khẩu
      - Validation: Bắt buộc, tối thiểu 6-8 ký tự
    
    - **Xác nhận mật khẩu mới (Confirm new password):**
      - Label "Xác nhận mật khẩu mới" phía trên
      - Input field password với underline
      - Icon hiển thị/ẩn mật khẩu
      - Validation: Bắt buộc, phải khớp với mật khẩu mới
  
  - **Nút "Cập nhật mật khẩu"** (Update password):
    - Button lớn, bo góc, background màu xanh dương nhạt
    - Text màu xanh dương đậm
    - Full width với padding 2 bên
    - Click để validate và cập nhật mật khẩu
    - Hiển thị loading khi đang cập nhật
    - Thông báo thành công/lỗi
    - Navigate back sau khi thành công
    - Yêu cầu đăng nhập lại sau khi đổi mật khẩu thành công

#### 2.3.3. Tin đã đăng
- **Mô tả**: Màn hình quản lý các tin đăng của người dùng
- **Chi tiết**:
  - **Header:**
    - Icon mũi tên quay lại (back) ở góc trái
    - Title "Tin đã đăng" ở giữa
  
  - **Danh sách tin đăng:**
    - Vertical list các card tin đăng
    - Mỗi card hiển thị:
      - **Hình ảnh** (nếu có):
        - Thumbnail hình ảnh đầu tiên của phòng trọ
        - Carousel indicator nếu có nhiều ảnh
        - Overlay giá ở góc dưới trái: "[Giá] triệu /tháng" (ví dụ: "2 triệu /tháng", "1,2 triệu /tháng")
      
      - **Loại tin:**
        - Text "cho thuê" hoặc "tìm người ở ghép"
        - Màu xám, font size nhỏ
      
      - **Địa chỉ:**
        - Icon location pin
        - Text địa chỉ (có thể truncate): "8, 288 phú diễn, phú diễn, Bắc Từ Liêm, H..."
      
      - **Tags tiện ích:**
        - Diện tích: "[Số] m²" với icon thước đo (ví dụ: "20 m²", "30 m²")
        - Tiện ích: "Wifi" với icon wifi
        - Đồ dùng: "Giường" với icon giường
        - Layout: Row với spacing
      
      - **Thông tin thống kê:**
        - **Status tag**: Badge màu xám với text:
          - "Đang chờ duyệt" (Pending approval)
          - "Đã cho thuê" (Rented)
          - "Đang hiển thị" (Active)
          - "Đã ẩn" (Hidden)
        - **Lượt xem**: "Lượt xem: [Số]" (ví dụ: "Lượt xem: 0")
        - **Liên hệ**: "Liên hệ: [Số]" (ví dụ: "Liên hệ: 0")
      
      - **Action icons:**
        - Icon checkmark (màu xanh): Xác nhận/duyệt tin
        - Icon thùng rác (màu đỏ): Xóa tin đăng
          - Click để hiển thị dialog xác nhận xóa
          - Sau khi xác nhận: Xóa tin và cập nhật danh sách
  
  - **Empty state:**
    - Hiển thị khi chưa có tin nào
    - Icon tài liệu/danh sách lớn, màu xám nhạt
    - Text: "Chưa có tin đăng nào"
    - Text hướng dẫn: "Bấm vào nút 'Đăng tin' để tạo tin đăng mới"
  
  - **Tương tác:**
    - Click vào card: Navigate đến màn hình chi tiết tin đăng (có thể chỉnh sửa)
    - Swipe to delete: Vuốt card sang trái để hiện nút xóa
    - Long press: Hiện menu với options (Chỉnh sửa, Xóa, Gia hạn, Ẩn/Hiện)

#### 2.3.4. Lịch sử xem phòng
- **Mô tả**: Màn hình hiển thị các phòng trọ đã xem gần đây
- **Chi tiết**:
  - **Header:**
    - Icon mũi tên quay lại (back) ở góc trái
    - Title "Lịch sử xem phòng" ở giữa
    - Nút "Xóa tất cả" (Clear all) ở góc phải:
      - Text màu xanh dương
      - Click để hiển thị dialog xác nhận
      - Sau khi xác nhận: Xóa toàn bộ lịch sử
  
  - **Danh sách lịch sử:**
    - Vertical list các item đã xem
    - Mỗi item hiển thị:
      - **Thumbnail hình ảnh** (bên trái):
        - Size: ~80-100px, square hoặc 4:3
        - Bo góc nhẹ
        - Hiển thị hình ảnh đầu tiên của phòng trọ
      
      - **Thông tin** (bên phải):
        - **Địa chỉ/Tiêu đề**:
          - Text địa chỉ hoặc loại tin (ví dụ: "Nhân Hòa, Nhân Chính, Thanh Xuân, H...", "cho thuê", "tim nguoi o ghep", "cho thuê trọ")
          - Font size: 14-16px, màu đen/xám đậm
          - Truncate nếu quá dài
        - **Địa chỉ chi tiết** (nếu có):
          - Text địa chỉ đầy đủ (ví dụ: "8, 288 phú diễn, phú diễn, Bắc Từ Liêm...")
          - Font size: 12-14px, màu xám
        - **Thời gian xem**:
          - Text relative time (ví dụ: "5 phút trước", "15 phút trước", "2 ngày trước")
          - Font size: 12px, màu xám
          - Format: "X phút trước", "X giờ trước", "X ngày trước", "X tuần trước"
      
      - Layout: Row với spacing phù hợp
      - Padding: 12-16px
  
  - **Tương tác:**
    - Click vào item: Navigate đến màn hình chi tiết phòng trọ
    - Swipe to delete: Vuốt item sang trái để xóa khỏi lịch sử
    - Long press: Hiện menu với option "Xóa"
  
  - **Empty state:**
    - Hiển thị khi chưa có lịch sử nào
    - Icon đồng hồ lớn, màu xám nhạt
    - Text: "Chưa có lịch sử xem nào"
    - Text hướng dẫn: "Các phòng bạn xem sẽ được lưu ở đây"
  
  - **Giới hạn:**
    - Tự động xóa các item cũ khi vượt quá 50-100 tin
    - Sắp xếp theo thời gian xem (mới nhất trước)

#### 2.3.5. Giới thiệu ứng dụng
- **Mô tả**: Màn hình thông tin về ứng dụng
- **Chi tiết**:
  - **Header:**
    - Icon mũi tên quay lại (back) ở góc trái
    - Title "Giới thiệu" ở giữa
  
  - **Card 1 - Thông tin ứng dụng:**
    - Background màu xám nhạt, bo góc
    - **Tên ứng dụng**: "Nhà Trọ 360" (font size lớn, bold)
    - **Mô tả**: "Ứng dụng hỗ trợ tìm kiếm và quản lý phòng trọ nhanh chóng dành cho sinh viên và người đi làm."
    - **Version**: "Phiên bản: 1.0.0" (font size nhỏ, màu xám)
  
  - **Card 2 - Tương tác:**
    - Background màu xám nhạt, bo góc
    - **Row 1 - Đánh giá ứng dụng:**
      - Icon sao màu cam bên trái
      - Text "Đánh giá ứng dụng" (bold)
      - Subtitle "Chia sẻ cảm nhận của bạn"
      - Click để mở Google Play Store/App Store để đánh giá
    - **Row 2 - Website:**
      - Icon globe màu xanh bên trái
      - Text "Website"
      - URL "nhatro360.example.com"
      - Icon mũi tên phải bên phải
      - Click để mở website trong browser
  
  - **Card 3 - Nhóm phát triển:**
    - Background màu xám nhạt, bo góc
    - **Title**: "Nhóm phát triển" (bold)
    - Icon nhóm người màu xanh bên trái
    - **Danh sách thành viên:**
      - "UI/UX: Bạn A"
      - "Flutter: Bạn B"
      - "Backend: Bạn C"
    - Layout: Column với spacing

#### 2.3.6. Liên hệ hỗ trợ
- **Mô tả**: Màn hình liên hệ với đội ngũ hỗ trợ
- **Chi tiết**:
  - **Header:**
    - Icon mũi tên quay lại (back) ở góc trái
    - Title "Liên hệ" ở giữa
  
  - **Danh sách phương thức liên hệ:**
    - Mỗi item là một card/row với:
      - Icon tròn màu xanh dương bên trái
      - Text và sub-text ở giữa
      - Icon mũi tên chéo (external link) bên phải
    - **Các phương thức:**
      - **Hỗ trợ nhanh (Quick Support):**
        - Icon: Điện thoại màu trắng trong circle xanh
        - Text: "Hỗ trợ nhanh"
        - Sub-text: "0901 234 567"
        - Click để mở dialer với số điện thoại
      
      - **Email hỗ trợ (Email Support):**
        - Icon: Phong bì màu trắng trong circle xanh
        - Text: "Email hỗ trợ"
        - Sub-text: "support@nhatro360.com"
        - Click để mở email client với địa chỉ email
      
      - **Facebook:**
        - Icon: Logo Facebook màu trắng trong circle xanh
        - Text: "Facebook"
        - Sub-text: "facebook.com/nhatro360"
        - Click để mở Facebook app hoặc browser
      
      - **Zalo:**
        - Icon: Logo Zalo màu trắng trong circle xanh
        - Text: "Zalo"
        - Sub-text: "Nhà Trọ 360"
        - Click để mở Zalo app
      
      - **Địa chỉ văn phòng (Office Address):**
        - Icon: Globe màu trắng trong circle xanh
        - Text: "Địa chỉ văn phòng"
        - Sub-text: "Tầng 5, 123 Nguyễn Trãi, Hà Nội"
        - Click để mở bottom sheet với các tùy chọn:
          - **"Xem trên bản đồ"**: Mở màn hình bản đồ với marker tại địa chỉ văn phòng (OpenStreetMap)
          - **"Chỉ đường"**: Tính toán route từ vị trí hiện tại đến văn phòng (OSRM)
          - **"Mở Google Maps"**: Mở Google Maps app (nếu có cài đặt)
          - **"Mở Apple Maps"**: Mở Apple Maps app (iOS, nếu có cài đặt)
          - **"Sao chép địa chỉ"**: Copy địa chỉ
  
  - **Layout:**
    - Vertical list các cards
    - Spacing giữa các items: 12-16px
    - Padding horizontal: 16px

### 3. Tìm kiếm cơ bản
#### 3.1. Màn hình Tìm kiếm
- **Mô tả**: Màn hình tìm kiếm phòng trọ với nhiều bộ lọc và tùy chọn
- **Chi tiết**:
  
  **Header:**
  - **Title**: "Tìm kiếm phòng trọ" (font size lớn, bold)
  - **Subtitle**: "Chọn từ khóa và bộ lọc để tìm phòng phù hợp" (font size nhỏ, màu xám)
  
  **Nút "Tìm bằng bản đồ":**
  - Button màu xanh dương đậm, bo góc
  - Icon bản đồ bên trái
  - Text "Tìm bằng bản đồ" màu trắng
  - Click để chuyển sang màn hình tìm kiếm trên bản đồ
  
  **Thanh tìm kiếm:**
  - Input field lớn, bo góc, background màu xám nhạt
  - Icon kính lúp (magnifying glass) bên trái
  - Placeholder text: "Tìm theo tên, địa chỉ..."
  - Có thể nhập từ khóa để tìm kiếm
  - Tìm kiếm theo: Tên phòng, địa chỉ, khu vực
  - Lịch sử tìm kiếm (5-10 từ khóa gần nhất) khi focus vào input
  - Gợi ý tìm kiếm (autocomplete) khi đang nhập
  
  **Filter Categories (Primary Filters - Horizontal Scrollable):**
  - Row các filter categories có thể scroll ngang
  - Mỗi category có dropdown arrow icon
  - Các categories:
    - **"Giá"** (Price) - Click để mở bottom sheet lọc giá
    - **"Tiện ích"** (Amenities) - Click để mở bottom sheet lọc tiện ích
    - **"Loại phòng"** (Room type) - Click để mở bottom sheet lọc loại phòng
    - **"Số người"** (Number of people) - Click để mở bottom sheet lọc số người
  - Category đang active: Text màu xanh dương, arrow hướng lên
  - Category không active: Text màu đen/xám, arrow hướng xuống
  
  **Quick Filter Buttons:**
  - Row các nút filter nhanh bên dưới filter categories
  - Layout: Grid hoặc wrap, responsive
  - Các nút:
    - **"Chọn địa điểm"** (Select location):
      - Icon location pin
      - Background trắng hoặc màu nhạt
      - Click để mở bottom sheet chọn địa điểm
      - Hiển thị địa điểm đã chọn khi có (ví dụ: "Hà Nội - Thanh Xuân")
    - **"Diện tích: [min]-[max] m²"** (Area):
      - Icon thước đo/ruler
      - Hiển thị range đã chọn (ví dụ: "Diện tích: 10-40 m²")
      - Click để mở bottom sheet chọn diện tích
      - Background highlight khi đã chọn
    - **"Đồ dùng"** (Furniture):
      - Icon giường/furniture
      - Click để mở bottom sheet chọn đồ dùng
    - **"Theo vị trí"** (By location):
      - Icon target/compass
      - Click để tìm theo vị trí GPS hiện tại
  
  **Empty State:**
  - Hiển thị khi chưa có kết quả tìm kiếm
  - Icon kính lúp lớn, màu xám nhạt ở giữa màn hình
  - Text hướng dẫn: "Nhập từ khóa hoặc chọn bộ lọc để tìm kiếm"
  - Màu xám, font size vừa
  
  **Kết quả tìm kiếm:**
  - Danh sách các card phòng trọ (tương tự màn hình trang chủ)
  - Hiển thị số lượng kết quả tìm được
  - Scrollable list
  - Pull to refresh

#### 3.2. Bộ lọc chi tiết
- **Mô tả**: Các bottom sheet để lọc phòng trọ theo nhiều tiêu chí
- **Chi tiết**:
  
  **Bottom Sheet chung:**
  - Trượt lên từ dưới màn hình khi click vào filter
  - Background trắng, bo góc ở phần trên
  - Có handle bar (thanh kéo) ở trên cùng
  - Có thể swipe down để đóng
  - Click ra ngoài để đóng
  
  **1. Bottom Sheet "Chọn địa điểm" (Select location):**
  - **Title**: "Chọn địa điểm" (bold, center)
  - **Thành phố (City):**
    - Label "Thành phố"
    - Dropdown/Select field với underline
    - Icon dropdown arrow bên phải
    - Danh sách các thành phố: Hà Nội, TP.HCM, Đà Nẵng, Hải Phòng...
  - **Quận/Huyện (District/County):**
    - Label "Quận/Huyện"
    - Dropdown/Select field phụ thuộc vào thành phố đã chọn
    - Icon dropdown arrow bên phải
    - Hiển thị danh sách quận/huyện của thành phố đã chọn
  - **Action Buttons:**
    - **"Xóa lọc"** (Clear filter): Text button bên trái, màu xám
    - **"Áp dụng"** (Apply): Button màu xanh dương, text trắng, bên phải
  
  **2. Bottom Sheet "Khoảng giá (VND)" (Price range):**
  - **Title**: "Khoảng giá (VND)" (bold, center)
  - **Range Slider:**
    - Slider ngang với 2 handle tròn màu xanh dương
    - Handle trái: Giá tối thiểu (ví dụ: "2 Tr đ" = 2 triệu)
    - Handle phải: Giá tối đa (ví dụ: "15 Tr đ" = 15 triệu)
    - Vùng giữa 2 handle được highlight màu xanh đậm
    - Có thể kéo để thay đổi range
    - Hiển thị giá min và max ở 2 đầu slider
  - **Action Button:**
    - **"Áp dụng"** (Apply): Button màu xanh dương, text trắng, center
  
  **3. Bottom Sheet "Loại phòng" (Room type):**
  - **Title**: "Loại phòng" (bold, center)
  - **Radio Button Options:**
    - **"Phòng"** (Room) - Radio button unchecked
    - **"Căn hộ"** (Apartment) - Radio button unchecked
    - **"Căn hộ Mini"** (Mini Apartment) - Radio button unchecked
    - **"Nguyên căn"** (Entire place) - Radio button unchecked
    - Chỉ có thể chọn 1 option
    - Radio button được chọn: Circle màu xanh dương với dot ở giữa
  - **Action Buttons:**
    - **"Xóa lọc"** (Clear filter): Text button bên trái
    - **"Áp dụng"** (Apply): Button màu xanh dương, text trắng, bên phải
  
  **4. Bottom Sheet "Số người (ở ghép cần thêm)" (Number of people):**
  - **Title**: "Số người (ở ghép cần thêm)" (bold, center)
  - **Slider:**
    - Slider ngang với 1 handle tròn màu xanh dương
    - Handle ở vị trí tối thiểu (bên trái)
    - Hiển thị giá trị: "Từ 1 người trở lên"
    - Có thể kéo để chọn số người tối thiểu
  - **Action Buttons:**
    - **"Xóa lọc"** (Clear filter): Text button bên trái
    - **"Áp dụng"** (Apply): Button màu xanh dương, text trắng, bên phải
  
  **5. Bottom Sheet "Diện tích (m²)" (Area):**
  - **Title**: "Diện tích (m²)" (bold, center)
  - **Range Slider:**
    - Slider ngang với 2 handle tròn màu xanh dương
    - Handle trái: Diện tích tối thiểu (ví dụ: "10 m²")
    - Handle phải: Diện tích tối đa (ví dụ: "40 m²")
    - Vùng giữa 2 handle được highlight màu xanh đậm
    - Có thể kéo để thay đổi range
    - Hiển thị giá trị min và max ở 2 đầu slider
  - **Action Button:**
    - **"Áp dụng"** (Apply): Button màu xanh dương, text trắng, center
  
  **6. Bottom Sheet "Đồ dùng có sẵn" (Available amenities):**
  - **Title**: "Đồ dùng có sẵn" (bold, center)
  - **Grid các options (2 hàng x 4 cột):**
    - **"Giường"** (Bed)
    - **"Tủ quần áo"** (Wardrobe)
    - **"Bàn ghế"** (Table and chairs)
    - **"Bếp"** (Kitchen)
    - **"Máy lạnh"** (Air conditioner)
    - **"Máy giặt"** (Washing machine)
    - **"Tủ lạnh"** (Refrigerator)
    - **"Nệm"** (Mattress)
  - Mỗi option là một button:
    - Không chọn: Background màu xám nhạt, text màu xám đậm
    - Đã chọn: Background màu xanh dương, text màu trắng
  - Có thể chọn nhiều options cùng lúc
  - **Action Buttons:**
    - **"Xóa lọc"** (Clear filter): Text button bên trái
    - **"Áp dụng"** (Apply): Button màu xanh dương, text trắng, bên phải
  
  **7. Bottom Sheet "Tiện ích" (Amenities):**
  - **Title**: "Tiện ích" (bold, center)
  - **Grid các options tương tự "Đồ dùng có sẵn":**
    - Wifi, WC riêng, Giữ xe, Điều hoà, Tủ lạnh, Máy giặt, Bếp riêng, Tự do giờ giấc...
  - Layout và behavior tương tự bottom sheet "Đồ dùng có sẵn"
  - Có thể chọn nhiều options
  - **Action Buttons:**
    - **"Xóa lọc"** (Clear filter): Text button bên trái
    - **"Áp dụng"** (Apply): Button màu xanh dương, text trắng, bên phải
  
  **Tính năng bổ sung:**
  - Lưu bộ lọc đã chọn để áp dụng lại sau
  - Reset tất cả bộ lọc
  - Hiển thị số lượng filter đang active trên các quick filter buttons
  - Kết hợp nhiều filter cùng lúc
  - Real-time update kết quả khi thay đổi filter

---

## 🟡 CẤP ĐỘ TRUNG BÌNH (INTERMEDIATE)

### 4. Xác thực và Bảo mật
#### 4.1. Xác thực người dùng
- **Mô tả**: Hệ thống đăng nhập/đăng ký hoàn chỉnh
- **Chi tiết**:
  - Đăng ký với email/OTP
  - Xác thực OTP qua SMS
  - Đăng nhập với email/phone + password
  - Đăng nhập bằng Google/Facebook
  - JWT token authentication
  - Refresh token
  - Auto-logout khi token hết hạn

#### 4.2. Quản lý phiên đăng nhập
- **Mô tả**: Duy trì trạng thái đăng nhập
- **Chi tiết**:
  - Lưu thông tin đăng nhập (SharedPreferences/Secure Storage)
  - Kiểm tra token khi mở app
  - Tự động đăng nhập lại nếu token còn hợp lệ
  - Xử lý logout

### 5. Quản lý dữ liệu
#### 5.1. Local Storage
- **Mô tả**: Lưu trữ dữ liệu cục bộ
- **Chi tiết**:
  - SharedPreferences: Lưu cài đặt, trạng thái
  - SQLite/Hive: Cache danh sách phòng trọ
  - Lưu tin đã xem gần đây
  - Offline mode cơ bản

#### 5.2. API Integration
- **Mô tả**: Kết nối với backend
- **Chi tiết**:
  - HTTP client (Dio/Http)
  - RESTful API calls
  - Error handling
  - Loading states
  - Retry mechanism

### 6. Tính năng tìm kiếm nâng cao
#### 6.1. Tìm kiếm nâng cao
- **Mô tả**: Bộ lọc phức tạp hơn
- **Chi tiết**:
  - Lọc theo nhiều tiêu chí cùng lúc
  - Lọc theo loại phòng: Chung chủ, Tự do, Ký túc xá
  - Lọc theo tiện ích: Wifi, điều hòa, máy giặt,...
  - Lọc theo khoảng cách (nếu có GPS)
  - Lưu bộ lọc yêu thích
  - Sắp xếp: Giá tăng/giảm, Mới nhất, Gần nhất

#### 6.2. Tìm kiếm theo bản đồ
- **Mô tả**: Tìm phòng trọ trên bản đồ sử dụng OpenStreetMap
- **Chi tiết**:
  - **Tích hợp OpenStreetMap:**
    - Sử dụng thư viện Flutter Map hoặc flutter_map
    - Tile layer từ OpenStreetMap (OSM)
    - Không cần API key, miễn phí
    - Hỗ trợ offline caching với MBTiles
  
  - **Màn hình tìm kiếm bản đồ:**
    - **Header:**
      - Icon mũi tên quay lại (back) ở góc trái
      - Title "Tìm kiếm trên bản đồ" ở giữa
      - Nút "Bộ lọc" ở góc phải (optional)
    
    - **Bản đồ:**
      - Full screen map view
      - Hiển thị các marker phòng trọ trên bản đồ
      - Marker màu xanh dương hoặc màu chủ đạo của app
      - Cluster markers khi zoom out (nhóm các marker gần nhau)
      - Zoom in/out bằng pinch gesture hoặc nút +/- trên bản đồ
      - Pan/drag để di chuyển bản đồ
      - Compass icon để reset về hướng Bắc
    
    - **Nút vị trí hiện tại:**
      - Floating action button ở góc dưới phải
      - Icon location pin
      - Click để di chuyển bản đồ về vị trí GPS hiện tại
      - Yêu cầu quyền location khi click lần đầu
      - Hiển thị marker vị trí hiện tại (màu xanh)
    
    - **Thanh tìm kiếm:**
      - Search bar ở trên cùng bản đồ (overlay)
      - Tìm kiếm địa điểm bằng text
      - Sử dụng Nominatim API (OSM geocoding) để tìm địa chỉ
      - Hiển thị kết quả tìm kiếm dưới search bar
      - Click kết quả để di chuyển bản đồ đến địa điểm đó
    
    - **Vùng tìm kiếm (Radius):**
      - Vẽ circle trên bản đồ để chọn vùng tìm kiếm
      - Có thể điều chỉnh radius bằng slider hoặc gesture
      - Hiển thị số lượng phòng trọ trong vùng
      - Filter các phòng trọ trong vùng đã chọn
    
    - **Marker phòng trọ:**
      - Click marker để hiển thị info window:
        - Thumbnail hình ảnh phòng trọ
        - Giá thuê
        - Địa chỉ
        - Nút "Xem chi tiết"
      - Info window có thể đóng bằng click ra ngoài hoặc nút X
      - Marker có thể có màu khác nhau theo loại phòng (Phòng, Căn hộ, Nguyên căn)
    
    - **Bottom sheet danh sách:**
      - Bottom sheet trượt lên từ dưới khi có kết quả
      - Hiển thị danh sách các phòng trọ trong vùng hiện tại
      - Có thể drag để mở rộng/thu nhỏ
      - Mỗi item có thumbnail, giá, địa chỉ
      - Click item để di chuyển bản đồ đến marker tương ứng
      - Swipe up để xem toàn bộ danh sách
  
  - **Tính năng bổ sung:**
    - **Chỉ đường:**
      - Click vào phòng trọ để mở bottom sheet
      - Nút "Chỉ đường" trong bottom sheet
      - Sử dụng OSRM (Open Source Routing Machine) để tính toán đường đi
      - Hiển thị route trên bản đồ với polyline màu xanh
      - Hiển thị khoảng cách và thời gian ước tính
      - Có thể mở ứng dụng bản đồ khác (Google Maps, Apple Maps) nếu cần
    
    - **Lưu vị trí yêu thích:**
      - Long press trên bản đồ để đánh dấu vị trí
      - Lưu các vị trí đã đánh dấu
      - Hiển thị danh sách vị trí đã lưu
    
    - **Chế độ offline:**
      - Tải bản đồ khu vực để sử dụng offline
      - Cache tiles khi online
      - Hiển thị thông báo khi đang ở chế độ offline
    
    - **Layers:**
      - Chuyển đổi giữa các tile layers:
        - Standard OSM
        - Satellite (nếu có)
        - Terrain
      - Toggle hiển thị traffic (nếu có dữ liệu)
  
  - **Performance:**
    - Lazy loading markers khi zoom
    - Cluster markers để tối ưu hiệu suất
    - Cache tiles để giảm bandwidth
    - Debounce khi search để tránh quá nhiều API calls
  
  - **Chi tiết kỹ thuật tích hợp OpenStreetMap:**
    - **Thư viện Flutter:**
      - `flutter_map`: Package chính để hiển thị bản đồ OSM
      - `latlong2`: Xử lý tọa độ latitude/longitude
      - `geolocator`: Lấy vị trí GPS
      - `geocoding`: Geocoding và reverse geocoding
    
    - **Tile Provider:**
      - Sử dụng OpenStreetMap tile server (tile.openstreetmap.org)
      - Hoặc sử dụng tile server khác như Mapbox (cần API key)
      - Cache tiles để giảm bandwidth và hỗ trợ offline
    
    - **Geocoding (Tìm địa chỉ từ text):**
      - Sử dụng Nominatim API (nominatim.openstreetmap.org)
      - Free, không cần API key
      - Rate limit: 1 request/giây
      - Tìm kiếm địa chỉ, POI (Point of Interest)
      - Trả về tọa độ và thông tin chi tiết
    
    - **Reverse Geocoding (Tìm địa chỉ từ tọa độ):**
      - Sử dụng Nominatim API
      - Chuyển đổi Lat/Lng thành địa chỉ
      - Sử dụng khi drag marker để cập nhật địa chỉ
    
    - **Routing (Chỉ đường):**
      - Sử dụng OSRM (Open Source Routing Machine)
      - Public server: router.project-osrm.org
      - Hoặc tự host OSRM server
      - Tính toán route giữa 2 điểm
      - Trả về polyline để vẽ trên bản đồ
      - Hiển thị khoảng cách và thời gian ước tính
    
    - **Offline Support:**
      - Cache tiles vào local storage
      - Sử dụng MBTiles format để lưu trữ
      - Tải trước bản đồ khu vực quan trọng
      - Hiển thị cached tiles khi không có internet
    
    - **Permissions:**
      - Yêu cầu quyền location (GPS)
      - Yêu cầu quyền internet để tải tiles
      - Yêu cầu quyền storage để cache tiles (optional)
    
    - **Error Handling:**
      - Xử lý khi không có internet
      - Xử lý khi không có quyền location
      - Xử lý khi API rate limit
      - Fallback khi không tìm thấy địa chỉ
      - Retry mechanism cho API calls

### 7. Quản lý tin đăng
#### 7.1. Đăng tin phòng trọ
- **Mô tả**: Chủ trọ đăng tin cho thuê qua form nhiều bước
- **Chi tiết**:
  
  **Header chung cho tất cả các bước:**
  - Icon mũi tên quay lại (back) ở góc trái
  - Tiêu đề "Đăng tin phòng trọ" ở giữa
  - Nút "Lưu nháp" ở góc phải (cho phép lưu tiến trình và quay lại sau)
  
  **Progress Indicator (Stepper):**
  - Hiển thị 4 bước: "Thông tin" → "Địa chỉ" → "Hình ảnh" → "Xác nhận"
  - Bước hiện tại: Circle màu xanh dương với số bước, text màu xanh
  - Bước đã hoàn thành: Circle màu xanh với checkmark hoặc số, text màu xanh, đường nối màu xanh
  - Bước chưa làm: Circle màu xám, text màu xám, đường nối màu xám
  - Đường nối giữa các bước để hiển thị tiến trình
  
  **BƯỚC 1: THÔNG TIN**
  - **Loại tin (Listing type):**
    - Segmented control với 2 lựa chọn:
      - "Cho thuê" (For rent) - mặc định được chọn
      - "Tìm ở ghép" (Looking for a roommate)
    - Option được chọn: Background màu xanh dương, icon checkmark, text màu trắng
    - Option không chọn: Background trắng, border nhẹ
  
  - **Loại phòng (Room type):**
    - Row các nút chọn:
      - "Phòng" (Room) - mặc định được chọn
      - "Căn hộ" (Apartment)
      - "Căn hộ mini" (Mini apartment)
      - "Nguyên căn" (Entire place)
    - Nút được chọn: Background màu xanh dương, text màu trắng
    - Nút không chọn: Background trắng, border, text màu đen
  
  - **Giá phòng (VND):**
    - Input field số: Nhập giá bằng VND
    - Format hiển thị: Tự động format số (ví dụ: "2.000.000")
    - Helper text bên dưới: Hiển thị giá dạng text dễ đọc (ví dụ: "2 triệu")
    - Validation: Chỉ cho phép nhập số, giá tối thiểu
  
  - **Diện tích (m²):**
    - Input field số: Nhập diện tích bằng mét vuông
    - Label: "Diện tích (m²)"
    - Validation: Chỉ cho phép nhập số, diện tích tối thiểu
  
  - **Tiện ích (Amenities):**
    - Section title: "Tiện ích"
    - Grid các nút chọn tiện ích:
      - **Các tiện ích có sẵn:**
        - "Wifi"
        - "WC riêng" (Private toilet)
        - "Giữ xe" (Parking)
        - "Tự do giờ giấc" (Flexible hours)
        - "Bếp riêng" (Private kitchen)
        - "Điều hoà" (Air conditioner)
        - "Tủ lạnh" (Refrigerator)
        - "Máy giặt" (Washing machine)
      - Có thể chọn nhiều tiện ích cùng lúc
      - Tiện ích được chọn: Background màu xanh dương, icon checkmark, text màu trắng
      - Tiện ích không chọn: Background trắng, border, text màu đen
    - Layout: Grid 2-3 cột, responsive
  
  - **Nút điều hướng:**
    - Nút "Huỷ" (Cancel) ở góc trái dưới
    - Nút "Tiếp theo" (Next) màu xanh nhạt ở góc phải dưới
  
  **BƯỚC 2: ĐỊA CHỈ**
  - **Thành phố (City):**
    - Dropdown/Select field
    - Hiển thị danh sách các thành phố (ví dụ: Hà Nội, TP.HCM, Đà Nẵng...)
    - Có icon dropdown arrow bên phải
    - Khi chọn thành phố, tự động load danh sách quận/huyện
  
  - **Quận/Huyện (District/County):**
    - Dropdown/Select field phụ thuộc vào thành phố đã chọn
    - Hiển thị danh sách quận/huyện của thành phố đã chọn
    - Ví dụ: Cầu Giấy, Thanh Xuân, Đống Đa, Hai Bà Trưng...
    - Có icon dropdown arrow
  
  - **Phường/Xã (Ward/Commune):**
    - Dropdown/Select field phụ thuộc vào quận/huyện đã chọn
    - Hiển thị danh sách phường/xã của quận/huyện đã chọn
    - Có icon dropdown arrow
  
  - **Tên đường (Street Name):**
    - Text input field
    - Nhập tên đường (ví dụ: "Đường Vành Đai 1")
    - Underline style
  
  - **Số nhà (House Number):**
    - Text input field
    - Nhập số nhà
    - Underline style
  
  - **Mô tả đường đi (tùy chọn) (Directions description - optional):**
    - Text input field (multiline)
    - Cho phép nhập mô tả chi tiết đường đi
    - Label có ghi chú "(tùy chọn)"
    - Underline style
  
  - **Lấy vị trí hiện tại:**
    - Nút "Lấy vị trí hiện tại" (Get current location)
    - Icon compass/target bên trái
    - Background màu xám nhạt, bo góc
    - Khi click: Yêu cầu quyền location, lấy GPS coordinates
    - Hiển thị tọa độ: "Lat: [latitude], Lng: [longitude]" (ví dụ: "Lat: 21.0281, Lng: 105,...")
  
  - **Bản đồ (Map Preview):**
    - Tích hợp OpenStreetMap sử dụng flutter_map
    - Embedded map view hiển thị vị trí đã chọn
    - Marker màu đỏ (teardrop shape) đánh dấu vị trí
    - Hiển thị tên đường, phường, quận trên bản đồ từ OSM data
    - Có thể drag marker để thay đổi vị trí
      - Khi drag marker: Cập nhật tọa độ GPS real-time
      - Reverse geocoding để lấy địa chỉ mới từ tọa độ
      - Cập nhật các field địa chỉ tự động
    - Zoom in/out để xem chi tiết (pinch gesture hoặc nút +/-)
    - Pan/drag để di chuyển bản đồ
    - Nút "Lấy vị trí hiện tại" để di chuyển marker về GPS location
    - Hiển thị tọa độ Lat/Lng dưới bản đồ
  
  - **Nút điều hướng:**
    - Nút "Quay lại" (Back) ở góc trái dưới
    - Nút "Tiếp theo" (Next) màu xanh nhạt ở góc phải dưới
  
  **BƯỚC 3: HÌNH ẢNH**
  - **Upload hình ảnh:**
    - Box upload lớn với icon camera và dấu "+" ở giữa
    - Background trắng, bo góc, border nhẹ
    - Click để mở gallery hoặc camera
    - Cho phép chọn nhiều ảnh cùng lúc
  
  - **Giới hạn:**
    - Text hiển thị: "Tối đa 15 hình, hiện có [số]"
    - Tối đa 15 hình ảnh
    - Cập nhật số lượng real-time khi thêm/xóa ảnh
  
  - **Thumbnail gallery:**
    - Hiển thị grid các thumbnail ảnh đã upload
    - Mỗi thumbnail có nút xóa (X) ở góc trên phải
    - Có thể drag để sắp xếp lại thứ tự
    - Ảnh đầu tiên sẽ là ảnh đại diện
    - Click thumbnail để xem full size hoặc chỉnh sửa
  
  - **Validation:**
    - Yêu cầu tối thiểu 1 ảnh
    - Kiểm tra kích thước file (ví dụ: max 5MB/ảnh)
    - Kiểm tra định dạng (jpg, png)
  
  - **Nút điều hướng:**
    - Nút "Quay lại" (Back) ở góc trái dưới
    - Nút "Tiếp theo" (Next) màu xanh nhạt ở góc phải dưới
  
  **BƯỚC 4: XÁC NHẬN**
  - **Tiêu đề bài đăng:**
    - Text input field
    - Label: "Tiêu đề bài đăng"
    - Underline style
    - Validation: Bắt buộc, tối thiểu 10 ký tự
  
  - **Mô tả chi tiết:**
    - Text input field (multiline)
    - Label: "Mô tả chi tiết"
    - Underline style
    - Cho phép nhập nhiều dòng
    - Validation: Bắt buộc, tối thiểu 50 ký tự
  
  - **Tên liên hệ:**
    - Text input field
    - Label: "Tên liên hệ"
    - Underline style
    - Validation: Bắt buộc
  
  - **Số điện thoại liên hệ:**
    - Text input field (số)
    - Label: "Số điện thoại liên hệ"
    - Underline style
    - Validation: Bắt buộc, format số điện thoại Việt Nam (10 số)
  
  - **Đồ dùng có sẵn (Available amenities):**
    - Section title: "Đồ dùng có sẵn" (bold)
    - Grid các nút chọn (2 hàng x 4 cột):
      - **Hàng 1:** "Giường" (Bed), "Tủ quần áo" (Wardrobe), "Bàn ghế" (Table and chairs), "Bếp" (Kitchen)
      - **Hàng 2:** "Máy lạnh" (Air conditioner), "Máy giặt" (Washing machine), "Tủ lạnh" (Refrigerator), "Nệm" (Mattress)
    - Nút được chọn: Background màu xanh, text màu trắng
    - Nút không chọn: Background trắng, border xám nhạt
    - Có thể chọn nhiều đồ dùng
  
  - **Tóm tắt (Summary):**
    - Card hiển thị tóm tắt thông tin đã nhập
    - Background màu xám nhạt, bo góc nhẹ
    - Title: "Tóm tắt" (bold)
    - Hiển thị:
      - "Loại tin": [Giá trị đã chọn] (ví dụ: "Cho thuê")
      - "Loại phòng": [Giá trị đã chọn] (ví dụ: "Phòng")
      - "Giá": [Giá đã nhập] VND (ví dụ: "2000000 VND")
    - Có thể mở rộng để xem thêm chi tiết
  
  - **Nút điều hướng:**
    - Nút "Quay lại" (Back) ở góc trái dưới
    - Nút "Đăng tin" (Post) màu xanh dương, text trắng, bo góc ở góc phải dưới
    - Khi click "Đăng tin": Validate tất cả fields, hiển thị loading, gửi lên server
  
  **Tính năng bổ sung:**
  - **Lưu nháp:**
    - Lưu tiến trình hiện tại vào local storage
    - Có thể quay lại tiếp tục chỉnh sửa sau
    - Hiển thị danh sách các bản nháp đã lưu
    - Tự động lưu nháp khi chuyển bước
  
  - **Validation:**
    - Validate từng bước trước khi chuyển bước tiếp theo
    - Hiển thị error message rõ ràng
    - Highlight field có lỗi
  
  - **Preview:**
    - Có thể xem trước tin đăng trước khi đăng
    - Hiển thị đầy đủ thông tin như người dùng sẽ thấy
  
  - **Upload progress:**
    - Hiển thị progress bar khi upload ảnh
    - Hiển thị progress khi gửi tin đăng lên server
  
  - **Success/Error handling:**
    - Thông báo thành công khi đăng tin thành công
    - Thông báo lỗi nếu có vấn đề
    - Redirect về màn hình quản lý tin đã đăng sau khi đăng thành công

#### 7.2. Quản lý tin đã đăng
- **Mô tả**: Xem và quản lý tin đã đăng
- **Chi tiết**:
  - Danh sách tin đã đăng
  - Trạng thái: Đang hiển thị, Đã cho thuê, Đã ẩn
  - Chỉnh sửa tin đăng
  - Xóa tin đăng
  - Gia hạn tin đăng
  - Thống kê: Số lượt xem, số lượt liên hệ

### 8. Tương tác người dùng
#### 8.1. Yêu thích (Favorites)
- **Mô tả**: Màn hình hiển thị danh sách các phòng trọ đã được đánh dấu yêu thích
- **Chi tiết**:
  
  **Header:**
  - **Title**: "Yêu thích" (font size lớn, bold, màu xám đậm)
  - **Subtitle**: "[Số] phòng đã lưu" (ví dụ: "1 phòng đã lưu")
    - Font size nhỏ hơn, màu xám nhạt
    - Cập nhật số lượng real-time khi thêm/xóa yêu thích
  
  **Danh sách phòng yêu thích:**
  - **Card phòng trọ:**
    - Background trắng, bo góc nhẹ, shadow nhẹ
    - Layout horizontal: Hình ảnh bên trái, thông tin bên phải
    - **Hình ảnh thumbnail (bên trái):**
      - Chiếm khoảng 1/3 chiều rộng card
      - Aspect ratio ~4:3 hoặc 16:9
      - Bo góc nhẹ
      - **Overlay giá** ở góc dưới trái hình ảnh:
        - Background màu xanh dương với độ trong suốt (~80% opacity)
        - Text màu trắng, bold: "[Giá] triệu /tháng" (ví dụ: "4,6 triệu /tháng")
        - Font size: 12-14px
        - Padding: 6-8px
    - **Thông tin phòng (bên phải):**
      - **Địa chỉ:**
        - Text địa chỉ (màu đen/xám đậm)
        - Truncate nếu quá dài, thêm "..." (ví dụ: "Nhân Hòa, Nhân Chính, Than...")
        - Font size: 14-16px
      - **Diện tích:**
        - Icon sơ đồ/phòng (màu xám)
        - Text: "[Diện tích] m²" (ví dụ: "30 m²")
        - Font size: 12-14px, màu xám
      - **Quận/Huyện:**
        - Icon tòa nhà (màu xám)
        - Text: "[Tên quận/huyện]" (ví dụ: "Thanh Xuân")
        - Font size: 12-14px, màu xám
      - Layout: Column với spacing phù hợp
      - Padding: 12-16px
    - **Icon mũi tên phải** ở góc phải card:
      - Icon mũi tên trỏ phải (màu xám)
      - Indicate có thể click để xem chi tiết
  
  - **Empty State:**
    - Hiển thị khi chưa có phòng nào được yêu thích
    - Icon trái tim lớn, màu xám nhạt ở giữa màn hình
    - Text: "Chưa có phòng yêu thích nào"
    - Text hướng dẫn: "Bấm vào icon trái tim trên các phòng trọ để lưu yêu thích"
  
  - **Layout danh sách:**
    - Vertical list (ListView/Column)
    - Spacing giữa các card: 12-16px
    - Padding horizontal: 16px
    - Scrollable, smooth scrolling
    - Pull to refresh để làm mới danh sách
  
  **Tương tác:**
  - **Click vào card:**
    - Navigate đến màn hình chi tiết phòng trọ
    - Pass ID của phòng trọ để load chi tiết
  
  - **Thêm yêu thích:**
    - Từ màn hình chi tiết phòng trọ: Click icon trái tim ở header
    - Từ màn hình danh sách: Click icon trái tim trên card phòng trọ
    - Icon trái tim chuyển từ outline sang filled màu đỏ
    - Hiển thị snackbar/toast: "Đã thêm vào yêu thích"
    - Tự động đồng bộ với server
  
  - **Xóa yêu thích:**
    - **Cách 1**: Từ màn hình chi tiết: Click lại icon trái tim (đã filled) để bỏ yêu thích
    - **Cách 2**: Từ màn hình yêu thích:
      - **Swipe to delete**: Vuốt card sang trái để hiện nút "Xóa"
      - **Long press menu**: Nhấn giữ card để hiện menu với option "Xóa khỏi yêu thích"
      - **Icon xóa trên card**: Có thể có icon X nhỏ ở góc trên phải card (optional)
    - Hiển thị dialog xác nhận: "Bạn có chắc muốn xóa phòng này khỏi yêu thích?"
    - Sau khi xác nhận: Xóa khỏi danh sách, cập nhật số lượng, đồng bộ với server
    - Hiển thị snackbar/toast: "Đã xóa khỏi yêu thích"
  
  - **Xóa tất cả:**
    - Menu option ở header (icon 3 chấm hoặc menu)
    - Option "Xóa tất cả yêu thích"
    - Hiển thị dialog xác nhận
    - Xóa toàn bộ danh sách sau khi xác nhận
  
  **Đồng bộ dữ liệu:**
  - Tự động đồng bộ với server khi thêm/xóa yêu thích
  - Lưu cache local để hiển thị offline
  - Sync khi có internet lại
  - Conflict resolution nếu có thay đổi từ nhiều thiết bị
  
  **Thông báo:**
  - Push notification khi phòng yêu thích có thay đổi giá
  - Push notification khi phòng yêu thích được cập nhật
  - Badge số trên tab "Yêu thích" nếu có thông báo mới
  
  **Tính năng bổ sung:**
  - Sắp xếp: Mới nhất, Giá tăng/giảm, Diện tích
  - Lọc: Theo khu vực, theo giá, theo loại phòng
  - Share danh sách yêu thích (optional)
  - Export danh sách (optional)

#### 8.2. Lịch sử xem
- **Mô tả**: Lưu các phòng đã xem
- **Chi tiết**:
  - Tự động lưu khi xem chi tiết
  - Danh sách lịch sử xem
  - Xóa từng item hoặc xóa tất cả
  - Giới hạn số lượng (50-100 tin)

#### 8.3. Đánh giá và Bình luận
- **Mô tả**: Người dùng đánh giá phòng trọ
- **Chi tiết**:
  - Rating 1-5 sao
  - Viết bình luận
  - Xem bình luận của người khác
  - Phản hồi bình luận
  - Báo cáo bình luận spam

### 9. Thông báo
#### 9.1. Thông báo trong app
- **Mô tả**: Hệ thống thông báo
- **Chi tiết**:
  - Danh sách thông báo
  - Các loại: Tin mới phù hợp, Phòng yêu thích giảm giá, Tin nhắn mới
  - Đánh dấu đã đọc/chưa đọc
  - Xóa thông báo
  - Badge số thông báo chưa đọc

#### 9.2. Push Notification
- **Mô tả**: Thông báo đẩy
- **Chi tiết**:
  - Tích hợp Firebase Cloud Messaging
  - Đăng ký token
  - Nhận thông báo khi app đang chạy
  - Nhận thông báo khi app ở background
  - Xử lý click vào thông báo

### 10. Chat/Messaging
#### 10.1. Nhắn tin với chủ trọ
- **Mô tả**: Chat trực tiếp (real-time) giữa khách tìm phòng và người đăng tin
- **Chi tiết**:
  - **Danh sách cuộc trò chuyện:**
    - Danh sách tất cả hội thoại của người dùng
    - Card hội thoại gồm avatar người đăng (hoặc ảnh phòng), tên phòng/người đăng, đoạn tin nhắn cuối, thời gian, badge chưa đọc
    - Swipe để ghim, mute hoặc xóa hội thoại
    - Search bar tìm theo tên người đăng hoặc tiêu đề phòng
    - Filter: Tất cả, Chưa đọc, Đã ghim
    - Pull to refresh
  
  - **Màn hình chat box:**
    - Header: Avatar + tên người đăng, trạng thái online/offline, icon gọi điện, icon xem phòng trọ
    - Tin nhắn dạng bubble (trái/phải) với timestamp, trạng thái gửi/đã đọc
    - Typing indicator (“Chủ trọ đang nhập…”)
    - Auto-scroll xuống cuối khi có tin mới
    - Input bar: Text field multiline, icon emoji, icon đính kèm (ảnh/file), icon chụp ảnh, nút gửi
    - Hỗ trợ dark mode
  
  - **Loại tin nhắn hỗ trợ:**
    - Text (có emoji, xuống dòng)
    - **Ảnh**:
      - Chọn nhiều ảnh cùng lúc từ gallery hoặc chụp trực tiếp bằng camera
      - Preview trước khi gửi, cho phép thêm chú thích/ghi chú
      - Tự động nén kích thước (giới hạn ví dụ ≤10MB/ảnh) nhưng đảm bảo chất lượng rõ
      - Hiển thị dạng thumbnail trong chat, click để mở full screen, pinch-to-zoom, swipe giữa các ảnh
      - Cho phép tải ảnh về, chia sẻ sang app khác hoặc chuyển tiếp tới cuộc chat khác
      - Hiển thị tiến trình upload (progress bar), trạng thái gửi; hỗ trợ retry khi upload lỗi
      - Kiểm tra định dạng (jpg, png, heic/webp) và cảnh báo khi vượt dung lượng
    - File (pdf/doc – optional)
    - Tin nhắn định vị (gửi link map của phòng trọ)
    - Quick replies (tin nhắn mẫu)
    - Voice note (optional)
  
  - **Thông tin phòng trọ trong chat:**
    - Banner cố định đầu màn hình: Ảnh thumbnail, tiêu đề, giá, địa chỉ rút gọn
    - Nút “Xem chi tiết”, “Gọi ngay”, “Đặt lịch xem”
    - Badge hiển thị trạng thái tin (còn phòng/hết phòng)
  
  - **Quản lý hội thoại:**
    - Pin/unpin, Đánh dấu đã đọc/chưa đọc
    - Mute/unmute thông báo
    - Xóa hội thoại (soft delete – chỉ ẩn phía client)
    - Báo cáo hội thoại (spam, lừa đảo, quấy rối)
    - Block người dùng (không nhận tin nhắn mới)
    - Export lịch sử chat (PDF) – optional
  
  - **Thông báo:**
    - Push notification khi có tin mới (hiển thị avatar + preview)
    - In-app badge ở tab “Thông báo” và icon chat
    - Notification trong admin console cho chủ trọ (web)
  
  - **Real-time messaging & đồng bộ:**
    - Sử dụng WebSocket/Firebase/Firestore
    - Nhắn tin offline: Lưu tạm local, sync khi online
    - Trạng thái gửi: Sending → Sent → Delivered → Read
    - Retry khi mất kết nối, exponential backoff
    - Đồng bộ đa thiết bị (mobile + web)
  
  - **Bảo mật & kiểm duyệt:**
    - Truyền dữ liệu qua HTTPS/WSS
    - Mã hóa end-to-end (optional)
    - Lọc nội dung nhạy cảm (keyword filter)
    - Lưu log chat để xử lý tranh chấp
    - Cho phép người dùng yêu cầu xóa dữ liệu chat
  
  - **Hỗ trợ từ admin:**
    - Admin/support có thể join chat (3-way chat) khi cần hỗ trợ
    - Tag cuộc trò chuyện quan trọng (VIP)
    - Chat template cho chủ trọ (ví dụ: “Phòng còn trống, bạn có muốn xem vào 17h hôm nay không?”)
  
  - **Tính năng nâng cao (optional):**
    - Chatbot tự động trả lời khi chủ trọ offline
    - Lên lịch gửi tin nhắn (schedule)
    - Gửi vị trí hiện tại của người tìm phòng
    - Tạo group chat (nhiều người thuê cùng trao đổi)
    - AI gợi ý câu trả lời dựa trên ngữ cảnh cuộc chat

### 11. Hệ thống Admin (Web/App)
#### 11.1. Đăng nhập Admin
- **Mô tả**: Xác thực quyền truy cập admin
- **Chi tiết**:
  - **Màn hình đăng nhập:**
    - Form đăng nhập với email/username và password
    - Validation đầy đủ
    - Checkbox "Ghi nhớ đăng nhập"
    - Nút "Quên mật khẩu"
    - Hiển thị lỗi rõ ràng khi đăng nhập sai
  
  - **Phân quyền:**
    - Super Admin: Toàn quyền hệ thống
    - Admin: Quản lý nội dung, duyệt tin
    - Moderator: Duyệt tin, quản lý báo cáo
    - Support: Xem thống kê, hỗ trợ người dùng
  
  - **Bảo mật:**
    - JWT token authentication
    - Session timeout
    - IP whitelist (optional)
    - 2FA (Two-Factor Authentication) cho Super Admin
    - Log mọi hoạt động đăng nhập

#### 11.2. Dashboard Admin
- **Mô tả**: Màn hình tổng quan với thống kê hệ thống
- **Chi tiết**:
  - **Header:**
    - Logo ứng dụng
    - Thông tin admin đang đăng nhập (avatar, tên)
    - Nút thông báo (badge số thông báo)
    - Nút đăng xuất
  
  - **Sidebar Navigation:**
    - Menu điều hướng các chức năng admin
    - Icon + text cho mỗi menu item
    - Highlight menu item đang active
    - Collapse/expand sidebar
    - Các menu chính:
      - Dashboard (Home)
      - Quản lý tin đăng
      - Quản lý người dùng
      - Quản lý báo cáo
      - Thống kê & Báo cáo
      - Cài đặt hệ thống
      - Nhật ký hoạt động
  
  - **Thống kê tổng quan (Cards):**
    - **Tổng số người dùng:**
      - Số lượng tổng
      - Tăng trưởng so với tháng trước (%)
      - Icon người dùng
      - Click để xem chi tiết
    
    - **Tổng số tin đăng:**
      - Số lượng tổng
      - Tăng trưởng so với tháng trước (%)
      - Icon tài liệu
      - Click để xem danh sách
    
    - **Tin đang chờ duyệt:**
      - Số lượng tin chưa duyệt
      - Badge màu đỏ nếu có tin mới
      - Icon đồng hồ
      - Click để xem danh sách chờ duyệt
    
    - **Tổng lượt xem:**
      - Số lượt xem tổng
      - Tăng trưởng so với tháng trước (%)
      - Icon mắt
      - Click để xem chi tiết
    
    - **Tổng lượt liên hệ:**
      - Số lượt liên hệ tổng
      - Tăng trưởng so với tháng trước (%)
      - Icon điện thoại
      - Click để xem chi tiết
    
    - **Báo cáo chưa xử lý:**
      - Số lượng báo cáo mới
      - Badge màu đỏ nếu có báo cáo mới
      - Icon cờ
      - Click để xem danh sách báo cáo
  
  - **Biểu đồ thống kê:**
    - **Biểu đồ người dùng đăng ký:**
      - Line chart hoặc bar chart
      - Thống kê theo ngày/tuần/tháng
      - Có thể chọn khoảng thời gian
      - So sánh với kỳ trước
    
    - **Biểu đồ tin đăng:**
      - Line chart hoặc bar chart
      - Thống kê tin đăng theo thời gian
      - Phân loại theo trạng thái (Đã duyệt, Chờ duyệt, Đã ẩn)
    
    - **Biểu đồ lượt xem:**
      - Line chart
      - Thống kê lượt xem theo thời gian
      - Peak hours analysis
    
    - **Biểu đồ phân bố địa lý:**
      - Map visualization
      - Hiển thị số lượng tin đăng theo khu vực
      - Heat map hoặc markers
  
  - **Danh sách hoạt động gần đây:**
    - Timeline các hoạt động mới nhất
    - Tin đăng mới, Người dùng mới, Báo cáo mới
    - Hiển thị thời gian relative (5 phút trước, 1 giờ trước...)
    - Click để xem chi tiết

#### 11.3. Quản lý tin đăng
- **Mô tả**: Quản lý và duyệt các tin đăng phòng trọ
- **Chi tiết**:
  - **Danh sách tin đăng:**
    - **Bộ lọc:**
      - Lọc theo trạng thái: Tất cả, Chờ duyệt, Đã duyệt, Đã từ chối, Đã ẩn
      - Lọc theo loại tin: Cho thuê, Tìm ở ghép
      - Lọc theo khu vực: Thành phố, Quận/Huyện
      - Lọc theo thời gian: Hôm nay, Tuần này, Tháng này, Tùy chọn
      - Lọc theo người đăng: Tìm kiếm theo tên/email
      - Nút "Đặt lại" để xóa tất cả bộ lọc
    
    - **Bảng danh sách:**
      - Columns:
        - Checkbox (để chọn nhiều)
        - Hình ảnh thumbnail
        - Tiêu đề/Tên người đăng
        - Địa chỉ
        - Giá thuê
        - Loại phòng
        - Trạng thái (badge màu)
        - Lượt xem
        - Lượt liên hệ
        - Ngày đăng
        - Actions (Xem, Duyệt, Từ chối, Xóa)
      - Sortable columns (click header để sắp xếp)
      - Pagination (phân trang)
      - Hiển thị số lượng trên mỗi trang (10, 25, 50, 100)
      - Search bar để tìm kiếm nhanh
    
    - **Bulk actions:**
      - Chọn nhiều tin bằng checkbox
      - Actions: Duyệt hàng loạt, Từ chối hàng loạt, Xóa hàng loạt, Ẩn/Hiện hàng loạt
      - Hiển thị số lượng đã chọn
  
  - **Chi tiết tin đăng:**
    - **Thông tin cơ bản:**
      - Carousel hình ảnh
      - Tiêu đề, Mô tả
      - Giá, Diện tích, Địa chỉ
      - Loại phòng, Tiện ích, Đồ dùng
      - Thông tin người đăng (tên, email, số điện thoại)
      - Thời gian đăng, Cập nhật lần cuối
    
    - **Thống kê:**
      - Số lượt xem
      - Số lượt liên hệ
      - Số lượt yêu thích
      - Lịch sử thay đổi trạng thái
    
    - **Actions:**
      - **Duyệt tin**: Chuyển trạng thái sang "Đã duyệt", hiển thị trên app
      - **Từ chối**: Chuyển trạng thái sang "Đã từ chối", gửi thông báo cho người đăng với lý do
      - **Ẩn tin**: Ẩn tin khỏi danh sách công khai
      - **Xóa tin**: Xóa vĩnh viễn, có dialog xác nhận
      - **Chỉnh sửa**: Sửa thông tin tin đăng (admin có thể chỉnh sửa)
      - **Gia hạn**: Gia hạn thời gian hiển thị tin
      - **Ghim tin**: Đưa tin lên đầu danh sách (featured)
      - **Gửi thông báo**: Gửi thông báo cho người đăng
  
  - **Lý do từ chối:**
    - Dropdown các lý do phổ biến:
      - Thông tin không chính xác
      - Hình ảnh không phù hợp
      - Nội dung spam/quảng cáo
      - Vi phạm quy định
      - Khác (có thể nhập lý do tùy chỉnh)
    - Textarea để nhập lý do chi tiết (optional)
    - Gửi email thông báo cho người đăng với lý do từ chối

#### 11.4. Quản lý người dùng
- **Mô tả**: Quản lý tài khoản người dùng trong hệ thống
- **Chi tiết**:
  - **Danh sách người dùng:**
    - **Bộ lọc:**
      - Lọc theo vai trò: Tất cả, Người thuê, Chủ trọ
      - Lọc theo trạng thái: Tất cả, Hoạt động, Đã khóa, Chưa xác thực
      - Lọc theo thời gian đăng ký
      - Tìm kiếm theo tên, email, số điện thoại
    
    - **Bảng danh sách:**
      - Columns:
        - Avatar
        - Tên người dùng
        - Email
        - Số điện thoại
        - Vai trò
        - Số tin đã đăng
        - Trạng thái (badge màu)
        - Ngày đăng ký
        - Actions (Xem, Khóa/Mở khóa, Xóa)
      - Sortable columns
      - Pagination
  
  - **Chi tiết người dùng:**
    - **Thông tin cá nhân:**
      - Avatar, Tên, Email, Số điện thoại
      - Thành phố, Quận/Huyện
      - Ngày đăng ký, Lần đăng nhập cuối
      - Trạng thái tài khoản
    
    - **Thống kê:**
      - Số tin đã đăng (phân loại theo trạng thái)
      - Số lượt xem tổng
      - Số lượt liên hệ nhận được
      - Số phòng đã yêu thích
      - Số báo cáo đã nhận
    
    - **Danh sách tin đăng:**
      - Hiển thị tất cả tin đăng của người dùng này
      - Có thể click để xem chi tiết từng tin
    
    - **Lịch sử hoạt động:**
      - Timeline các hoạt động: Đăng tin, Chỉnh sửa tin, Xóa tin, Đăng nhập...
      - Hiển thị thời gian và IP address
    
    - **Actions:**
      - **Khóa tài khoản**: Khóa tài khoản, người dùng không thể đăng nhập
        - Nhập lý do khóa
        - Thời gian khóa (vĩnh viễn hoặc có thời hạn)
        - Gửi email thông báo
      - **Mở khóa tài khoản**: Khôi phục quyền truy cập
      - **Xóa tài khoản**: Xóa vĩnh viễn, có dialog xác nhận
      - **Reset mật khẩu**: Gửi link reset mật khẩu qua email
      - **Gửi thông báo**: Gửi thông báo trực tiếp cho người dùng
      - **Xác thực email**: Đánh dấu email đã xác thực thủ công

#### 11.5. Quản lý báo cáo
- **Mô tả**: Xử lý các báo cáo từ người dùng
- **Chi tiết**:
  - **Danh sách báo cáo:**
    - **Bộ lọc:**
      - Lọc theo trạng thái: Tất cả, Chờ xử lý, Đang xử lý, Đã xử lý, Đã từ chối
      - Lọc theo loại: Tin đăng spam, Tin đăng sai thông tin, Người dùng spam, Nội dung không phù hợp
      - Lọc theo thời gian báo cáo
      - Tìm kiếm theo ID tin đăng, ID người báo cáo
    
    - **Bảng danh sách:**
      - Columns:
        - ID báo cáo
        - Loại báo cáo (badge màu)
        - Đối tượng bị báo cáo (Tin đăng/Người dùng)
        - Người báo cáo
        - Lý do báo cáo
        - Trạng thái
        - Ngày báo cáo
        - Actions (Xem, Xử lý, Từ chối)
      - Sortable columns
      - Pagination
  
  - **Chi tiết báo cáo:**
    - **Thông tin báo cáo:**
      - Loại báo cáo
      - Lý do chi tiết
      - Mô tả từ người báo cáo
      - Hình ảnh đính kèm (nếu có)
      - Người báo cáo (thông tin)
      - Thời gian báo cáo
    
    - **Đối tượng bị báo cáo:**
      - Nếu là tin đăng: Hiển thị card tin đăng với đầy đủ thông tin
      - Nếu là người dùng: Hiển thị thông tin người dùng
      - Có thể click để xem chi tiết đối tượng
    
    - **Lịch sử xử lý:**
      - Timeline các hành động đã thực hiện với báo cáo này
      - Admin đã xử lý, Thời gian, Hành động
    
    - **Actions:**
      - **Chấp nhận báo cáo:**
        - Ẩn tin đăng hoặc khóa tài khoản
        - Gửi cảnh báo cho người vi phạm
        - Gửi thông báo cho người báo cáo
        - Chuyển trạng thái sang "Đã xử lý"
      - **Từ chối báo cáo:**
        - Đánh dấu báo cáo không hợp lệ
        - Gửi thông báo cho người báo cáo
        - Chuyển trạng thái sang "Đã từ chối"
      - **Yêu cầu thêm thông tin:**
        - Gửi email cho người báo cáo yêu cầu cung cấp thêm thông tin
        - Chuyển trạng thái sang "Đang xử lý"
  
  - **Thống kê báo cáo:**
    - Tổng số báo cáo theo loại
    - Tỷ lệ báo cáo được chấp nhận/từ chối
    - Top người dùng bị báo cáo nhiều nhất
    - Top loại báo cáo phổ biến

#### 11.6. Thống kê & Báo cáo
- **Mô tả**: Xem các báo cáo thống kê chi tiết về hệ thống
- **Chi tiết**:
  - **Thống kê người dùng:**
    - Tổng số người dùng theo thời gian
    - Phân bố theo vai trò (Người thuê/Chủ trọ)
    - Phân bố theo khu vực địa lý
    - Tỷ lệ người dùng hoạt động/thụ động
    - Biểu đồ đăng ký mới theo thời gian
    - Retention rate (tỷ lệ người dùng quay lại)
  
  - **Thống kê tin đăng:**
    - Tổng số tin đăng theo thời gian
    - Phân bố theo trạng thái (Đã duyệt, Chờ duyệt, Đã từ chối)
    - Phân bố theo loại tin (Cho thuê/Tìm ở ghép)
    - Phân bố theo loại phòng
    - Phân bố theo khu vực
    - Phân bố theo giá thuê (khoảng giá)
    - Thời gian trung bình để duyệt tin
    - Tỷ lệ tin được duyệt/từ chối
  
  - **Thống kê tương tác:**
    - Tổng lượt xem theo thời gian
    - Tổng lượt liên hệ
    - Tổng lượt yêu thích
    - Tỷ lệ chuyển đổi (view → contact)
    - Tin đăng được xem nhiều nhất
    - Tin đăng được liên hệ nhiều nhất
  
  - **Thống kê doanh thu (nếu có thanh toán):**
    - Tổng doanh thu theo thời gian
    - Doanh thu từ phí đăng tin
    - Doanh thu từ phí nâng cấp tin
    - Phân bố theo phương thức thanh toán
    - Biểu đồ doanh thu theo tháng/quý
  
  - **Export báo cáo:**
    - Export Excel/CSV
    - Export PDF
    - Chọn khoảng thời gian
    - Chọn loại thống kê
    - Tự động gửi email báo cáo định kỳ (hàng ngày/tuần/tháng)

#### 11.7. Cài đặt hệ thống
- **Mô tả**: Cấu hình các thông số hệ thống
- **Chi tiết**:
  - **Cài đặt chung:**
    - Tên ứng dụng
    - Logo ứng dụng
    - Favicon
    - Email liên hệ
    - Số điện thoại hỗ trợ
    - Địa chỉ văn phòng
    - Link website, Facebook, Zalo
  
  - **Cài đặt tin đăng:**
    - Số lượng hình ảnh tối đa cho mỗi tin
    - Thời gian hiển thị tin mặc định (số ngày)
    - Phí đăng tin (nếu có)
    - Phí nâng cấp tin (nếu có)
    - Tự động duyệt tin (on/off)
    - Thời gian tự động ẩn tin cũ
  
  - **Cài đặt người dùng:**
    - Yêu cầu xác thực email khi đăng ký
    - Yêu cầu xác thực số điện thoại
    - Cho phép đăng ký bằng Google/Facebook
    - Giới hạn số tin đăng cho mỗi người dùng
  
  - **Cài đặt báo cáo:**
    - Số lượng báo cáo cần thiết để tự động ẩn tin
    - Thời gian xử lý báo cáo mặc định
    - Gửi email thông báo khi có báo cáo mới
  
  - **Cài đặt thông báo:**
    - Bật/tắt push notification
    - Template email thông báo
    - Template SMS (nếu có)
  
  - **Cài đặt bảo mật:**
    - Yêu cầu mật khẩu mạnh
    - Số lần đăng nhập sai tối đa trước khi khóa
    - Thời gian khóa tài khoản
    - Session timeout
  
  - **Backup & Restore:**
    - Tự động backup database (hàng ngày/tuần)
    - Manual backup
    - Restore từ backup
    - Download backup file

#### 11.8. Nhật ký hoạt động (Activity Logs)
- **Mô tả**: Theo dõi mọi hoạt động trong hệ thống
- **Chi tiết**:
  - **Danh sách nhật ký:**
    - **Bộ lọc:**
      - Lọc theo loại hoạt động: Tất cả, Đăng nhập, Duyệt tin, Xóa tin, Khóa tài khoản...
      - Lọc theo admin/user thực hiện
      - Lọc theo thời gian
      - Tìm kiếm theo keyword
    
    - **Bảng danh sách:**
      - Columns:
        - Thời gian
        - Loại hoạt động
        - Người thực hiện (Admin/User)
        - Mô tả chi tiết
        - IP address
        - User agent
        - Actions (Xem chi tiết)
      - Sortable columns
      - Pagination
  
  - **Chi tiết nhật ký:**
    - Thông tin đầy đủ về hoạt động
    - Dữ liệu trước và sau thay đổi (nếu có)
    - Screenshot hoặc snapshot (nếu có)
    - IP address và location
    - Device information
  
  - **Thống kê nhật ký:**
    - Số lượng hoạt động theo loại
    - Top admin/user hoạt động nhiều nhất
    - Hoạt động theo thời gian trong ngày
    - Phát hiện hoạt động bất thường

#### 11.9. Quản lý Admin
- **Mô tả**: Quản lý tài khoản admin và phân quyền
- **Chi tiết**:
  - **Danh sách admin:**
    - Hiển thị tất cả tài khoản admin
    - Thông tin: Tên, Email, Vai trò, Trạng thái, Lần đăng nhập cuối
    - Actions: Chỉnh sửa, Xóa, Reset mật khẩu
  
  - **Thêm/Sửa admin:**
    - Form: Tên, Email, Mật khẩu, Vai trò
    - Chọn quyền truy cập:
      - Quản lý tin đăng
      - Quản lý người dùng
      - Quản lý báo cáo
      - Xem thống kê
      - Cài đặt hệ thống
      - Quản lý admin
    - Lưu và gửi thông tin đăng nhập qua email
  
  - **Phân quyền:**
    - Role-based access control (RBAC)
    - Mỗi vai trò có quyền truy cập khác nhau
    - Có thể tùy chỉnh quyền cho từng admin

---

## 🟠 CẤP ĐỘ KHÓ (ADVANCED)

### 11. Tìm kiếm thông minh
#### 11.1. Tìm kiếm bằng giọng nói
- **Mô tả**: Tìm kiếm bằng voice
- **Chi tiết**:
  - Tích hợp Speech-to-Text
  - Nhận diện tiếng Việt
  - Chuyển đổi giọng nói thành text
  - Xử lý lỗi nhận diện

#### 11.2. Tìm kiếm bằng hình ảnh
- **Mô tả**: Tìm phòng trọ tương tự qua ảnh
- **Chi tiết**:
  - Upload ảnh phòng trọ
  - AI nhận diện đặc điểm (màu sắc, nội thất, phong cách)
  - Tìm các phòng trọ tương tự
  - Sử dụng ML Kit hoặc custom model

#### 11.3. Gợi ý thông minh
- **Mô tả**: AI đề xuất phòng trọ phù hợp
- **Chi tiết**:
  - Phân tích lịch sử tìm kiếm
  - Phân tích phòng đã xem/yêu thích
  - Đề xuất dựa trên sở thích
  - Machine Learning model
  - Collaborative filtering

### 12. Tính năng nâng cao
#### 12.1. So sánh phòng trọ
- **Mô tả**: So sánh nhiều phòng trọ
- **Chi tiết**:
  - Chọn tối đa 3-5 phòng để so sánh
  - Bảng so sánh: Giá, diện tích, tiện ích, địa điểm
  - Highlight điểm khác biệt
  - Export so sánh

#### 12.2. Lịch xem phòng
- **Mô tả**: Đặt lịch xem phòng trọ
- **Chi tiết**:
  - Calendar picker
  - Chọn khung giờ
  - Gửi yêu cầu xem phòng
  - Xác nhận từ chủ trọ
  - Nhắc nhở trước giờ hẹn
  - Hủy/đổi lịch

#### 12.3. Thanh toán online
- **Mô tả**: Thanh toán phí dịch vụ
- **Chi tiết**:
  - Tích hợp cổng thanh toán (VNPay, Momo, ZaloPay)
  - Thanh toán phí đăng tin
  - Thanh toán phí nâng cấp tin
  - Lịch sử giao dịch
  - Hoàn tiền

### 13. Quản lý nâng cao
#### 13.1. Quản lý nhiều tài khoản
- **Mô tả**: Chuyển đổi giữa tài khoản người thuê và chủ trọ
- **Chi tiết**:
  - Đăng ký 2 loại tài khoản
  - Chuyển đổi mode
  - UI khác nhau cho mỗi loại
  - Quản lý riêng biệt

#### 13.2. Thống kê và Báo cáo
- **Mô tả**: Thống kê cho chủ trọ
- **Chi tiết**:
  - Số lượt xem tin
  - Số lượt liên hệ
  - Tỷ lệ chuyển đổi
  - Biểu đồ thống kê
  - Export báo cáo

#### 13.3. Quản lý hợp đồng
- **Mô tả**: Tạo và quản lý hợp đồng thuê
- **Chi tiết**:
  - Template hợp đồng
  - Điền thông tin tự động
  - Ký điện tử
  - Lưu trữ hợp đồng
  - Nhắc nhở gia hạn

### 14. Tối ưu hiệu suất
#### 14.1. Caching thông minh
- **Mô tả**: Cache dữ liệu để tăng tốc
- **Chi tiết**:
  - Cache hình ảnh
  - Cache danh sách phòng trọ
  - Cache API responses
  - Cache invalidation strategy
  - LRU cache

#### 14.2. Lazy Loading
- **Mô tả**: Tải dữ liệu khi cần
- **Chi tiết**:
  - Infinite scroll
  - Lazy load images
  - Code splitting
  - Reduce initial load time

#### 14.3. Offline Mode
- **Mô tả**: Sử dụng app khi không có internet
- **Chi tiết**:
  - Sync dữ liệu khi online
  - Xem danh sách đã cache
  - Queue các thao tác khi offline
  - Sync khi có internet lại
  - Conflict resolution

### 15. Bảo mật nâng cao
#### 15.1. Xác thực 2 lớp (2FA)
- **Mô tả**: Bảo mật tài khoản
- **Chi tiết**:
  - OTP qua SMS/Email
  - Authenticator app (Google Authenticator)
  - Backup codes
  - Recovery options

#### 15.2. Mã hóa dữ liệu
- **Mô tả**: Bảo vệ dữ liệu nhạy cảm
- **Chi tiết**:
  - Encrypt local storage
  - Encrypt sensitive data
  - Secure API communication (HTTPS)
  - Certificate pinning

### 16. Tích hợp bên thứ ba
#### 16.1. Social Login
- **Mô tả**: Đăng nhập bằng mạng xã hội
- **Chi tiết**:
  - Google Sign-In
  - Facebook Login
  - Apple Sign-In (iOS)
  - Zalo Login
  - Xử lý callback

#### 16.2. Chia sẻ
- **Mô tả**: Chia sẻ phòng trọ
- **Chi tiết**:
  - Share qua Facebook, Zalo, Messenger
  - Share qua SMS, Email
  - Deep linking
  - Generate share link
  - QR code

---

## 🔴 CẤP ĐỘ RẤT KHÓ (EXPERT)

### 17. AI và Machine Learning
#### 17.1. Nhận diện gian lận
- **Mô tả**: Phát hiện tin đăng giả/spam
- **Chi tiết**:
  - ML model phân tích nội dung
  - Phát hiện hình ảnh giả
  - Phát hiện giá bất thường
  - Tự động gắn cờ nghi ngờ
  - Học từ dữ liệu người dùng báo cáo

#### 17.2. Dự đoán giá
- **Mô tả**: Dự đoán giá phòng trọ hợp lý
- **Chi tiết**:
  - Phân tích dữ liệu lịch sử
  - Xem xét vị trí, diện tích, tiện ích
  - Đưa ra mức giá dự đoán
  - Cảnh báo giá bất thường
  - Regression model

#### 17.3. Chatbot hỗ trợ
- **Mô tả**: Trợ lý ảo tự động
- **Chi tiết**:
  - NLP xử lý câu hỏi tiếng Việt
  - Trả lời câu hỏi thường gặp
  - Hướng dẫn sử dụng app
  - Tích hợp với backend AI
  - Context awareness

### 18. Real-time Features
#### 18.1. Real-time Updates
- **Mô tả**: Cập nhật real-time
- **Chi tiết**:
  - WebSocket connection
  - Real-time chat
  - Real-time thông báo
  - Real-time cập nhật giá
  - Connection management

#### 18.2. Live Streaming
- **Mô tả**: Xem phòng trọ trực tiếp
- **Chi tiết**:
  - Video call với chủ trọ
  - Live tour 360 độ
  - Record và lưu lại
  - Tích hợp WebRTC

### 19. AR/VR Features
#### 19.1. AR View
- **Mô tả**: Xem phòng trọ qua AR
- **Chi tiết**:
  - ARKit/ARCore integration
  - Overlay thông tin phòng trọ
  - 3D model phòng trọ
  - Đo khoảng cách AR
  - Virtual tour

#### 19.2. 360° Virtual Tour
- **Mô tả**: Tour ảo 360 độ
- **Mô tả**:
  - Upload ảnh 360°
  - Interactive tour
  - Hotspot navigation
  - VR mode với Cardboard
  - Smooth transitions

### 20. Analytics và Monitoring
#### 20.1. User Analytics
- **Mô tả**: Phân tích hành vi người dùng
- **Chi tiết**:
  - Track user events
  - Funnel analysis
  - User journey mapping
  - A/B testing
  - Firebase Analytics / Mixpanel

#### 20.2. Performance Monitoring
- **Mô tả**: Giám sát hiệu suất app
- **Chi tiết**:
  - Crash reporting (Firebase Crashlytics)
  - Performance monitoring
  - Network monitoring
  - Memory leaks detection
  - Custom metrics

### 21. Advanced Features
#### 21.1. Multi-language
- **Mô tả**: Đa ngôn ngữ
- **Chi tiết**:
  - Tiếng Việt, Tiếng Anh
  - Dynamic language switching
  - Localization files
  - RTL support (nếu cần)

#### 21.2. Dark Mode
- **Mô tả**: Chế độ tối
- **Chi tiết**:
  - Theme switching
  - System theme detection
  - Smooth transition
  - Custom dark theme colors

#### 21.3. Accessibility
- **Mô tả**: Hỗ trợ người khuyết tật
- **Chi tiết**:
  - Screen reader support
  - High contrast mode
  - Font size scaling
  - Voice commands
  - Gesture alternatives

### 22. Advanced Security
#### 22.1. Biometric Authentication
- **Mô tả**: Xác thực sinh trắc học
- **Chi tiết**:
  - Fingerprint authentication
  - Face ID / Face Recognition
  - Biometric login
  - Secure storage với biometric

#### 22.2. App Shielding
- **Mô tả**: Bảo vệ app khỏi reverse engineering
- **Chi tiết**:
  - Code obfuscation
  - Anti-tampering
  - Root/jailbreak detection
  - Certificate pinning nâng cao

### 23. Advanced Backend Integration
#### 23.1. Microservices Architecture
- **Mô tả**: Tích hợp với backend phức tạp
- **Chi tiết**:
  - Multiple API endpoints
  - Service discovery
  - Load balancing
  - Circuit breaker pattern

#### 23.2. GraphQL Integration
- **Mô tả**: Sử dụng GraphQL thay vì REST
- **Chi tiết**:
  - GraphQL client
  - Query optimization
  - Caching strategies
  - Real-time subscriptions

### 24. Advanced UI/UX
#### 24.1. Custom Animations
- **Mô tả**: Animation phức tạp
- **Chi tiết**:
  - Page transitions
  - Micro-interactions
  - Loading animations
  - Gesture-based animations
  - Physics-based animations

#### 24.2. Advanced List Features
- **Mô tả**: Danh sách nâng cao
- **Chi tiết**:
  - Sticky headers
  - Expandable items
  - Drag to reorder
  - Swipe actions
  - Multi-select

### 25. Testing và Quality Assurance
#### 25.1. Unit Testing
- **Mô tả**: Test từng component
- **Chi tiết**:
  - Widget tests
  - Unit tests cho business logic
  - Mock dependencies
  - Test coverage > 80%

#### 25.2. Integration Testing
- **Mô tả**: Test tích hợp
- **Chi tiết**:
  - API integration tests
  - Database tests
  - End-to-end tests
  - UI automation tests

#### 25.3. Performance Testing
- **Mô tả**: Test hiệu suất
- **Chi tiết**:
  - Load testing
  - Stress testing
  - Memory profiling
  - Battery usage optimization

---

## 📊 TỔNG KẾT

### Phân bổ theo độ khó:
- **Dễ**: ~15 chức năng chính
- **Trung bình**: ~20 chức năng chính (bao gồm Admin)
- **Khó**: ~10 chức năng chính
- **Rất khó**: ~10 chức năng chính

### Ưu tiên phát triển:
1. **Phase 1 (MVP)**: Các chức năng cấp độ Dễ
2. **Phase 2**: Các chức năng cấp độ Trung bình
3. **Phase 3**: Các chức năng cấp độ Khó
4. **Phase 4**: Các chức năng cấp độ Rất khó (nếu cần)

### Lưu ý:
- Mỗi chức năng có thể được chia nhỏ thành nhiều task
- Ưu tiên các chức năng core trước (tìm kiếm, xem chi tiết, đăng tin)
- Test kỹ từng chức năng trước khi chuyển sang chức năng mới
- Cân nhắc thời gian và nguồn lực khi lựa chọn chức năng

---

**Tài liệu này có thể được cập nhật và mở rộng theo tiến độ dự án.**

