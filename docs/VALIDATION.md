# Validation — 1.3.1

Local runtime environment: Mac mini M4 Pro, macOS 27.0, Xcode 27.0.

| Check | Result |
|---|---|
| Debug tests, English / US | 48 passed, 0 failures |
| Debug tests, Traditional Chinese / Taiwan | 48 passed, 0 failures |
| Optimized Release tests, Traditional Chinese / Taiwan | 48 passed, 0 failures |
| Native AppKit window snapshots | Both languages rendered and visually inspected; `00042` remains visible in `snapshots/v1.3.1/` |
| Literal cell values | Leading zeroes, signed text, decimal trailing zeroes, exponent spelling, 50-digit identifiers, dates, formula text, surrounding whitespace, Traditional Chinese, delimiters, quotes, backslashes, embedded CRLF and empty cells |
| Dialect/encoding matrix | Comma, semicolon and tab; doubled-quote and backslash escaping; UTF-8, UTF-16 and explicit Big5; 18 combinations |
| Real document workflow | Open → unchanged save → edit one ID → undo → redo → save → reopen; all other cells equal fixture values; source copy untouched |
| Unchanged saves | Original bytes returned, including UTF-8 BOM / UTF-16 BOM, quoting and record endings; tested before the window loads as well |
| Paste | Leading zeroes, decimal spelling, exponent spelling, whitespace and reordered column mapping |
| Writer behavior | Does not mutate input; preserves ragged rows, blank records and trailing empty fields; supports reordered columns |
| Save failure | Unsafe unquoted output and unrepresentable encoding rejected; actual document failed saves leave the existing file's bytes unchanged |
| Distribution executable | Mach-O arm64 |
| Distribution signature | Ad hoc; `codesign --verify --deep --strict` passes |
| Apple notarization / Developer ID | Not available for this release |

The suite contains 36 upstream tests (numeric-looking cells now assert literal strings plus independent numeric classification) and 12 integration/regression tests. Before the fix, the new real-document regression reproduced changed IDs, decimal/exponent normalization, and an exception when undoing a numeric edit.

Optimized Release tests use a separate derived-data directory with `GCC_SYMBOLS_PRIVATE_EXTERN=NO` so XCTest can link to application classes. The distribution uses normal Release visibility in `build/Distribution-arm64`; the packaged app must not contain XCTest plug-ins or frameworks.

## Scope and limits

- CSV cells are text, with no automatic numeric conversion. The decimal-mark setting affects heuristic scoring/alignment only.
- Unchanged bytes are retained only when cell content, header content, column order and format match the original read. After edits, quoting is regenerated; record endings use the detected style, so mixed endings can normalize. This is not a byte-identical rewrite guarantee after edits.
- Format and legacy encoding detection remain heuristic. Big5 tests explicitly select Big5, since successful decoding alone cannot resolve every ambiguous legacy encoding. Inspect the preview and select the correct format before editing.
- These fixtures cover supported dialects, not all malformed files. Formula text is preserved as text; this app does not evaluate it.
- The deployment target is macOS 12, not a claim that every macOS 12–26 release has been runtime-tested. See GitHub Actions for additional runner results.
- Historical 1.3.0 snapshots remain in their versioned directory; 1.3.1 does not overwrite them.
