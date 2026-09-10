# Publish a Swift package release

Swift Package Manager resolves VisionCamera directly from this Git repository. Publishing requires a commit containing `Package.swift` and a semantic version tag. No package-name registration, registry account, upload, or binary archive is required. See [Apple's Swift package publishing guide](https://developer.apple.com/documentation/xcode/publishing-a-swift-package-with-xcode).

1. Merge the release changes into `main` and wait for both CI workflows to pass. The **Swift Package Manager** workflow validates the manifest, builds for iOS devices, and runs the package tests on an iOS simulator.
2. Set `s.version` in `VisionCamera.podspec` to the new version and merge that change before tagging. Use the same version for both package managers.
3. Create a GitHub release targeting the tested commit on `main`, with the version as its tag, such as `0.1.1`. Use the version without a `v` prefix to match the podspec's source tag.
4. Confirm that the tag's **Swift Package Manager** workflow passes. Add the Git URL to an app with a version requirement and confirm that Xcode resolves the new release.

The existing `0.1.0` tag does not contain `Package.swift`. Use a new version for the first SPM release. Never move an existing release tag.

SPM consumers can resolve a pushed version tag without a GitHub release entry. The release entry provides release notes. CocoaPods publication remains a separate step.

## Add the package to Swift Package Index

The repository is currently private, so consumers need GitHub access. When the repository becomes public and contains a package release, optionally [submit its Git URL to Swift Package Index](https://swiftpackageindex.com/add-a-package). The index provides discovery and compatibility information. It does not reserve the package name and is not required for SPM installation.
