//
//  arraytools.swift
//  swiftbridge
//
//  Created by ELLUL, Alexander (Alex) on 13/12/2025.
//


import Foundation

/// Small utilities shared across the framework for bridging Swift data over a C ABI.
///
/// The core idea is to keep a Swift-owned, reusable raw buffer that can be exposed as an
/// `UnsafeRawPointer` to foreign code (e.g. Rust) without requiring a "free" function.
///
/// Important:
/// - The returned memory is owned by Swift.
/// - Any pointer returned to foreign code is only valid until the next call that reuses
///   the same buffer.
/// - This pattern is best for "snapshot" reads (query → copy/consume immediately).

@usableFromInline
internal struct ReusableRawBuffer {
    /// Pointer to the allocated storage (Swift-owned). May be nil until first use.
    @usableFromInline var ptr: UnsafeMutableRawPointer? = nil
    /// Current capacity of `ptr` in bytes.
    @usableFromInline var capacityBytes: Int = 0

    /// Ensures `ptr` has at least `byteCount` bytes allocated with `alignment`.
    ///
    /// - Returns: A valid pointer to `byteCount` bytes, or nil if `byteCount <= 0`.
    ///
    /// The buffer may be reallocated (and the previous pointer invalidated) when growing.
    @usableFromInline
    mutating func ensure(byteCount: Int, alignment: Int) -> UnsafeMutableRawPointer? {
        guard byteCount > 0 else { return nil }

        if ptr == nil || capacityBytes < byteCount {
            if let existing = ptr {
                existing.deallocate()
            }
            ptr = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
            capacityBytes = byteCount
        }

        return ptr
    }
}

/// Creates a typed view over a Swift-owned raw buffer laid out as:
///
/// - `Header` (one element)
/// - followed by `count` `Element` values
///
/// This is useful when exporting "array-like" structures over a C ABI.
///
/// Safety/lifetime:
/// - The returned pointers alias `buffer` storage.
/// - They are only valid until the next operation that mutates/reallocates `buffer`.
@usableFromInline
internal func makeArrayView<Header, Element>(
    count: Int,
    buffer: inout ReusableRawBuffer
) -> (base: UnsafeMutableRawPointer, header: UnsafeMutablePointer<Header>, elements: UnsafeMutablePointer<Element>)? {
    let headerSize = MemoryLayout<Header>.stride
    let elementSize = MemoryLayout<Element>.stride
    let bytesNeeded = headerSize + (max(0, count) * elementSize)

    let alignment = max(MemoryLayout<Header>.alignment, MemoryLayout<Element>.alignment)
    guard let base = buffer.ensure(byteCount: bytesNeeded, alignment: alignment) else { return nil }

    let headerPtr = base.assumingMemoryBound(to: Header.self)
    let elementsPtr = base.advanced(by: headerSize).assumingMemoryBound(to: Element.self)
    return (base: base, header: headerPtr, elements: elementsPtr)
}

/// Writes an array of object pointers as unretained `UnsafeRawPointer` values.
///
/// This is intended for bridging Objective-C/Swift class instances (e.g. `NSScreen`, `NSWindow`)
/// to foreign code. The pointers are *borrowed* references; callers must not free them.
///
/// The foreign side should treat these as opaque handles and only use them with Swift-exported
/// functions that expect the same pointer.
@usableFromInline
internal func writeUnretainedObjectPointers<T: AnyObject>(
    _ objects: [T],
    to out: UnsafeMutablePointer<UnsafeRawPointer?>
) {
    for i in objects.indices {
        out[i] = UnsafeRawPointer(Unmanaged.passUnretained(objects[i]).toOpaque())
    }
}

