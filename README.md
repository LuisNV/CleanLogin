# CleanLogin — UIKit + Clean Architecture

Dự án đăng nhập dành cho người đã biết Flutter/Bloc và đang học Swift + UIKit viết giao diện bằng code.

**Stack:** Swift, UIKit, MVVM, Clean Architecture, Repository, UseCase, Coordinator, constructor DI, RxSwift/RxCocoa/RxRelay, Alamofire và Keychain.

## Chạy nhanh

1. Giải nén toàn bộ thư mục.
2. Mở `CleanLogin.xcodeproj` bằng **Xcode 16 trở lên**.
3. Chờ Xcode tải Swift Package Dependencies. Lần đầu cần Internet để tải từ GitHub.
4. Chọn scheme **CleanLogin-Mock** và iPhone Simulator có iOS 16 trở lên.
5. Bấm **Command + R**.
6. Đăng nhập: **demo@example.com** / **123456**.

Không cần CocoaPods, không cần tự tạo file hoặc kéo thả Storyboard. SPM đã cấu hình trong `.xcodeproj`, ghim RxSwift **6.9.0** và Alamofire **5.10.2** để ví dụ có dependency xác định. Không khẳng định đây là các bản mới nhất. Project dùng Swift 5 language mode và strict concurrency checking complete.

Nếu chạy trên iPhone thật: chọn Team của bạn trong Target → Signing & Capabilities và đổi Bundle Identifier nếu cần. Chế độ LocalAPI bên dưới dành cho **Simulator trên cùng Mac**.

## Ba chế độ

| Scheme | Nguồn dữ liệu | Cần backend? |
|---|---|---|
| `CleanLogin-Mock` | `MockAuthService`, chờ giả lập khoảng 0,65 giây | Không |
| `CleanLogin-LocalAPI` | Alamofire gọi `http://localhost:8080` | Có, chạy `Backend/server.py` |
| `CleanLogin-RemoteAPI` | Alamofire gọi URL HTTPS của bạn | Có, cấu hình `API_BASE_URL` |

Mock là mặc định nếu không có biến môi trường. Scheme RemoteAPI chủ động hiện lỗi cấu hình cho tới khi bạn thay URL mẫu bằng backend của mình.

Biến môi trường của scheme dùng khi Xcode chạy app. Đây là cấu hình phục vụ học/debug, không phải cơ chế lựa chọn môi trường cho bản phân phối App Store; trước khi phát hành cần cấu hình build/xcconfig phù hợp.

## Thử gọi API thật trên Mac

Mở Terminal trong thư mục dự án và chạy Python 3.9 trở lên:

```bash
python3 Backend/server.py
```

Giữ Terminal đang chạy, chọn **CleanLogin-LocalAPI**, chạy iPhone Simulator rồi đăng nhập bằng tài khoản demo. Nút **Cập nhật tài khoản** gọi `GET /auth/me` với Bearer token; không phải response hard-code trong ứng dụng.

Backend chỉ lắng nghe loopback `127.0.0.1`, phục vụ học tập. Info.plist cho phép HTTP cục bộ và có ngoại lệ localhost; không bật `NSAllowsArbitraryLoads` toàn cục. RemoteAPI yêu cầu HTTPS.

Token local hết hạn sau 3.600 giây. Để thử nhanh token hết hạn:

```bash
python3 Backend/server.py --token-ttl 15
```

Đăng nhập, chờ hơn 15 giây, bấm **Cập nhật tài khoản**: app xóa token và quay về Login với thông báo hết phiên. Dừng server bằng Ctrl+C. Khởi động lại server sẽ làm các token cũ vô hiệu vì phiên của backend mẫu chỉ nằm trong RAM.

## Nối backend của bạn

1. Chọn scheme **CleanLogin-RemoteAPI**.
2. Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables.
3. Thay `API_BASE_URL` bằng URL HTTPS thật, ví dụ `https://your-host.example/api/v1`.
4. Xem `Docs/API_CONTRACT.md` và chỉnh DTO/endpoint nếu backend trả JSON khác.
5. Giữ `AUTH_MODE=remoteAPI`.

