// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!

// swiftlint:disable all
import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(matrix_sdkFFI)
import matrix_sdkFFI
#endif

fileprivate extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func empty() -> RustBuffer {
        RustBuffer(capacity: 0, len:0, data: nil)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_matrix_sdk_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_matrix_sdk_rustbuffer_free(self, $0) }
    }
}

fileprivate extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a library of its own.

fileprivate extension Data {
    init(rustBuffer: RustBuffer) {
        // TODO: This copies the buffer. Can we read directly from a
        // Rust buffer?
        self.init(bytes: rustBuffer.data!, count: Int(rustBuffer.len))
    }
}

// Define reader functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.
//
// With external types, one swift source file needs to be able to call the read
// method on another source file's FfiConverter, but then what visibility
// should Reader have?
// - If Reader is fileprivate, then this means the read() must also
//   be fileprivate, which doesn't work with external types.
// - If Reader is internal/public, we'll get compile errors since both source
//   files will try define the same type.
//
// Instead, the read() method and these helper functions input a tuple of data

fileprivate func createReader(data: Data) -> (data: Data, offset: Data.Index) {
    (data: data, offset: 0)
}

// Reads an integer at the current offset, in big-endian order, and advances
// the offset on success. Throws if reading the integer would move the
// offset past the end of the buffer.
fileprivate func readInt<T: FixedWidthInteger>(_ reader: inout (data: Data, offset: Data.Index)) throws -> T {
    let range = reader.offset..<reader.offset + MemoryLayout<T>.size
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    if T.self == UInt8.self {
        let value = reader.data[reader.offset]
        reader.offset += 1
        return value as! T
    }
    var value: T = 0
    let _ = withUnsafeMutableBytes(of: &value, { reader.data.copyBytes(to: $0, from: range)})
    reader.offset = range.upperBound
    return value.bigEndian
}

// Reads an arbitrary number of bytes, to be used to read
// raw bytes, this is useful when lifting strings
fileprivate func readBytes(_ reader: inout (data: Data, offset: Data.Index), count: Int) throws -> Array<UInt8> {
    let range = reader.offset..<(reader.offset+count)
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    var value = [UInt8](repeating: 0, count: count)
    value.withUnsafeMutableBufferPointer({ buffer in
        reader.data.copyBytes(to: buffer, from: range)
    })
    reader.offset = range.upperBound
    return value
}

// Reads a float at the current offset.
fileprivate func readFloat(_ reader: inout (data: Data, offset: Data.Index)) throws -> Float {
    return Float(bitPattern: try readInt(&reader))
}

// Reads a float at the current offset.
fileprivate func readDouble(_ reader: inout (data: Data, offset: Data.Index)) throws -> Double {
    return Double(bitPattern: try readInt(&reader))
}

// Indicates if the offset has reached the end of the buffer.
fileprivate func hasRemaining(_ reader: (data: Data, offset: Data.Index)) -> Bool {
    return reader.offset < reader.data.count
}

// Define writer functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.  See the above discussion on Readers for details.

fileprivate func createWriter() -> [UInt8] {
    return []
}

fileprivate func writeBytes<S>(_ writer: inout [UInt8], _ byteArr: S) where S: Sequence, S.Element == UInt8 {
    writer.append(contentsOf: byteArr)
}

// Writes an integer in big-endian order.
//
// Warning: make sure what you are trying to write
// is in the correct type!
fileprivate func writeInt<T: FixedWidthInteger>(_ writer: inout [UInt8], _ value: T) {
    var value = value.bigEndian
    withUnsafeBytes(of: &value) { writer.append(contentsOf: $0) }
}

fileprivate func writeFloat(_ writer: inout [UInt8], _ value: Float) {
    writeInt(&writer, value.bitPattern)
}

fileprivate func writeDouble(_ writer: inout [UInt8], _ value: Double) {
    writeInt(&writer, value.bitPattern)
}

