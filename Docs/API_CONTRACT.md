# Hợp đồng API mẫu

## POST /auth/login

Headers:

```http
Accept: application/json
Content-Type: application/json
```

Request:

```json
{"email":"demo@example.com","password":"123456"}
```

HTTP 200:

```json
{
  "accessToken": "opaque-token-string",
  "user": {
    "id": "001",
    "fullName": "Nguyễn Thành",
    "email": "demo@example.com"
  }
}
```

HTTP 401 nghĩa là sai thông tin đăng nhập. App map thành `AuthError.invalidCredentials`. HTTP 400/415/5xx được hiển thị dưới dạng lỗi service chung; app không đưa nguyên thông báo nội bộ backend lên UI.

## GET /auth/me

```http
Accept: application/json
Authorization: Bearer <accessToken>
```

HTTP 200 trả trực tiếp object user, không có lớp bọc `data`:

```json
{"id":"001","fullName":"Nguyễn Thành","email":"demo@example.com"}
```

HTTP 401: token thiếu, sai, bị thu hồi hoặc hết hạn. App xóa token, yêu cầu đăng nhập lại. HTTP 403 không tự coi là hết phiên; app giữ token và báo lỗi.

## GET /health (chỉ backend mẫu)

HTTP 200: `{"status":"ok"}`. App không dùng endpoint này.

## Cấu hình client

| Thiết lập | Giá trị |
|---|---|
| Base URL local | `http://localhost:8080` |
| Base URL remote | `API_BASE_URL`, bắt buộc HTTPS |
| Request timeout | 20 giây chờ thêm dữ liệu |
| Resource timeout | 40 giây |
| Cache/session | URLSessionConfiguration.ephemeral |
| Redirect | Không theo redirect cho request có credential |
| Retry | Không tự retry |
| Token store | Keychain, WhenUnlockedThisDeviceOnly |

Đây là ví dụ hợp đồng, không phải chuẩn áp dụng cho mọi backend. Nếu backend trả `data.user`, `access_token`, id dạng số hoặc một kiểu lỗi khác, sửa `AuthDTOs.swift`, `RemoteAuthService.swift` và mapping của Repository cho khớp.

Nếu backend dùng cookie session thay cho Bearer token, cần thiết kế lại storage/session; mẫu hiện tại không dành cho cookie auth.

## Các lệnh thử trên Mac

```bash
curl -i http://localhost:8080/health
```

```bash
curl -i http://localhost:8080/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@example.com","password":"123456"}'
```

Thay `<token>` bằng accessToken nhận được (chỉ dùng token demo):

```bash
curl -i http://localhost:8080/auth/me \
  -H 'Authorization: Bearer <token>'
```