`RemoteAuthService` dùng đường dẫn tương đối `auth/login` và `auth/me`. Nếu base URL có `/api/v1`, request sẽ đi vào `/api/v1/auth/login` và `/api/v1/auth/me`.

## Chức năng có sẵn

- Form UIKit bằng code, Auto Layout, Dynamic Type, Dark Mode và cuộn khi bàn phím mở.
- Validate email/trường trống trong UseCase, giữ nguyên password.
- Loading, báo lỗi, chặn submit trùng, hủy Task khi màn hình biến mất.
- RxSwift/RxRelay phát state; RxCocoa `Driver` đưa state tới UI, `rx.tap` nhận bấm nút.
- Alamofire cấu hình session, timeout, JSON, kiểm tra HTTP status và Bearer header.
- DTO → Domain mapping, lỗi tầng Data → lỗi Domain.
- Lưu access token trong Keychain; không lưu password, không log token hoặc request body.
- Mở lại app: đọc token, gọi `/auth/me` kiểm tra phiên trước khi mở Home.
- HTTP 401 khi khôi phục phiên: xóa token và về Login.
- Mất mạng hoặc server lỗi khi khôi phục phiên: giữ token, hiện Thử lại/Xóa phiên.
- Đăng xuất cục bộ, xóa token và thay navigation stack để không Back về Home.
- Token tách riêng theo mock/local/remote và base URL.
- Unit test target cho UseCase, Repository, ViewModel; backend mẫu có integration tests.

## Cách chia code

Code chia theo **feature** (vertical slice). Mỗi feature tự chứa Domain/Data/Presentation của mình; phần dùng chung nằm ở `Core` và `Shared`.

```
CleanLogin/
├── App/            # Lifecycle, cấu hình, AppContainer (composition root), AppCoordinator
├── Core/           # Không biết gì về feature
│   ├── Networking/ # APIClient (nơi DUY NHẤT refresh token), APIError, APIResponse
│   ├── Storage/    # TokenStore, AuthTokens, KeychainTokenStore
│   └── DesignSystem/ # AppColors, AppFonts, Loading, Toast, FormFieldView, DatePickerSheet
├── Shared/         # Dùng chung giữa nhiều feature
│   ├── Domain/     # User, AuthError
│   ├── Data/       # AuthErrorMapper (APIError → AuthError), DemoAccount (dữ liệu mock)
│   └── Presentation/ # BootstrapViewController, MainTabBarController, ErrorMessage
└── Features/
    ├── Auth/       # Đăng nhập, khôi phục phiên, đăng xuất + AuthFactory
    ├── Profile/    # Hồ sơ, chỉnh sửa + ProfileFactory, ProfileCoordinator
    ├── Home/       # Chỉ có Presentation (chưa có API)
    └── About/
```

| Nhóm | Trách nhiệm | Ví dụ |
|---|---|---|
| `Features/<X>/Domain` | Hợp đồng repository và UseCase của feature | `AuthRepository`, `LoginUseCase`, `UserRepository` |
| `Features/<X>/Data` | DTO, service (remote/mock), repository triển khai Domain | `AuthDTOs`, `RemoteAuthService`, `DefaultUserRepository` |
| `Features/<X>/Presentation` | ViewController, ViewModel, state | `LoginViewModel`, `ProfileViewController` |
| `Features/<X>/<X>Factory` | Lắp ráp UseCase/ViewModel/màn hình của feature | `AuthFactory`, `ProfileFactory` |
| `Features/<X>/<X>Coordinator` | Điều hướng bên trong feature (nếu có nhiều màn) | `ProfileCoordinator` |
| `App` | Chọn mock hay API, chia phụ thuộc chung cho các factory, điều hướng giữa các feature | `AppContainer`, `AppCoordinator` |

**Quy tắc phụ thuộc:**

- Domain không import UIKit, RxSwift, Alamofire hoặc Security, và không biết DTO/token.
- `Core` không biết feature nào (APIClient tự định nghĩa payload refresh, chỉ throw `APIError`).
- Feature không gọi màn hình của feature khác. Muốn chuyển màn thì báo ra ngoài bằng callback (`onLoginSuccess`, `onLogout`), `AppCoordinator` quyết định đi đâu.
- Thứ nhiều feature cùng cần (`User`, `AuthError`) đặt ở `Shared`, không copy.
- Feature chưa có dữ liệu thật (Home, About) chỉ cần thư mục `Presentation`.

