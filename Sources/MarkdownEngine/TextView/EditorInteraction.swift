import AppKit

/// Host callbacks run against the current native document, before default input handling.
/// Return true from a handler to consume the operation. Marked text bypasses key handling.
public struct EditorInteraction {
    public var key: ((NSTextView, NSEvent) -> Bool)?
    public var paste: ((NSTextView, NSPasteboard) -> Bool)?
    /// Reports the native selection and whether its caret is in inline or fenced code.
    public var selection: ((NSTextView, Bool) -> Void)?
    public var openURL: ((URL) -> Bool)?

    public init(
        key: ((NSTextView, NSEvent) -> Bool)? = nil,
        paste: ((NSTextView, NSPasteboard) -> Bool)? = nil,
        selection: ((NSTextView, Bool) -> Void)? = nil,
        openURL: ((URL) -> Bool)? = nil
    ) {
        self.key = key
        self.paste = paste
        self.selection = selection
        self.openURL = openURL
    }
}
