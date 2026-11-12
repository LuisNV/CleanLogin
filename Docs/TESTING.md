# Kiểm tra dự án

## Trạng thái xác minh

| Kiểm tra | Trạng thái ở môi trường tạo dự án |
|---|---|
| Backend API: 7 integration tests | Đã chạy, đạt |
| Parse cú pháp Swift | Đã kiểm tra bằng Tree-sitter; không phải compiler |
| Cấu trúc pbxproj, scheme, plist, source membership | Đã kiểm tra tĩnh |
| Quy tắc import Domain/Presentation | Đã kiểm tra tĩnh |
| Resolve SPM / build iOS | Chưa chạy; cần Xcode/macOS |
| 14 XCTest của app | Có source/target/scheme; chưa chạy |
| UI và Keychain trên Simulator | Chưa chạy |

Không coi kiểm tra parser là bằng chứng ứng dụng build thành công. Cần thực hiện các bước Xcode bên dưới trên Mac.

## Unit tests iOS

Mở project, chọn scheme **CleanLogin-Mock**, chọn iPhone Simulator rồi bấm **Command + U**.

- LoginUseCaseTests: chuẩn hóa email, giữ nguyên password, chặn email sai và password rỗng.
- AuthRepositoryTests: map user/lưu token, sai credentials, hết phiên, lỗi mạng giữ token, không token không gọi mạng, lỗi Keychain, token rỗng, logout.
- LoginViewModelTests: chuỗi loading/success, lỗi không điều hướng, cancellation không hiển thị lỗi/điều hướng.

Các unit test dùng fake service và MemoryTokenStore, không gọi backend hoặc ghi token của test vào Keychain.

Nếu chạy CLI, đứng tại thư mục gốc CleanLogin:

```bash
xcodebuild -resolvePackageDependencies -project CleanLogin.xcodeproj -scheme CleanLogin-Mock
```

```bash
xcodebuild -project CleanLogin.xcodeproj -scheme CleanLogin-Mock \
  -sdk iphonesimulator -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

Liệt kê simulator hiện có bằng `xcrun simctl list devices available`, rồi thay `<UDID>`:

```bash
xcodebuild -project CleanLogin.xcodeproj -scheme CleanLogin-Mock \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  CODE_SIGNING_ALLOWED=NO test
```

## Backend integration tests

Python 3.9 trở lên, không cần pip:

```bash
python3 -m unittest discover -s Backend -v
```

Test tự mở server trên một port trống, tự đóng khi kết thúc; không cần chạy server.py trước.

## Checklist Simulator

| Tình huống | Mong đợi |
|---|---|
| Email/password trống | Báo lỗi input |
| Email sai dạng | Không gửi login request |
| Sai mật khẩu | Báo sai thông tin, nút cho thử lại |
| Bấm nhanh nhiều lần | Chỉ một login đang chạy |
| Login đúng | Home hiển thị tên/email |
| Tắt app, mở lại khi token hợp lệ | Xác minh /auth/me rồi vào Home |
| Có token nhưng backend ngừng chạy lúc mở app | Màn hình lỗi có Thử lại/Xóa phiên |
| Backend hoạt động lại, nhấn Thử lại | Kiểm tra phiên lại |
| Refresh khi mất mạng | Giữ Home/token, báo lỗi |
| Refresh sau khi token hết hạn | Xóa token, về Login, có thông báo hết phiên |
| Logout | Xóa token, về Login, không Back về Home |
| Logout rồi tắt/mở app | Vẫn ở Login |
| Đổi mock sang local | Không dùng nhầm token mock |
| RemoteAPI chưa sửa URL mẫu | Thông báo cấu hình, không gửi request vào example.com |
| Dark Mode / cỡ chữ lớn / landscape / bàn phím | Form có thể cuộn, màu theo hệ thống |

Để reset token, dùng Đăng xuất hoặc Xóa phiên trên màn hình lỗi. Keychain có thể tồn tại qua cài lại ứng dụng; không mặc định rằng uninstall luôn xóa Keychain.

## Vấn đề thường gặp

- **No such module RxSwift/Alamofire:** đợi SPM resolve; kiểm tra mạng truy cập GitHub, chọn File → Packages → Resolve Package Versions. Sản phẩm đã được gắn vào target.
- **LocalAPI không kết nối:** chạy `python3 Backend/server.py`, thử `/health`, dùng iPhone Simulator trên cùng Mac. Localhost trên iPhone thật là chính iPhone đó.
- **Port 8080 đang bị dùng:** dừng tiến trình server cũ của bạn hoặc chọn port khác và sửa URL trong AppConfiguration.localAPI cho khớp.
- **Lỗi Signing:** chạy Simulator; với thiết bị thật chọn Team của bạn và Bundle Identifier phù hợp.
- **Decode lỗi:** so JSON thật với Docs/API_CONTRACT.md. Backend mẫu trả user trực tiếp ở GET /auth/me.
- **Khóa thiết bị/Keychain chưa truy cập được:** mở khóa và thử lại. Store dùng WhenUnlockedThisDeviceOnly.
