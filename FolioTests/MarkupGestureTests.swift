import Foundation
import PDFKit
import Testing

/// Highlight is a command on the current selection, not a pen that marks every drag.
@MainActor
@Suite struct MarkupGestureTests {
    @Test func highlightDoesNotMarkWhenTheSelectionEnds() {
        #expect(!AnnotationTool.highlight.marksSelectionOnMouseUp)
        #expect(!AnnotationTool.select.marksSelectionOnMouseUp)
        #expect(!AnnotationTool.note.marksSelectionOnMouseUp)
        #expect(!AnnotationTool.text.marksSelectionOnMouseUp)
        #expect(!AnnotationTool.ink.marksSelectionOnMouseUp)
    }

    @Test func underlineAndStrikeStillMarkWhenTheSelectionEnds() {
        #expect(AnnotationTool.underline.marksSelectionOnMouseUp)
        #expect(AnnotationTool.strikeOut.marksSelectionOnMouseUp)
    }

    @Test func highlightRemainsAMarkupKindForTheShortcut() {
        #expect(AnnotationTool.highlight.markupType == .highlight)
        #expect(AnnotationTool.highlight.keyEquivalent == "h")
    }

    @Test func defaultHighlightShortcutIsShiftCommandH() {
        let shortcut = HighlightShortcut.default
        #expect(shortcut.display == "⇧⌘H")
        #expect(shortcut.storage == "h|1179648")
        #expect(shortcut.isUsable)
        #expect(HighlightShortcut(storage: shortcut.storage) == shortcut)
    }

    @Test func shortcutWithoutCommandOrControlIsRejected() {
        #expect(HighlightShortcut(storage: "h|131072") == nil)
        #expect(HighlightShortcut(storage: "h|0") == nil)
        #expect(HighlightShortcut(storage: "not-a-shortcut") == nil)
        #expect(!HighlightShortcut(key: "h", modifiers: [.option]).isUsable)
        #expect(HighlightShortcut(key: "h", modifiers: [.control]).display == "⌃H")
    }

    @Test func shortcutDisplayRoundTripAndConflicts() {
        let all = HighlightShortcut(key: "k", modifiers: [.control, .option, .shift, .command])
        #expect(all.display == "⌃⌥⇧⌘K")
        #expect(all.storage == "k|1966080")
        let f1 = HighlightShortcut(key: HighlightShortcut.key(forKeyCode: 122, unmodified: "")!, modifiers: [.command])
        #expect(f1.display == "⌘F1")
        #expect(HighlightShortcut.key(forKeyCode: 51, unmodified: "") == "\u{8}")
        #expect(HighlightShortcut(key: "\u{8}", modifiers: [.command]).display == "⌘⌫")
        #expect(HighlightShortcut(key: " ", modifiers: [.command, .shift]).display == "⇧⌘空格")
        #expect(HighlightShortcut.key(forKeyCode: 126, unmodified: "") == "\u{F700}")
        #expect(HighlightShortcut(key: "\u{F700}", modifiers: [.command]).display == "⌘↑")
        #expect(HighlightShortcut.key(forKeyCode: 53, unmodified: "\u{1b}") == nil)
        #expect(HighlightShortcut.key(forKeyCode: 4, unmodified: "H") == "h")
        #expect(HighlightShortcut.key(forKeyCode: 18, unmodified: "1") == "1")

        let hide = HighlightShortcut.Claim(key: "h", modifiers: [.command], title: "隐藏 Folio")
        #expect(HighlightShortcut(key: "h", modifiers: [.command]).conflictingTitle(among: [hide]) == "隐藏 Folio")
        #expect(HighlightShortcut.default.conflictingTitle(among: [hide]) == nil)
        let redo = HighlightShortcut.Claim(key: "Z", modifiers: [.command], title: "重做")
        #expect(HighlightShortcut(key: "z", modifiers: [.command, .shift]).conflictingTitle(among: [redo]) == "重做")
    }

    @Test func storedShortcutFallsBackToTheDefault() {
        let name = "com.nnqc.Folio.shortcutTests"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        #expect(HighlightShortcut.stored(in: defaults) == .default)
        defaults.set("k|1966080", forKey: HighlightShortcut.defaultsKey)
        #expect(HighlightShortcut.stored(in: defaults).display == "⌃⌥⇧⌘K")
        defaults.set("h|131072", forKey: HighlightShortcut.defaultsKey)
        #expect(HighlightShortcut.stored(in: defaults) == .default)
        defaults.removePersistentDomain(forName: name)
    }
}
