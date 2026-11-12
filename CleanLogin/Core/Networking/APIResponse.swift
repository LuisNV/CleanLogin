import Foundation

struct APIResponse<Payload: Decodable & Sendable>: Decodable, Sendable {
    let code: Int
    let httpStatus: Int
    let message: String
    let data: Payload?
    let traceId: String?
}

// Đọc metadata mà không phụ thuộc cấu trúc data của response lỗi hoặc logout.
struct APIResponseMetadata: Decodable, Sendable {
    let code: Int
    let httpStatus: Int
    let message: String
    let traceId: String?
}
