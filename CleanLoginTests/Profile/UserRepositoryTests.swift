import XCTest
@testable import CleanLogin

@MainActor
final class UserRepositoryTests: XCTestCase {
    func testMapsDTOToDomain() async throws {
        let user = try await DefaultUserRepository(service: UserServiceStub()).getCurrentUser()
        XCTAssertEqual(user.fullName, "Nguyễn Văn Test")
        XCTAssertEqual(user.initials, "NT")
    }

    /// Hồi quy: trước đây lỗi hết phiên từ APIClient bị biến thành thông báo lỗi chung.
    func testUnauthorizedMapsToSessionExpired() async {
        let service = UserServiceStub()
        service.error = APIError.unauthorized
        do {
            _ = try await DefaultUserRepository(service: service).getCurrentUser()
            XCTFail("Expected session expired")
        } catch { XCTAssertEqual(error as? AuthError, .sessionExpired) }
    }

    func testTransportMapsToNetworkUnavailable() async {
        let service = UserServiceStub()
        service.error = APIError.transport
        do {
            _ = try await DefaultUserRepository(service: service).getCurrentUser()
            XCTFail("Expected network error")
        } catch { XCTAssertEqual(error as? AuthError, .networkUnavailable) }
    }
}
