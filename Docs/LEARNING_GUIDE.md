# Đọc dự án bằng tư duy Flutter / Bloc

## 1. Ánh xạ khái niệm

| Flutter | CleanLogin |
|---|---|
| Screen/StatefulWidget | UIViewController |
| Cubit quản lý trạng thái | ViewModel |
| State class | LoginViewState / HomeViewState |
| emit(state) | stateRelay.accept(state) |
| BlocBuilder/BlocListener | Driver.drive + render hoặc callback điều hướng |
| RxDart | RxSwift |
| Binding với UI | RxCocoa |
| Dio client dùng chung | APIClient bọc Alamofire Session |
| Abstract Repository | protocol AuthRepository |
| Repository implementation | DefaultAuthRepository |
| UseCase | LoginUseCase / RestoreSessionUseCase / LogoutUseCase |
| get_it / Provider wiring | AppContainer với constructor injection |
| Router/Navigator orchestration | AppCoordinator |
| flutter_secure_storage | KeychainTokenStore sử dụng Security framework |

Đây là đối chiếu trách nhiệm, không phải các API tương đương hoàn toàn. UIKit không tự dựng lại cây widget khi state đổi; `render` sửa trực tiếp từng control.

## 2. Luồng chạy thực tế

Khi mở app, `AppDelegate` chọn SceneDelegate. SceneDelegate tạo cửa sổ và UINavigationController, đọc AppConfiguration, tạo AppContainer rồi AppCoordinator. SceneDelegate giữ Coordinator bằng thuộc tính để Coordinator không bị giải phóng ngay sau khi hàm khởi tạo kết thúc.

Coordinator chạy RestoreSessionUseCase. Không có token thì mở Login. Có token thì Repository gọi `/auth/me`; chỉ khi backend xác nhận mới mở Home. Mạng lỗi không đồng nghĩa với token sai: màn hình khởi động hiện Thử lại và không xóa token.

Tại Login:

1. `loginButton.rx.tap` phát sự kiện.
2. ViewController lấy text rồi gọi `viewModel.login` trong Task.
3. ViewModel phát `LoginViewState(isLoading: true)`.
4. View nhận state qua `Driver.drive` và chạy `render`.
5. ViewModel gọi `LoginUseCase.execute`.
6. UseCase trim/lowercase email, kiểm tra trường trống và hình thức email. Password giữ nguyên.
7. UseCase gọi protocol AuthRepository.
8. DefaultAuthRepository gọi AuthService.
9. RemoteAuthService encode body, gọi APIClient với endpoint `auth/login`.
10. APIClient gửi request bằng Alamofire, kiểm tra status, decode LoginResponseDTO.
11. Repository kiểm tra token, lưu Keychain, map UserDTO thành User.
12. ViewModel kết thúc loading và gọi callback thành công.
13. Coordinator thay navigation stack bằng Home.

Trong scheme Mock, bước gọi remote được thay bằng MockAuthService. Các tầng trên không đổi.

## 3. Tại sao cần UseCase nếu đã có ViewModel?

ViewModel quản lý trạng thái giao diện: đang chờ hay không, thông báo gì, phát sự kiện thành công. UseCase biểu diễn thao tác của ứng dụng: đăng nhập với dữ liệu hợp lệ, khôi phục phiên, đăng xuất. Nó không biết spinner, label hoặc navigation controller.

UseCase có thể được tái sử dụng từ màn hình khác, và test không cần Rx/UIKit. Với ví dụ nhỏ, RestoreSessionUseCase và LogoutUseCase chỉ ủy quyền cho Repository để minh họa ranh giới; không bắt buộc mọi app nhỏ phải thêm các wrapper này.

## 4. RxSwift thực sự nằm ở đâu?

`BehaviorRelay<LoginViewState>` giữ state hiện tại và phát các giá trị tiếp theo. Relay nằm private trong ViewModel để View không tự sửa state.

```swift
private let stateRelay: BehaviorRelay<LoginViewState>
var state: Driver<LoginViewState> { stateRelay.asDriver() }
```

