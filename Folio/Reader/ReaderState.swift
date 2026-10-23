import AppKit
import Observation
import PDFKit

/// Annotation tools of the reader (READER-04).
enum AnnotationTool: Int, CaseIterable {
    case select, highlight, underline, strikeOut, note, text, ink

    var title: String {
        switch self {
        case .select: String(localized: "选择")
        case .highlight: String(localized: "高亮")
        case .underline: String(localized: "下划线")
        case .strikeOut: String(localized: "删除线")
        case .note: String(localized: "便签")
        case .text: String(localized: "文本框")
        case .ink: String(localized: "手绘")
        }
    }

    var symbol: String {
        switch self {
        case .select: "cursorarrow"
        case .highlight: "highlighter"
        case .underline: "underline"
        case .strikeOut: "strikethrough"
        case .note: "note.text"
        case .text: "character.textbox"
        case .ink: "scribble"
        }
    }

    /// ⌃⌘ shortcut in the 批注 menu.
    var keyEquivalent: String {
        switch self {
        case .select: "0"
        case .highlight: "h"
        case .underline: "u"
        case .strikeOut: "k"
        case .note: "n"
        case .text: "t"
        case .ink: "d"
        }
    }

    /// Tools that turn a text selection into markup.
    var markupType: PDFAnnotationSubtype? {
        switch self {
        case .highlight: .highlight
        case .underline: .underline
        case .strikeOut: .strikeOut
        default: nil
        }
    }

    /// Underline and strike-out mark the selection when the mouse goes up.
    /// Highlight does not: the selection stays available to copy until the highlight shortcut.
    var marksSelectionOnMouseUp: Bool {
        switch self {
        case .underline, .strikeOut: true
        default: false
        }
    }
}

/// Pages of the reader sidebar (READER-02).
enum ReaderSidebarTab: Int, CaseIterable {
    case thumbnails, outline, annotations, search

    var title: String {
        switch self {
        case .thumbnails: String(localized: "缩略图")
        case .outline: String(localized: "目录")
        case .annotations: String(localized: "批注")
        case .search: String(localized: "查找结果")
        }
    }

    var symbol: String {
        switch self {
        case .thumbnails: "square.grid.2x2"
        case .outline: "list.bullet.indent"
        case .annotations: "highlighter"
        case .search: "magnifyingglass"
        }
    }
}

/// One annotation as listed in the sidebar.
struct AnnotationRow: Identifiable, Equatable {
    let id: ObjectIdentifier
    let pageIndex: Int
    let kind: String
    let color: NSColor
    let text: String
    let comment: String
    /// "译文" when the annotation lives on the parallel translation; empty for the original.
    var pane: String = ""
}

/// One find result as listed in the sidebar.
struct SearchHit: Identifiable, Equatable {
    let id: Int
    let pageIndex: Int
    let pageLabel: String
    let context: AttributedString
}

/// An entry of the PDF outline.
struct OutlineRow: Identifiable {
    let id: Int
    let title: String
    let pageIndex: Int?
    let children: [OutlineRow]?
}

/// The keystroke that highlights the current selection. Stored as `key|modifierMask`
/// (⇧⌘H is `h|1179648`). Command or Control is required, so a bare letter still types.
struct HighlightShortcut: Equatable {
    struct Modifiers: OptionSet {
        var rawValue: UInt
        static let shift = Modifiers(rawValue: 1 << 17)
        static let control = Modifiers(rawValue: 1 << 18)
        static let option = Modifiers(rawValue: 1 << 19)
        static let command = Modifiers(rawValue: 1 << 20)
        static let recorded: Modifiers = [.shift, .control, .option, .command]
    }

    /// A menu item the shortcut must not reuse. An uppercase key implies Shift.
    struct Claim: Equatable {
        var key: String
        var modifiers: Modifiers
        var title: String
    }

    static let defaultsKey = "highlightShortcut"
    static let `default` = HighlightShortcut(key: "h", modifiers: [.command, .shift])
    /// The shortcut currently in effect. AppSettings updates this; menus read it.
    static var current = HighlightShortcut.default

    var key: String
    var modifiers: Modifiers

    init(key: String, modifiers: Modifiers) {
        self.key = Self.normalizedKey(key)
        self.modifiers = modifiers.intersection(.recorded)
    }

    init?(storage: String) {
        guard let separator = storage.lastIndex(of: "|") else { return nil }
        let key = String(storage[..<separator])
        let raw = String(storage[storage.index(after: separator)...])
        guard let value = UInt(raw) else { return nil }
        self.init(key: key, modifiers: Modifiers(rawValue: value))
        if !isUsable { return nil }
    }

    var isUsable: Bool {
        (modifiers.contains(.command) || modifiers.contains(.control)) && Self.isAcceptableKey(key)
    }

    var storage: String { "\(key)|\(modifiers.rawValue)" }

    /// ⌃⌥⇧⌘, then the key, matching the menu bar.
    var display: String { modifierSymbols + keyLabel }

