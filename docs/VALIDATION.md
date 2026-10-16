# Validation — 1.3.0

Local runtime environment: Mac mini M4 Pro, macOS 27.0, Xcode 27.0.

| Check | Result |
|---|---|
| Debug tests, English / US | 39 passed, 0 failures |
| Debug tests, Traditional Chinese / Taiwan | 39 passed, 0 failures |
| Optimized Release tests, Traditional Chinese / Taiwan | 39 passed, 0 failures |
| Native AppKit window snapshots | Both languages rendered and visually inspected; saved in `snapshots/v1.3.0/` |
| Big5 round-trip | Passed in each test run |
| CSV open, edit, save, reopen | Passed, including Traditional Chinese, quotes, and embedded newlines |
| Translated “no quotes” control | Passed; CSV settings use stable segment identities instead of translated labels |
| Distribution executable | Mach-O arm64 |
| Distribution signature | Ad hoc; `codesign --verify --deep --strict` passes |
| Apple notarization / Developer ID | Not available for this release |
| ZIP contents | MIT license included; no XCTest bundles or test frameworks |

The 39 tests consist of 36 upstream tests and 3 additional integration tests. The optimized Release test host is built in its own derived-data directory with `GCC_SYMBOLS_PRIVATE_EXTERN=NO` so XCTest can link to application classes. The distributed app uses normal Release symbol visibility and a separate `build/Distribution-arm64` directory; it does not include the test host's plug-ins.

The minimum deployment target is macOS 12. That target is a build setting, not a claim that every macOS 12–26 version has been runtime-tested. See the repository's GitHub Actions page for additional runner results.

Upstream numeric inference is unchanged; numeric formatting such as leading zeroes may be normalized. This compatibility/localization release does not claim lossless preservation of arbitrary CSV byte formatting.