ViewController nhận Driver và subscribe:

```swift
viewModel.state
    .drive(onNext: { [weak self] state in
        self?.render(state)
    })
    .disposed(by: disposeBag)
```

Driver dành cho luồng UI: đưa sự kiện trên main scheduler, không phát error kết thúc stream, chia sẻ và replay giá trị mới nhất khi có subscription. Lỗi đăng nhập được biểu diễn bằng `errorMessage` trong state, nên người dùng có thể thử lại nhiều lần mà subscription không chết sau lần lỗi đầu tiên.

DisposeBag giữ subscription và dispose khi ViewController được giải phóng. `[weak self]` tránh vòng giữ ViewController → DisposeBag → subscription → closure → ViewController. Các closure điều hướng cũng capture Coordinator yếu.

## 5. Vì sao Rx đi cùng async/await?

Rx dùng cho UI/state, async/await dùng cho nghiệp vụ và I/O. Như vậy protocol Domain không phụ thuộc RxSwift. Nếu sau này thay Rx bằng Combine hoặc closure, chỉ Presentation thay đổi; UseCase và Repository vẫn dùng được.

Task của login nằm trong ViewController; closure Task giữ ViewModel riêng và capture ViewController yếu. Khi màn hình biến mất, task bị hủy. ViewModel xử lý cancellation như một kết thúc bình thường, không hiển thị lỗi hoặc chuyển màn hình. Alamofire DataTask được bật automaticallyCancelling để nối hủy Swift Task xuống request mạng.

Các loại liên quan đến UI/usecase/repository được cô lập bằng @MainActor trong ví dụ này. Await network không chặn main thread. Nếu xử lý JSON rất lớn hoặc tác vụ CPU nặng, cần tách công việc khỏi main actor; không suy ra mọi công việc đều nên chạy ở đây.

## 6. DI không nhất thiết cần thư viện

Trong AppContainer:

```swift
let service = RemoteAuthService(client: APIClient(baseURL: baseURL))
let store = KeychainTokenStore(service: namespace)
let repository = DefaultAuthRepository(service: service, tokenStore: store)
let useCase = LoginUseCase(repository: repository)
let viewModel = LoginViewModel(loginUseCase: useCase)
```

Các dòng trên minh họa thứ tự lắp ráp; xem file thật để có biến cấu hình đầy đủ. Mỗi lớp nhận dependency từ bên ngoài qua init. Test inject stub/mock thay implementation thật mà không cần singleton hoặc service locator.

## 7. Ranh giới Repository / Service / APIClient

| Lớp | Biết gì? | Không xử lý gì? |
|---|---|---|
| APIClient | HTTP, timeout, Bearer header, decoding | Không hiểu màn hình Login hay lỗi sai mật khẩu |
| RemoteAuthService | Endpoint và DTO của chức năng auth | Không cập nhật UI hoặc lưu token |
| DefaultAuthRepository | Mapping, token storage, ngữ nghĩa lỗi auth | Không render label hoặc push màn hình |
| LoginUseCase | Input và thao tác đăng nhập của app | Không biết JSON/Alamofire/Keychain |
| LoginViewModel | State giao diện, kết quả tác vụ | Không biết base URL hoặc key của Keychain |
| AppCoordinator | Mở màn hình nào | Không gửi request hoặc validate password |

## 8. Bài tập thực hành

1. Đổi màu nút trong LoginViewController mà không sửa ViewModel.
2. Đổi tên user mock trong MockAuthService mà không sửa UI.
3. Chạy LocalAPI, bấm refresh để xem request GET trong terminal.
4. Dừng server khi đang ở Home rồi refresh: vẫn ở Home và báo lỗi mạng.
5. Khởi động lại server rồi refresh: token cũ vô hiệu, app về Login.
6. Đặt token TTL 15 giây để thử hết phiên.
7. Đọc AuthRepositoryTests và tìm test chứng minh mất mạng không xóa token.
8. Thêm một feature ProfileEdit với UseCase mới, giữ cùng Repository contract nếu phù hợp.