    func conflictingTitle(among claims: [Claim]) -> String? {
        let mine = Self.canonical(key: key, modifiers: modifiers)
        for claim in claims {
            if Self.canonical(key: claim.key, modifiers: claim.modifiers) == mine { return claim.title }
        }
        return nil
    }

    static func stored(in defaults: UserDefaults = .standard) -> HighlightShortcut {
        guard let raw = defaults.string(forKey: defaultsKey), let shortcut = HighlightShortcut(storage: raw) else {
            return .default
        }
        return shortcut
    }

    /// The menu key equivalent for a hardware key, or nil for Escape and keys that cannot be a shortcut.
    static func key(forKeyCode code: UInt16, unmodified: String) -> String? {
        switch code {
        case 36, 76: return "\r"
        case 48: return "\t"
        case 49: return " "
        case 51: return "\u{8}"
        case 53: return nil
        case 115: return "\u{F729}"
        case 116: return "\u{F72C}"
        case 117: return "\u{F728}"
        case 119: return "\u{F72B}"
        case 121: return "\u{F72D}"
        case 123: return "\u{F702}"
        case 124: return "\u{F703}"
        case 125: return "\u{F701}"
        case 126: return "\u{F700}"
        case 122: return functionKey(1)
        case 120: return functionKey(2)
        case 99: return functionKey(3)
        case 118: return functionKey(4)
        case 96: return functionKey(5)
        case 97: return functionKey(6)
        case 98: return functionKey(7)
        case 100: return functionKey(8)
        case 101: return functionKey(9)
        case 109: return functionKey(10)
        case 103: return functionKey(11)
        case 111: return functionKey(12)
        default: return normalizedPrintable(unmodified)
        }
    }

    private var modifierSymbols: String {
        var symbols = ""
        if modifiers.contains(.control) { symbols.append("⌃") }
        if modifiers.contains(.option) { symbols.append("⌥") }
        if modifiers.contains(.shift) { symbols.append("⇧") }
        if modifiers.contains(.command) { symbols.append("⌘") }
        return symbols
    }

    private var keyLabel: String {
        guard let scalar = key.unicodeScalars.first, key.unicodeScalars.count == 1 else { return key.uppercased() }
        switch scalar.value {
        case 0x08, 0x7F: return "⌫"
        case 0x09: return "⇥"
        case 0x0D, 0x03: return "↩"
        case 0x20: return String(localized: "空格")
        case 0xF700: return "↑"
        case 0xF701: return "↓"
        case 0xF702: return "←"
        case 0xF703: return "→"
        case 0xF728: return "⌦"
        case 0xF729: return "↖"
        case 0xF72B: return "↘"
        case 0xF72C: return "⇞"
        case 0xF72D: return "⇟"
        case 0xF704...0xF70F: return "F\(scalar.value - 0xF704 + 1)"
        default: return key.uppercased()
        }
    }

    private static func functionKey(_ number: Int) -> String {
        String(UnicodeScalar(UInt32(0xF703 + number))!)
    }

    private static func normalizedPrintable(_ raw: String) -> String? {
        guard raw.unicodeScalars.count == 1, let scalar = raw.unicodeScalars.first else { return nil }
        guard scalar.value >= 32, scalar.value < 0xF700 else { return nil }
        return normalizedKey(String(scalar))
    }

    private static func normalizedKey(_ key: String) -> String {
        let lower = key.lowercased()
        return lower.unicodeScalars.count == key.unicodeScalars.count ? lower : key
    }

    private static func isAcceptableKey(_ key: String) -> Bool {
        guard key.unicodeScalars.count == 1, let value = key.unicodeScalars.first?.value else { return false }
        if value == 0x08 || value == 0x09 || value == 0x0D || value == 0x20 || value == 0x7F { return true }
        if (0xF700...0xF8FF).contains(value) { return true }
        return value >= 32 && value < 0xF700
    }

    private static func canonical(key: String, modifiers: Modifiers) -> (String, Modifiers) {
        var mods = modifiers.intersection(.recorded)
        let normalized = normalizedKey(key)
        if normalized != key { mods.insert(.shift) }
        return (normalized, mods)
    }
}

/// What the reader window's SwiftUI parts (sidebar, notes panel) read and the AppKit side writes.
@Observable
final class ReaderState {
    var tool = AnnotationTool.select
    var color: AnnotationColor
    var sidebarTab = ReaderSidebarTab.thumbnails
    var pageIndex = 0
    var pageCount = 0
    var annotations: [AnnotationRow] = []
    var outline: [OutlineRow] = []
    var searchQuery = ""
    var searchHits: [SearchHit] = []
    var isSearching = false
    var currentHit: Int?
    /// The mono/dual translation shown next to the original, when 对照阅读 is on (READER-10).
    var parallelFileId: String?
    /// Symbols for the highlight shortcut, for example "⇧⌘H".
    var highlightShortcutLabel: String

    init(color: AnnotationColor, highlightShortcutLabel: String = HighlightShortcut.default.display) {
        self.color = color
        self.highlightShortcutLabel = highlightShortcutLabel
    }
}
