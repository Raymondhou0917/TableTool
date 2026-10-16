# Upstream and existing Apple Silicon work

Table Tool Native is a community fork of [jakob/TableTool](https://github.com/jakob/TableTool), originally created by Sandro Peham, Andreas Aigner, and Jakob Egger. The original MIT license is preserved in `LICENSE`.

An Apple Silicon solution already existed before this fork:

- [Upstream issue #109](https://github.com/jakob/TableTool/issues/109) describes building the original app with a current Xcode and its legacy appearance limitations.
- [Andrea Brugnoli's PR #112](https://github.com/jakob/TableTool/pull/112) updates the deployment target, removes unused Swift settings, and updates deprecated AppKit constants. The commit is included with its original author and a cherry-pick provenance trailer. This fork raises the deployment target further to macOS 12 to match the Xcode 27 SDK used for validation.

This fork adds a reproducible ARM64 build, Traditional Chinese and English localization, a language menu, Big5 in the encoding menu, regression tests, a privacy manifest, and release instructions. It does not claim to be the official App Store update.

The executable retains upstream's CSV parsing and numeric inference behavior. This is a focused compatibility/localization release, not a new CSV engine. Keep backups when converting files; numeric formatting such as leading zeroes may be normalized by the inherited reader. A separately scoped data-preservation change would require additional design and regression coverage.
