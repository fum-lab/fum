import AppKit
import SwiftUI

struct PlainTextChange {
  let range: NSRange
  let replacement: String
}

struct PlainTextEditor: NSViewRepresentable {
  let text: String
  let onChange: (String, NSRange, PlainTextChange?) -> Void
  let onSelectionChange: (NSRange) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onChange: onChange, onSelectionChange: onSelectionChange)
  }

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder

    let textView = NSTextView(frame: scrollView.bounds)
    textView.autoresizingMask = [.width]
    textView.isRichText = false
    textView.importsGraphics = false
    textView.allowsUndo = true
    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isAutomaticDashSubstitutionEnabled = false
    textView.isAutomaticTextReplacementEnabled = false
    textView.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
    textView.textContainerInset = NSSize(width: 18, height: 18)
    textView.textContainer?.widthTracksTextView = true
    textView.textContainer?.containerSize = NSSize(
      width: scrollView.contentSize.width,
      height: .greatestFiniteMagnitude
    )
    textView.string = text
    textView.delegate = context.coordinator
    scrollView.documentView = textView
    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView,
      textView.string != text
    else {
      return
    }
    let selection = textView.selectedRange()
    textView.string = text
    textView.setSelectedRange(
      NSRange(
        location: min(selection.location, (text as NSString).length),
        length: 0
      )
    )
  }

  final class Coordinator: NSObject, NSTextViewDelegate {
    let onChange: (String, NSRange, PlainTextChange?) -> Void
    let onSelectionChange: (NSRange) -> Void
    private var pendingChange: PlainTextChange?

    init(
      onChange: @escaping (String, NSRange, PlainTextChange?) -> Void,
      onSelectionChange: @escaping (NSRange) -> Void
    ) {
      self.onChange = onChange
      self.onSelectionChange = onSelectionChange
    }

    func textDidChange(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }
      let change = pendingChange
      pendingChange = nil
      onChange(textView.string, textView.selectedRange(), change)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
      guard let textView = notification.object as? NSTextView else { return }
      onSelectionChange(textView.selectedRange())
    }

    func textView(
      _ textView: NSTextView,
      shouldChangeTextIn affectedCharRange: NSRange,
      replacementString: String?
    ) -> Bool {
      pendingChange = replacementString.map {
        PlainTextChange(range: affectedCharRange, replacement: $0)
      }
      return true
    }
  }
}
