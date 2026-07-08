import AppKit

/// Small helper around the macOS general pasteboard.
enum Clipboard {
    static func copy(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    /// The current plain-text contents of the clipboard, if any.
    static func string() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}
