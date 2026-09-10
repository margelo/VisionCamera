# Building the documentation

VisionCamera uses DocC for its API reference and written guides. Documentation comments live beside the public Swift declarations. Articles live in [`Documentation.docc`](./Sources/VisionCamera/Documentation.docc).

## Build locally

Use Xcode 26.2 or later and the Ruby version in `.ruby-version`:

```sh
bundle install
scripts/build-documentation.sh
```

The script installs the local CocoaPod, builds the framework's documentation, and checks that every public declaration has a documentation comment. Unresolved DocC links and other documentation warnings fail the build.

The build produces:

* `build/documentation/Build/Products/Release-iphoneos/VisionCamera/VisionCamera.doccarchive`, which opens in Xcode.
* `build/site`, which contains the static documentation website.

To preview the website:

```sh
python3 -m http.server 8080 --bind 127.0.0.1 --directory build/site
```

Open `http://localhost:8080`. You can also open `Example/VisionCameraExample.xcworkspace`, select the **VisionCamera** scheme, and choose **Product > Build Documentation**.

If you use Swift Package Manager, open `Package.swift` in Xcode, select **VisionCamera** with an iOS destination, and choose **Product > Build Documentation**. The same comments and catalog work with both package managers.

To build the Swift package's documentation directly:

```sh
xcodebuild docbuild -scheme VisionCamera -configuration Release \
	-destination 'generic/platform=iOS' \
	-derivedDataPath build/spm-documentation CODE_SIGNING_ALLOWED=NO \
	OTHER_DOCC_FLAGS='--warnings-as-errors'
```

## Write API documentation

Use `///` comments above declarations. Start with a short summary, then explain behavior that the declaration alone doesn't describe. Include parameters, return values, thrown errors, callback queues, and buffer lifetimes where they apply.

Link to a symbol with double backticks, such as ``CameraSession`` or ``CameraSession/configure(connections:config:)``. Use `<doc:PhotoOutput>` for a guide and ordinary Markdown links for external Apple documentation.

Keep the author's existing explanations when adapting documentation from react-native-vision-camera. Change platform details, API names, examples, and links to match this framework. The native framework uses Swift callbacks, `async`/`await`, `UIImage`, and retained media buffers.

The initial documentation was adapted from the TypeScript specs and `docs/content/docs` at react-native-vision-camera commit `91bae1f08d549b50444ee16661dc4f4375cba0b6`. Each guide records its original file names in a source comment. These Swift comments and articles are maintained here; DocC generates the reference pages and website from them.

## Publish with GitHub Pages

The [Documentation workflow](./.github/workflows/documentation.yml) checks documentation on pull requests and pushes to `main`. Each run uploads an Xcode documentation archive and a Pages website artifact.

The Xcode archive is packaged as `VisionCamera.doccarchive.tar.gz` to preserve Swift symbol filenames. Extract it to open the resulting `.doccarchive` in Xcode.

To publish from this repository:

1. Enable GitHub Pages in the repository settings and select **GitHub Actions** as the build source.
2. Check the site's visibility. Private source repositories do not automatically mean private websites.
3. Run the **Documentation** workflow on `main` with **Publish the documentation** enabled.

The workflow reads the configured site's base path, so it works at a project URL such as `/VisionCamera` or a custom domain root. For a local build targeting a project URL, run `scripts/build-documentation.sh /VisionCamera`.

GitHub Free supports Pages for public repositories. A private repository needs GitHub Team or Enterprise Cloud; restricting the website itself to repository readers requires Enterprise Cloud. See [GitHub Pages availability](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages) and [site visibility](https://docs.github.com/en/enterprise-cloud@latest/pages/getting-started-with-github-pages/changing-the-visibility-of-your-github-pages-site).