**Hết phiên:** khi request cần đăng nhập bị 401, `APIClient` refresh một lần rồi retry. Nếu refresh token cũng hết hạn, nó xóa token, gọi `onSessionExpired` (AppContainer → AppCoordinator đưa về Login) và throw `APIError.unauthorized` (repository map thành `AuthError.sessionExpired`).

Các feature là folder trong một app target, chưa tách thành Swift Package. Xcode chưa cưỡng chế ranh giới; cần tuân thủ quy tắc trên khi code review. Khi số feature hoặc số người làm tăng, có thể tách mỗi feature thành một package.

## Nên đọc theo thứ tự nào?

1. `Shared/Domain/User.swift`, `Shared/Domain/AuthError.swift`.
2. `Features/Auth/Domain/AuthRepository.swift`, `LoginUseCase.swift`.
3. `Features/Auth/Presentation/Login/LoginViewModel.swift`, `LoginViewController.swift`.
4. `Features/Auth/Data/DefaultAuthRepository.swift`, `RemoteAuthService.swift`, `AuthDTOs.swift`.
5. `Features/Auth/AuthFactory.swift`.
6. `Features/Profile/` theo cùng thứ tự, rồi `ProfileCoordinator.swift`.
7. `Core/Networking/APIClient.swift`, `Core/Storage/KeychainTokenStore.swift`.
8. `App/AppContainer.swift`, `App/AppCoordinator.swift`, `App/SceneDelegate.swift`.

Xem **`Docs/LEARNING_GUIDE.md`** để theo dõi một lần bấm đăng nhập và đối chiếu với Flutter/Cubit. Xem **`Docs/TESTING.md`** để chạy test và kiểm tra thủ công.

## Giới hạn có chủ đích

Đây là dự án học tập đầy đủ cho phạm vi đăng nhập/tài khoản; chưa phải ứng dụng xác thực sẵn sàng phát hành. Chưa có đăng ký, quên mật khẩu, MFA, refresh token, revoke token phía server, certificate pinning hoặc account deletion. Không tự retry request đăng nhập.

Logout chỉ xóa token trên thiết bị. Token đã được sao chép ở nơi khác vẫn có thể dùng đến khi backend cho hết hạn; nếu backend có endpoint logout/revoke, bổ sung service/usecase tương ứng.

Backend Python dùng một tài khoản cố định để thử nghiệm, không có database/password hashing/rate limiting; không đưa backend này lên Internet. Mock token là hằng số minh họa, không có cơ chế hết hạn. Lưu token bằng Keychain không biến mock thành xác thực thật.

`@MainActor` bảo vệ luồng cập nhật trạng thái; Rx dùng cho binding UI, async/await dùng cho UseCase/Repository. Đây là lựa chọn để Domain không phụ thuộc Rx, không phải pipeline Rx từ đầu đến cuối.

## Kiểm tra đã thực hiện

- Backend: 7 integration tests đã chạy, gồm login/profile, sai mật khẩu, thiếu/sai/hết hạn token, dữ liệu sai dạng, phiên độc lập.
- Swift: kiểm tra cú pháp bằng parser, không tương đương compiler/type-check.
- Project: kiểm tra file nguồn, target memberships, scheme, dependency graph, Info.plist và cấu hình SPM.
- Đã tạo 14 XCTest cho app. **Chưa chạy XCTest, chưa resolve SPM hoặc build/chạy iOS Simulator** vì môi trường tạo dự án là Linux, không có Xcode/iOS SDK.

## Tài liệu gốc

- RxSwift: https://github.com/ReactiveX/RxSwift
- RxSwift traits: https://github.com/ReactiveX/RxSwift/blob/main/Documentation/Traits.md
- Alamofire: https://github.com/Alamofire/Alamofire
- Alamofire async/await: https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md
- Apple Keychain: https://developer.apple.com/documentation/security/keychain-services
