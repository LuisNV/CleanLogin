import Foundation

/// Chuỗi lỗi hiển thị cho người dùng. Gom một chỗ để mọi ViewModel xử lý giống nhau.
enum ErrorMessage {
    static func from(_ error: Error) -> String {
        (error as? AuthError)?.localizedDescription
            ?? AuthError.serviceUnavailable.localizedDescription
    }

    static func isCancellation(_ error: Error) -> Bool {
        error is CancellationError || Task.isCancelled
    }
}
