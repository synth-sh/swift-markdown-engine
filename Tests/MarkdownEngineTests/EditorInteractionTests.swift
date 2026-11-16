import AppKit
import SwiftUI
import Testing
@testable import MarkdownEngine

@MainActor
struct EditorInteractionTests {
    init() {
        _ = NSApplication.shared
    }

    @Test func keyHookCanConsumeReturn() throws {
        let view = NativeTextView(frame: .zero)
        view.string = "Draft"
        view.isEditable = true
        var returns = 0
        view.interaction.key = { _, event in
            guard event.keyCode == 36 else { return false }
            returns += 1
            return true
        }
        let event = try #require(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
            context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36
        ))
        view.keyDown(with: event)
        #expect(returns == 1)
        #expect(view.string == "Draft")
    }

    @Test func hostCanHandleReadOnlyLinksAndIdentifyCodeSelection() async throws {
        let coordinator = NativeTextViewWrapper(text: .constant("")).makeCoordinator()
        let view = NativeTextView(frame: .zero)
        view.isEditable = false
        view.delegate = coordinator
        view.string = "A `code` span"
        view.setSelectedRange(NSRange(location: 4, length: 0))
        var reportedCode = false
        var opened: URL?
        view.interaction.selection = { _, inCode in reportedCode = inCode }
        view.interaction.openURL = { opened = $0; return true }
        coordinator.reportHostSelection(in: view)
        let url = try #require(URL(string: "demo://example"))
        #expect(coordinator.textView(view, clickedOnLink: url, at: 0))
        #expect(!reportedCode)
        await flushSelectionReports()
        #expect(reportedCode)
        #expect(opened == url)
    }

    @Test func hostSelectionIsCoalescedAfterDocumentRebuild() async {
        let source = "A `code` span"
        let coordinator = NativeTextViewWrapper(text: .constant(source)).makeCoordinator()
        let view = NativeTextView(frame: .zero)
        view.delegate = coordinator
        var ranges: [NSRange] = []
        var codeFlags: [Bool] = []
        view.interaction.selection = { view, inCode in
            ranges.append(view.selectedRange())
            codeFlags.append(inCode)
        }
        let caret = NSRange(location: 4, length: 0)
        coordinator.rebuildTextStorageAndStyle(view, from: source, restoring: caret)
        #expect(ranges.isEmpty)
        await flushSelectionReports()
        #expect(ranges == [caret])
        #expect(codeFlags == [true])
    }

    @Test func backticksInSeparateListItemsDoNotFormCode() {
        let source = "- `a\n- b`\n- 🐈 `c`"
        let expected = (source as NSString).range(of: "`c`")
        #expect(MarkdownSource.codeRanges(in: source) == [expected])
    }

    private func flushSelectionReports() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

extension EditorInteractionTests {
    @Test func readOnlyMarkdownFillsItsHeightAndKeepsLinksSelectable() throws {
        let paragraph = String(repeating: "A paragraph that should wrap at a narrow transcript width. ", count: 8)
        let source = """
        ## A transcript heading

        **Bold**, `inline code`, and [@project notes.txt](synth-file://project/project%20notes.txt).

        | Name | Status |
        | --- | --- |
        | Editing | Done |

        ```swift
        let message = "hello world"
        ```

        \(paragraph)
        """
        let stack = HeightBehaviorStack(
            viewport: NSSize(width: 330, height: 320), heightBehavior: .fitsContent
        )
        let editor = stack.textView
        let wrapper = NativeTextViewWrapper(text: .constant(source), isEditable: false)
        let coordinator = wrapper.makeCoordinator()
        editor.delegate = coordinator
        editor.isEditable = false
        editor.isSelectable = true
        coordinator.rebuildTextStorageAndStyle(editor, from: source, invalidateLayout: true)
        editor.recalcOverscroll(for: stack.scrollView)

        let storage = try #require(editor.textStorage)
        let linkRange = (source as NSString).range(of: "@project notes.txt")
        let destination = storage.attribute(.link, at: linkRange.location, effectiveRange: nil) as? URL
        #expect(destination?.scheme == "synth-file")
        #expect(editor.isSelectable)
        #expect(stack.container.scrollableContentHeight > 220)
        #expect(MarkdownSource.codeRanges(in: source).count == 2)
    }
}
