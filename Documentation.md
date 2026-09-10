# Building the documentation

VisionCamera uses DocC for its API reference and written guides. Documentation comments live beside the public Swift declarations. Articles live in [`Documentation.docc`](./Sources/VisionCamera/Documentation.docc).

## Build locally

Use Xcode 26.2 or later and the Ruby version in `.ruby-version`:

```sh
bundle install
scripts/build-documentation.sh
python3 scripts/check-documentation-examples.py
```

The script installs the local CocoaPod, builds the framework's documentation, and checks that every public declaration has a documentation comment. Unresolved DocC links and other documentation warnings fail the build. The example checker compiles every complete Swift guide and README example against the built framework as a separate consumer. Compilation errors and warnings fail the check.

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

Link to a symbol with double backticks, such as ``CameraSession`` or ``CameraSession/configure(_:configuration:)``. Use `<doc:PhotoOutputGuide>` for a guide and ordinary Markdown links for external Apple documentation.

Keep the author's existing explanations when adapting documentation from react-native-vision-camera. Change platform details, API names, examples, and links to match this framework. The native framework uses Swift callbacks, `async`/`await`, `UIImage`, and retained media buffers.

The initial documentation was adapted from the TypeScript specs and `docs/content/docs` at react-native-vision-camera commit `91bae1f08d549b50444ee16661dc4f4375cba0b6`. Each guide records its original file names in a source comment. These Swift comments and articles are maintained here; DocC generates the reference pages and website from them.

## Publish with GitHub Pages

The documentation website lives at **https://margelo.github.io/VisionCamera/**. The repository's About section and README link to this URL.

The [Documentation workflow](./.github/workflows/documentation.yml) checks documentation on pull requests and pushes to `main`. Each successful build uploads an Xcode documentation archive and a Pages website artifact, including while the repository is private.

Once Pages is enabled, the workflow publishes automatically when the repository becomes public and on subsequent pushes to `main`. Pull requests and private repositories only build and check the documentation. To publish again manually, run **Documentation** on `main` with **Publish the documentation** enabled.

The Xcode archive is packaged as `VisionCamera.doccarchive.tar.gz` to preserve Swift symbol filenames. Extract it to open the resulting `.doccarchive` in Xcode.

### First-time activation

GitHub currently rejects Pages activation for this private repository on the organization's plan. After making the repository public, run this once from a checkout of `main`, using GitHub CLI authenticated as a repository administrator:

```sh
scripts/enable-documentation.sh
```

The script selects **GitHub Actions** as the Pages source and starts a fresh documentation deployment. It refuses to publish while the repository is private and does not change the repository's visibility. It is safe to run again if activation succeeded but the first build failed.

Alternatively, select **GitHub Actions** under [Settings > Pages](https://github.com/margelo/VisionCamera/settings/pages), then run the **Documentation** workflow on `main`. A run triggered by making the repository public can reach deployment before Pages is enabled; activate Pages and start a fresh run in that case.

This one-time step uses your local administrator session. GitHub's ordinary workflow token [cannot enable Pages](https://github.com/actions/configure-pages/blob/v6/action.yml), but it can publish subsequent updates without an additional secret. See [GitHub Pages availability](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages).

The website artifact always uses `/VisionCamera` as its hosting base path so asset URLs and direct links work at the project URL. To build the same artifact locally, run `scripts/build-documentation.sh /VisionCamera`. A future custom domain would also need this workflow setting updated.