// Protocol for types that transfer other types across the FFI. This is
// analogous to the Rust trait of the same name.
fileprivate protocol FfiConverter {
    associatedtype FfiType
    associatedtype SwiftType

    static func lift(_ value: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType
    static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType
    static func write(_ value: SwiftType, into buf: inout [UInt8])
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
fileprivate protocol FfiConverterPrimitive: FfiConverter where FfiType == SwiftType { }

extension FfiConverterPrimitive {
    public static func lift(_ value: FfiType) throws -> SwiftType {
        return value
    }

    public static func lower(_ value: SwiftType) -> FfiType {
        return value
    }
}

// Types conforming to `FfiConverterRustBuffer` lift and lower into a `RustBuffer`.
// Used for complex types where it's hard to write a custom lift/lower.
fileprivate protocol FfiConverterRustBuffer: FfiConverter where FfiType == RustBuffer {}

extension FfiConverterRustBuffer {
    public static func lift(_ buf: RustBuffer) throws -> SwiftType {
        var reader = createReader(data: Data(rustBuffer: buf))
        let value = try read(from: &reader)
        if hasRemaining(reader) {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    public static func lower(_ value: SwiftType) -> RustBuffer {
          var writer = createWriter()
          write(value, into: &writer)
          return RustBuffer(bytes: writer)
    }
}
// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
fileprivate enum UniffiInternalError: LocalizedError {
    case bufferOverflow
    case incompleteData
    case unexpectedOptionalTag
    case unexpectedEnumCase
    case unexpectedNullPointer
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case unexpectedStaleHandle
    case rustPanic(_ message: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow: return "Reading the requested value would read past the end of the buffer"
        case .incompleteData: return "The buffer still has data after lifting its containing value"
        case .unexpectedOptionalTag: return "Unexpected optional tag; should be 0 or 1"
        case .unexpectedEnumCase: return "Raw enum value doesn't match any cases"
        case .unexpectedNullPointer: return "Raw pointer value was null"
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "CALL_ERROR but no errorClass specified"
        case .unexpectedStaleHandle: return "The object in the handle map has been dropped already"
        case let .rustPanic(message): return message
        }
    }
}

fileprivate extension NSLock {
    func withLock<T>(f: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try f()
    }
}

fileprivate let CALL_SUCCESS: Int8 = 0
fileprivate let CALL_ERROR: Int8 = 1
fileprivate let CALL_UNEXPECTED_ERROR: Int8 = 2
fileprivate let CALL_CANCELLED: Int8 = 3

fileprivate extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer.init(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    let neverThrow: ((RustBuffer) throws -> Never)? = nil
    return try makeRustCall(callback, errorHandler: neverThrow)
}

private func rustCallWithError<T, E: Swift.Error>(
    _ errorHandler: @escaping (RustBuffer) throws -> E,
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: errorHandler)
}

private func makeRustCall<T, E: Swift.Error>(
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T,
    errorHandler: ((RustBuffer) throws -> E)?
) throws -> T {
    uniffiEnsureInitialized()
    var callStatus = RustCallStatus.init()
    let returnedVal = callback(&callStatus)
    try uniffiCheckCallStatus(callStatus: callStatus, errorHandler: errorHandler)
    return returnedVal
}

private func uniffiCheckCallStatus<E: Swift.Error>(
    callStatus: RustCallStatus,
    errorHandler: ((RustBuffer) throws -> E)?
) throws {
    switch callStatus.code {
        case CALL_SUCCESS:
            return

        case CALL_ERROR:
            if let errorHandler = errorHandler {
                throw try errorHandler(callStatus.errorBuf)
            } else {
                callStatus.errorBuf.deallocate()
                throw UniffiInternalError.unexpectedRustCallError
            }

        case CALL_UNEXPECTED_ERROR:
            // When the rust code sees a panic, it tries to construct a RustBuffer
            // with the message.  But if that code panics, then it just sends back
            // an empty buffer.
            if callStatus.errorBuf.len > 0 {
                throw UniffiInternalError.rustPanic(try FfiConverterString.lift(callStatus.errorBuf))
            } else {
                callStatus.errorBuf.deallocate()
                throw UniffiInternalError.rustPanic("Rust panic")
            }

        case CALL_CANCELLED:
            fatalError("Cancellation not supported yet")

        default:
            throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

private func uniffiTraitInterfaceCall<T>(
    callStatus: UnsafeMutablePointer<RustCallStatus>,
    makeCall: () throws -> T,
    writeReturn: (T) -> ()
) {
    do {
        try writeReturn(makeCall())
    } catch let error {
        callStatus.pointee.code = CALL_UNEXPECTED_ERROR
        callStatus.pointee.errorBuf = FfiConverterString.lower(String(describing: error))
    }
}

private func uniffiTraitInterfaceCallWithError<T, E>(
    callStatus: UnsafeMutablePointer<RustCallStatus>,
    makeCall: () throws -> T,
    writeReturn: (T) -> (),
    lowerError: (E) -> RustBuffer
) {
    do {
        try writeReturn(makeCall())
    } catch let error as E {
        callStatus.pointee.code = CALL_ERROR
        callStatus.pointee.errorBuf = lowerError(error)
    } catch {
        callStatus.pointee.code = CALL_UNEXPECTED_ERROR
        callStatus.pointee.errorBuf = FfiConverterString.lower(String(describing: error))
    }
}
fileprivate class UniffiHandleMap<T> {
    private var map: [UInt64: T] = [:]
    private let lock = NSLock()
    private var currentHandle: UInt64 = 1

    func insert(obj: T) -> UInt64 {
        lock.withLock {
            let handle = currentHandle
            currentHandle += 1
            map[handle] = obj
            return handle
        }
    }

     func get(handle: UInt64) throws -> T {
        try lock.withLock {
            guard let obj = map[handle] else {
                throw UniffiInternalError.unexpectedStaleHandle
            }
            return obj
        }
    }

    @discardableResult
    func remove(handle: UInt64) throws -> T {
        try lock.withLock {
            guard let obj = map.removeValue(forKey: handle) else {
                throw UniffiInternalError.unexpectedStaleHandle
            }
            return obj
        }
    }

    var count: Int {
        get {
            map.count
        }
    }
}


// Public interface members begin here.


fileprivate struct FfiConverterInt64: FfiConverterPrimitive {
    typealias FfiType = Int64
    typealias SwiftType = Int64

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Int64 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: Int64, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

fileprivate struct FfiConverterBool : FfiConverter {
    typealias FfiType = Int8
    typealias SwiftType = Bool

    public static func lift(_ value: Int8) throws -> Bool {
        return value != 0
    }

    public static func lower(_ value: Bool) -> Int8 {
        return value ? 1 : 0
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Bool {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: Bool, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

fileprivate struct FfiConverterString: FfiConverter {
    typealias SwiftType = String
    typealias FfiType = RustBuffer

    public static func lift(_ value: RustBuffer) throws -> String {
        defer {
            value.deallocate()
        }
        if value.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: value.data!, count: Int(value.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    public static func lower(_ value: String) -> RustBuffer {
        return value.utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                return RustBuffer.from(buf)
            }
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> String {
        let len: Int32 = try readInt(&buf)
        return String(bytes: try readBytes(&buf, count: Int(len)), encoding: String.Encoding.utf8)!
    }

    public static func write(_ value: String, into buf: inout [UInt8]) {
        let len = Int32(value.utf8.count)
        writeInt(&buf, len)
        writeBytes(&buf, value.utf8)
    }
}




/**
 * The data needed to perform authorization using OAuth 2.0.
 */
public protocol OAuthAuthorizationDataProtocol : AnyObject {
    
    /**
     * The login URL to use for authorization.
     */
    func loginUrl()  -> String
    
}

/**
 * The data needed to perform authorization using OAuth 2.0.
 */
open class OAuthAuthorizationData:
    OAuthAuthorizationDataProtocol {
    fileprivate let pointer: UnsafeMutableRawPointer!

    /// Used to instantiate a [FFIObject] without an actual pointer, for fakes in tests, mostly.
    public struct NoPointer {
        public init() {}
    }

    // TODO: We'd like this to be `private` but for Swifty reasons,
    // we can't implement `FfiConverter` without making this `required` and we can't
    // make it `required` without making it `public`.
    required public init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    /// This constructor can be used to instantiate a fake object.
    /// - Parameter noPointer: Placeholder value so we can have a constructor separate from the default empty one that may be implemented for classes extending [FFIObject].
    ///
    /// - Warning:
    ///     Any object instantiated with this constructor cannot be passed to an actual Rust-backed object. Since there isn't a backing [Pointer] the FFI lower functions will crash.
    public init(noPointer: NoPointer) {
        self.pointer = nil
    }

    public func uniffiClonePointer() -> UnsafeMutableRawPointer {
        return try! rustCall { uniffi_matrix_sdk_fn_clone_oauthauthorizationdata(self.pointer, $0) }
    }
    // No primary constructor declared for this class.

    deinit {
        guard let pointer = pointer else {
            return
        }

        try! rustCall { uniffi_matrix_sdk_fn_free_oauthauthorizationdata(pointer, $0) }
    }

    

    
    /**
     * The login URL to use for authorization.
     */
open func loginUrl() -> String {
    return try!  FfiConverterString.lift(try! rustCall() {
    uniffi_matrix_sdk_fn_method_oauthauthorizationdata_login_url(self.uniffiClonePointer(),$0
    )
})
}
    

}

public struct FfiConverterTypeOAuthAuthorizationData: FfiConverter {

    typealias FfiType = UnsafeMutableRawPointer
    typealias SwiftType = OAuthAuthorizationData

    public static func lift(_ pointer: UnsafeMutableRawPointer) throws -> OAuthAuthorizationData {
        return OAuthAuthorizationData(unsafeFromRawPointer: pointer)
    }

    public static func lower(_ value: OAuthAuthorizationData) -> UnsafeMutableRawPointer {
        return value.uniffiClonePointer()
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> OAuthAuthorizationData {
        let v: UInt64 = try readInt(&buf)
        // The Rust code won't compile if a pointer won't fit in a UInt64.
        // We have to go via `UInt` because that's the thing that's the size of a pointer.
        let ptr = UnsafeMutableRawPointer(bitPattern: UInt(truncatingIfNeeded: v))
        if (ptr == nil) {
            throw UniffiInternalError.unexpectedNullPointer
        }
        return try lift(ptr!)
    }

    public static func write(_ value: OAuthAuthorizationData, into buf: inout [UInt8]) {
        // This fiddling is because `Int` is the thing that's the same size as a pointer.
        // The Rust code won't compile if a pointer won't fit in a `UInt64`.
        writeInt(&buf, UInt64(bitPattern: Int64(Int(bitPattern: lower(value)))))
    }
}




public func FfiConverterTypeOAuthAuthorizationData_lift(_ pointer: UnsafeMutableRawPointer) throws -> OAuthAuthorizationData {
    return try FfiConverterTypeOAuthAuthorizationData.lift(pointer)
}

public func FfiConverterTypeOAuthAuthorizationData_lower(_ value: OAuthAuthorizationData) -> UnsafeMutableRawPointer {
    return FfiConverterTypeOAuthAuthorizationData.lower(value)
}


/**
 * A set of common power levels required for various operations within a room,
 * that can be applied as a single operation. When updating these
 * settings, any levels that are `None` will remain unchanged.
 */
public struct RoomPowerLevelChanges {
    /**
     * The level required to ban a user.
     */
    public var ban: Int64?
    /**
     * The level required to invite a user.
     */
    public var invite: Int64?
    /**
     * The level required to kick a user.
     */
    public var kick: Int64?
    /**
     * The level required to redact an event.
     */
    public var redact: Int64?
    /**
     * The default level required to send message events.
     */
    public var eventsDefault: Int64?
    /**
     * The default level required to send state events.
     */
    public var stateDefault: Int64?
    /**
     * The default power level for every user in the room.
     */
    public var usersDefault: Int64?
    /**
     * The level required to change the room's name.
     */
    public var roomName: Int64?
    /**
     * The level required to change the room's avatar.
     */
    public var roomAvatar: Int64?
    /**
     * The level required to change the room's topic.
     */
    public var roomTopic: Int64?

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(
        /**
         * The level required to ban a user.
         */ban: Int64? = nil, 
        /**
         * The level required to invite a user.
         */invite: Int64? = nil, 
        /**
         * The level required to kick a user.
         */kick: Int64? = nil, 
        /**
         * The level required to redact an event.
         */redact: Int64? = nil, 
        /**
         * The default level required to send message events.
         */eventsDefault: Int64? = nil, 
        /**
         * The default level required to send state events.
         */stateDefault: Int64? = nil, 
        /**
         * The default power level for every user in the room.
         */usersDefault: Int64? = nil, 
        /**
         * The level required to change the room's name.
         */roomName: Int64? = nil, 
        /**
         * The level required to change the room's avatar.
         */roomAvatar: Int64? = nil, 
        /**
         * The level required to change the room's topic.
         */roomTopic: Int64? = nil) {
        self.ban = ban
        self.invite = invite
        self.kick = kick
        self.redact = redact
        self.eventsDefault = eventsDefault
        self.stateDefault = stateDefault
        self.usersDefault = usersDefault
        self.roomName = roomName
        self.roomAvatar = roomAvatar
        self.roomTopic = roomTopic
    }
}



extension RoomPowerLevelChanges: Equatable, Hashable {
    public static func ==(lhs: RoomPowerLevelChanges, rhs: RoomPowerLevelChanges) -> Bool {
        if lhs.ban != rhs.ban {
            return false
        }
        if lhs.invite != rhs.invite {
            return false
        }
        if lhs.kick != rhs.kick {
            return false
        }
        if lhs.redact != rhs.redact {
            return false
        }
        if lhs.eventsDefault != rhs.eventsDefault {
            return false
        }
        if lhs.stateDefault != rhs.stateDefault {
            return false
        }
        if lhs.usersDefault != rhs.usersDefault {
            return false
        }
        if lhs.roomName != rhs.roomName {
            return false
        }
        if lhs.roomAvatar != rhs.roomAvatar {
            return false
        }
        if lhs.roomTopic != rhs.roomTopic {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ban)
        hasher.combine(invite)
        hasher.combine(kick)
        hasher.combine(redact)
        hasher.combine(eventsDefault)
        hasher.combine(stateDefault)
        hasher.combine(usersDefault)
        hasher.combine(roomName)
        hasher.combine(roomAvatar)
        hasher.combine(roomTopic)
    }
}


public struct FfiConverterTypeRoomPowerLevelChanges: FfiConverterRustBuffer {
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> RoomPowerLevelChanges {
        return
            try RoomPowerLevelChanges(
                ban: FfiConverterOptionInt64.read(from: &buf), 
                invite: FfiConverterOptionInt64.read(from: &buf), 
                kick: FfiConverterOptionInt64.read(from: &buf), 
                redact: FfiConverterOptionInt64.read(from: &buf), 
                eventsDefault: FfiConverterOptionInt64.read(from: &buf), 
                stateDefault: FfiConverterOptionInt64.read(from: &buf), 
                usersDefault: FfiConverterOptionInt64.read(from: &buf), 
                roomName: FfiConverterOptionInt64.read(from: &buf), 
                roomAvatar: FfiConverterOptionInt64.read(from: &buf), 
                roomTopic: FfiConverterOptionInt64.read(from: &buf)
        )
    }

    public static func write(_ value: RoomPowerLevelChanges, into buf: inout [UInt8]) {
        FfiConverterOptionInt64.write(value.ban, into: &buf)
        FfiConverterOptionInt64.write(value.invite, into: &buf)
        FfiConverterOptionInt64.write(value.kick, into: &buf)
        FfiConverterOptionInt64.write(value.redact, into: &buf)
        FfiConverterOptionInt64.write(value.eventsDefault, into: &buf)
        FfiConverterOptionInt64.write(value.stateDefault, into: &buf)
        FfiConverterOptionInt64.write(value.usersDefault, into: &buf)
        FfiConverterOptionInt64.write(value.roomName, into: &buf)
        FfiConverterOptionInt64.write(value.roomAvatar, into: &buf)
        FfiConverterOptionInt64.write(value.roomTopic, into: &buf)
    }
}


public func FfiConverterTypeRoomPowerLevelChanges_lift(_ buf: RustBuffer) throws -> RoomPowerLevelChanges {
    return try FfiConverterTypeRoomPowerLevelChanges.lift(buf)
}

public func FfiConverterTypeRoomPowerLevelChanges_lower(_ value: RoomPowerLevelChanges) -> RustBuffer {
    return FfiConverterTypeRoomPowerLevelChanges.lower(value)
}

// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
/**
 * Settings for end-to-end encryption features.
 */

public enum BackupDownloadStrategy {
    
    /**
     * Automatically download all room keys from the backup when the backup
     * recovery key has been received. The backup recovery key can be received
     * in two ways:
     *
     * 1. Received as a `m.secret.send` to-device event, after a successful
     * interactive verification.
     * 2. Imported from secret storage (4S) using the
     * [`SecretStore::import_secrets()`] method.
     *
     * [`SecretStore::import_secrets()`]: crate::encryption::secret_storage::SecretStore::import_secrets
     */
    case oneShot
    /**
     * Attempt to download a single room key if an event fails to be decrypted.
     */
    case afterDecryptionFailure
    /**
     * Don't download any room keys automatically. The user can manually
     * download room keys using the [`Backups::download_room_key()`] methods.
     *
     * This is the default option.
     */
    case manual
}


public struct FfiConverterTypeBackupDownloadStrategy: FfiConverterRustBuffer {
    typealias SwiftType = BackupDownloadStrategy

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> BackupDownloadStrategy {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        
        case 1: return .oneShot
        
        case 2: return .afterDecryptionFailure
        
        case 3: return .manual
        
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: BackupDownloadStrategy, into buf: inout [UInt8]) {
        switch value {
        
        
        case .oneShot:
            writeInt(&buf, Int32(1))
        
        
        case .afterDecryptionFailure:
            writeInt(&buf, Int32(2))
        
        
        case .manual:
            writeInt(&buf, Int32(3))
        
        }
    }
}


public func FfiConverterTypeBackupDownloadStrategy_lift(_ buf: RustBuffer) throws -> BackupDownloadStrategy {
    return try FfiConverterTypeBackupDownloadStrategy.lift(buf)
}

public func FfiConverterTypeBackupDownloadStrategy_lower(_ value: BackupDownloadStrategy) -> RustBuffer {
    return FfiConverterTypeBackupDownloadStrategy.lower(value)
}



extension BackupDownloadStrategy: Equatable, Hashable {}



// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
/**
 * Current state of a [`Paginator`].
 */

public enum PaginatorState {
    
    /**
     * The initial state of the paginator.
     */
    case initial
    /**
     * The paginator is fetching the target initial event.
     */
    case fetchingTargetEvent
    /**
     * The target initial event could be found, zero or more paginations have
     * happened since then, and the paginator is at rest now.
     */
    case idle
    /**
     * The paginator is… paginating one direction or another.
     */
    case paginating
}


public struct FfiConverterTypePaginatorState: FfiConverterRustBuffer {
    typealias SwiftType = PaginatorState

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> PaginatorState {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        
        case 1: return .initial
        
        case 2: return .fetchingTargetEvent
        
        case 3: return .idle
        
        case 4: return .paginating
        
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: PaginatorState, into buf: inout [UInt8]) {
        switch value {
        
        
        case .initial:
            writeInt(&buf, Int32(1))
        
        
        case .fetchingTargetEvent:
            writeInt(&buf, Int32(2))
        
        
        case .idle:
            writeInt(&buf, Int32(3))
        
        
        case .paginating:
            writeInt(&buf, Int32(4))
        
        }
    }
}


public func FfiConverterTypePaginatorState_lift(_ buf: RustBuffer) throws -> PaginatorState {
    return try FfiConverterTypePaginatorState.lift(buf)
}

public func FfiConverterTypePaginatorState_lower(_ value: PaginatorState) -> RustBuffer {
    return FfiConverterTypePaginatorState.lower(value)
}



extension PaginatorState: Equatable, Hashable {}




/**
 * The error type for failures while trying to log in a new device using a QR
 * code.
 */
public enum QrCodeLoginError {

    
    
    /**
     * An error happened while we were communicating with the OAuth 2.0
     * authorization server.
     */
    case OAuth(message: String)
    
    /**
     * The other device has signaled to us that the login has failed.
     */
    case LoginFailure(message: String)
    
    /**
     * An unexpected message was received from the other device.
     */
    case UnexpectedMessage(message: String)
    
    /**
     * An error happened while exchanging messages with the other device.
     */
    case SecureChannel(message: String)
    
    /**
     * The cross-process refresh lock failed to be initialized.
     */
    case CrossProcessRefreshLock(message: String)
    
    /**
     * An error happened while we were trying to discover our user and device
     * ID, after we have acquired an access token from the OAuth 2.0
     * authorization server.
     */
    case UserIdDiscovery(message: String)
    
    /**
     * We failed to set the session tokens after we figured out our device and
     * user IDs.
     */
    case SessionTokens(message: String)
    
    /**
     * The device keys failed to be uploaded after we successfully logged in.
     */
    case DeviceKeyUpload(message: String)
    
    /**
     * The secrets bundle we received from the existing device failed to be
     * imported.
     */
    case SecretImport(message: String)
    
}


public struct FfiConverterTypeQRCodeLoginError: FfiConverterRustBuffer {
    typealias SwiftType = QrCodeLoginError

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> QrCodeLoginError {
        let variant: Int32 = try readInt(&buf)
        switch variant {

        

        
        case 1: return .OAuth(
            message: try FfiConverterString.read(from: &buf)
        )
        
        case 2: return .LoginFailure(
            message: try FfiConverterString.read(from: &buf)
        )
        
        case 3: return .UnexpectedMessage(
            message: try FfiConverterString.read(from: &buf)
        )
        
        case 4: return .SecureChannel(
            message: try FfiConverterString.read(from: &buf)
        )
        
        case 5: return .CrossProcessRefreshLock(
            message: try FfiConverterString.read(from: &buf)
        )
        
        case 6: return .UserIdDiscovery(
            message: try FfiConverterString.read(from: &buf)
        )
        
        case 7: return .SessionTokens(
            message: try FfiConverterString.read(from: &buf)
        )
        
        case 8: return .DeviceKeyUpload(
            message: try FfiConverterString.read(from: &buf)
        )
        
        case 9: return .SecretImport(
            message: try FfiConverterString.read(from: &buf)
        )
        

        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: QrCodeLoginError, into buf: inout [UInt8]) {
        switch value {

        

        
        case .OAuth(_ /* message is ignored*/):
            writeInt(&buf, Int32(1))
        case .LoginFailure(_ /* message is ignored*/):
            writeInt(&buf, Int32(2))
        case .UnexpectedMessage(_ /* message is ignored*/):
            writeInt(&buf, Int32(3))
        case .SecureChannel(_ /* message is ignored*/):
            writeInt(&buf, Int32(4))
        case .CrossProcessRefreshLock(_ /* message is ignored*/):
            writeInt(&buf, Int32(5))
        case .UserIdDiscovery(_ /* message is ignored*/):
            writeInt(&buf, Int32(6))
        case .SessionTokens(_ /* message is ignored*/):
            writeInt(&buf, Int32(7))
        case .DeviceKeyUpload(_ /* message is ignored*/):
            writeInt(&buf, Int32(8))
        case .SecretImport(_ /* message is ignored*/):
            writeInt(&buf, Int32(9))

        
        }
    }
}


extension QrCodeLoginError: Equatable, Hashable {}

extension QrCodeLoginError: Foundation.LocalizedError {
    public var errorDescription: String? {
        String(reflecting: self)
    }
}

// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
/**
 * The role of a member in a room.
 */

public enum RoomMemberRole {
    
    /**
     * The member is an administrator.
     */
    case administrator
    /**
     * The member is a moderator.
     */
    case moderator
    /**
     * The member is a regular user.
     */
    case user
}


public struct FfiConverterTypeRoomMemberRole: FfiConverterRustBuffer {
    typealias SwiftType = RoomMemberRole

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> RoomMemberRole {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        
        case 1: return .administrator
        
        case 2: return .moderator
        
        case 3: return .user
        
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: RoomMemberRole, into buf: inout [UInt8]) {
        switch value {
        
        
        case .administrator:
            writeInt(&buf, Int32(1))
        
        
        case .moderator:
            writeInt(&buf, Int32(2))
        
        
        case .user:
            writeInt(&buf, Int32(3))
        
        }
    }
}


public func FfiConverterTypeRoomMemberRole_lift(_ buf: RustBuffer) throws -> RoomMemberRole {
    return try FfiConverterTypeRoomMemberRole.lift(buf)
}

public func FfiConverterTypeRoomMemberRole_lower(_ value: RoomMemberRole) -> RustBuffer {
    return FfiConverterTypeRoomMemberRole.lower(value)
}



extension RoomMemberRole: Equatable, Hashable {}



// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
/**
 * Status for the back-pagination on a room event cache.
 */

public enum RoomPaginationStatus {
    
    /**
     * No back-pagination is happening right now.
     */
    case idle(
        /**
         * Have we hit the start of the timeline, i.e. back-paginating wouldn't
         * have any effect?
         */hitTimelineStart: Bool
    )
    /**
     * Back-pagination is already running in the background.
     */
    case paginating
}


public struct FfiConverterTypeRoomPaginationStatus: FfiConverterRustBuffer {
    typealias SwiftType = RoomPaginationStatus

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> RoomPaginationStatus {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        
        case 1: return .idle(hitTimelineStart: try FfiConverterBool.read(from: &buf)
        )
        
        case 2: return .paginating
        
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: RoomPaginationStatus, into buf: inout [UInt8]) {
        switch value {
        
        
        case let .idle(hitTimelineStart):
            writeInt(&buf, Int32(1))
            FfiConverterBool.write(hitTimelineStart, into: &buf)
            
        
        case .paginating:
            writeInt(&buf, Int32(2))
        
        }
    }
}


public func FfiConverterTypeRoomPaginationStatus_lift(_ buf: RustBuffer) throws -> RoomPaginationStatus {
    return try FfiConverterTypeRoomPaginationStatus.lift(buf)
}

public func FfiConverterTypeRoomPaginationStatus_lower(_ value: RoomPaginationStatus) -> RustBuffer {
    return FfiConverterTypeRoomPaginationStatus.lower(value)
}



extension RoomPaginationStatus: Equatable, Hashable {}



fileprivate struct FfiConverterOptionInt64: FfiConverterRustBuffer {
    typealias SwiftType = Int64?

    public static func write(_ value: SwiftType, into buf: inout [UInt8]) {
        guard let value = value else {
            writeInt(&buf, Int8(0))
            return
        }
        writeInt(&buf, Int8(1))
        FfiConverterInt64.write(value, into: &buf)
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType {
        switch try readInt(&buf) as Int8 {
        case 0: return nil
        case 1: return try FfiConverterInt64.read(from: &buf)
        default: throw UniffiInternalError.unexpectedOptionalTag
        }
    }
}

private enum InitializationResult {
    case ok
    case contractVersionMismatch
    case apiChecksumMismatch
}
// Use a global variable to perform the versioning checks. Swift ensures that
// the code inside is only computed once.
private var initializationResult: InitializationResult = {
    // Get the bindings contract version from our ComponentInterface
    let bindings_contract_version = 26
    // Get the scaffolding contract version by calling the into the dylib
    let scaffolding_contract_version = ffi_matrix_sdk_uniffi_contract_version()
    if bindings_contract_version != scaffolding_contract_version {
        return InitializationResult.contractVersionMismatch
    }
    if (uniffi_matrix_sdk_checksum_method_oauthauthorizationdata_login_url() != 25566) {
        return InitializationResult.apiChecksumMismatch
    }

    return InitializationResult.ok
}()

private func uniffiEnsureInitialized() {
    switch initializationResult {
    case .ok:
        break
    case .contractVersionMismatch:
        fatalError("UniFFI contract version mismatch: try cleaning and rebuilding your project")
    case .apiChecksumMismatch:
        fatalError("UniFFI API checksum mismatch: try cleaning and rebuilding your project")
    }
}

// swiftlint:enable all