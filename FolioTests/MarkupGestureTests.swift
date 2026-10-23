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
}
