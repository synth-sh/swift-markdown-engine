import Foundation

public enum MarkdownSource {
    /// UTF-16 source ranges of inline and fenced code.
    public static func codeRanges(in markdown: String) -> [NSRange] {
        MarkdownTokenizer.parseTokensViaAST(in: markdown)
            .filter { $0.kind == .inlineCode || $0.kind == .codeBlock }
            .map(\.range)
    }
}
