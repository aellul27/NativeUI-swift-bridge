import Foundation

/// Minimal error reporting facility for the C/Rust FFI surface.
///
/// Why this exists:
/// - Most Swift-exported C ABI functions can't throw across the boundary.
/// - Returning `nil`/0 from the C ABI is safe, but we still want a human-readable reason.
///
/// How to use from foreign code:
/// - Call a Swift-exported function.
/// - If it indicates failure (e.g. returns null/0), call `swiftbridge_last_error()`.
/// - Consume/copy the returned C string immediately, then call `swiftbridge_clear_last_error()`.
///
/// Lifetime:
/// - The returned pointer is Swift-owned and only valid until the next call to
///   `swiftbridge_last_error()` (or any later mutation that reuses the buffer).
/// - Do not free the pointer.

private final class SwiftBridgeLastError {
    private let lock = NSLock()
    private var message: String?
    private var cStringBuffer = ReusableRawBuffer()

    /// Stores/overwrites the current error message.
    func set(_ message: String) {
        lock.lock()
        self.message = message
        lock.unlock()
    }

    /// Clears the stored error message.
    func clear() {
        lock.lock()
        self.message = nil
        lock.unlock()
    }

    /// Returns the current error message as a NUL-terminated UTF-8 C string.
    ///
    /// The pointer is backed by a reusable Swift-owned buffer.
    /// Callers must copy the string if they need to keep it.
    func getCStringPointer() -> UnsafePointer<CChar>? {
        lock.lock()
        defer { lock.unlock() }

        guard let message = message else { return nil }
        guard var data = message.data(using: .utf8) else { return nil }
        data.append(0)

        guard let base = cStringBuffer.ensure(
            byteCount: data.count,
            alignment: MemoryLayout<CChar>.alignment
        ) else {
            return nil
        }
        _ = data.withUnsafeBytes { bytes in
            memcpy(base, bytes.baseAddress!, data.count)
        }
        return UnsafePointer<CChar>(base.assumingMemoryBound(to: CChar.self))
    }
}

private let gLastError = SwiftBridgeLastError()

/// Internal helper for Swift code to record an error for the next foreign call to retrieve.
@usableFromInline
internal func swiftbridge_set_last_error(_ message: String) {
    gLastError.set(message)
}

/// Returns the last error message recorded by the Swift bridge, if any.
///
/// - Returns: A Swift-owned NUL-terminated UTF-8 C string pointer, or null.
/// - Important: Valid until the next call to `swiftbridge_last_error()`.
@_cdecl("swiftbridge_last_error")
public func swiftbridge_last_error() -> UnsafePointer<CChar>? {
    return gLastError.getCStringPointer()
}

/// Clears the stored last error.
@_cdecl("swiftbridge_clear_last_error")
public func swiftbridge_clear_last_error() {
    gLastError.clear()
}
