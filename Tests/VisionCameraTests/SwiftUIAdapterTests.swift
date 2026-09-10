import AVFoundation
import SwiftUI
import UIKit
import VisionCamera
import XCTest

final class SwiftUIAdapterTests: XCTestCase {
  @MainActor
  func testFrameRendererMountsUpdatesAndDetachesThroughSwiftUI() throws {
    let firstRenderer = FrameRenderer()
    let secondRenderer = FrameRenderer()
    let host = UIHostingController<CameraFrameRenderer?>(
      rootView: CameraFrameRenderer(renderer: firstRenderer))
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    window.rootViewController = host
    window.isHidden = false
    defer {
      window.isHidden = true
      window.rootViewController = nil
    }
    host.view.layoutIfNeeded()

    let view = try XCTUnwrap(firstRenderer.layer.superlayer?.delegate as? FrameRendererView)
    XCTAssertEqual(firstRenderer.layer.videoGravity, .resizeAspect)
    XCTAssertEqual(firstRenderer.layer.frame, view.bounds)

    host.rootView = CameraFrameRenderer(renderer: secondRenderer, resizeMode: .cover)
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    XCTAssertNil(firstRenderer.layer.superlayer)
    XCTAssertTrue(secondRenderer.layer.superlayer === view.layer)
    XCTAssertEqual(secondRenderer.layer.videoGravity, .resizeAspectFill)

    host.rootView = nil
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    XCTAssertNil(secondRenderer.layer.superlayer)
    XCTAssertNil(view.renderer)
  }

  @MainActor
  func testPreviewUpdatesOutputGesturesAndCallbacksWithoutReplacingUIKitView() throws {
    let firstOutput = PreviewOutput()
    let secondOutput = PreviewOutput()
    let pinch = ZoomGestureController()
    let focus = TapToFocusGestureController()
    var firstCallbackCount = 0
    var latestCallbackCount = 0
    let host = UIHostingController<CameraPreview?>(
      rootView: CameraPreview(
        previewOutput: firstOutput,
        gestureControllers: [pinch],
        onPreviewStarted: { firstCallbackCount += 1 }))
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
    window.rootViewController = host
    window.isHidden = false
    defer {
      window.isHidden = true
      window.rootViewController = nil
    }
    host.view.layoutIfNeeded()

    let view = try XCTUnwrap(firstOutput.previewLayer.superlayer?.delegate as? PreviewView)
    XCTAssertTrue(pinch.gestureRecognizer.view === view)
    XCTAssertEqual(firstOutput.previewLayer.videoGravity, .resizeAspectFill)

    host.rootView = CameraPreview(
      previewOutput: secondOutput,
      resizeMode: .contain,
      gestureControllers: [focus],
      onPreviewStarted: { latestCallbackCount += 1 })
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    XCTAssertNil(firstOutput.previewLayer.superlayer)
    XCTAssertTrue(secondOutput.previewLayer.superlayer === view.layer)
    XCTAssertNil(pinch.gestureRecognizer.view)
    XCTAssertTrue(focus.gestureRecognizer.view === view)
    XCTAssertEqual(secondOutput.previewLayer.videoGravity, .resizeAspect)
    view.onPreviewStarted?()
    XCTAssertEqual(firstCallbackCount, 0)
    XCTAssertEqual(latestCallbackCount, 1)

    host.rootView = nil
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    XCTAssertNil(secondOutput.previewLayer.superlayer)
    XCTAssertNil(focus.gestureRecognizer.view)
    XCTAssertNil(view.previewOutput)
    XCTAssertNil(view.onPreviewStarted)
    XCTAssertNil(view.onPreviewStopped)
    XCTAssertNil(view.interfaceOrientation)
  }

  @MainActor
  func testDismantlingPreviousViewDoesNotDetachAReusedDisplayLayer() {
    let renderer = FrameRenderer()
    let previousRendererView = FrameRendererView(frame: .zero)
    let currentRendererView = FrameRendererView(frame: .zero)
    previousRendererView.renderer = renderer
    currentRendererView.renderer = renderer
    CameraFrameRenderer.dismantleUIView(previousRendererView, coordinator: ())
    XCTAssertTrue(renderer.layer.superlayer === currentRendererView.layer)

    let previewOutput = PreviewOutput()
    let previousPreviewView = PreviewView(previewOutput: previewOutput)
    let currentPreviewView = PreviewView(previewOutput: previewOutput)
    CameraPreview.dismantleUIView(previousPreviewView, coordinator: ())
    XCTAssertTrue(previewOutput.previewLayer.superlayer === currentPreviewView.layer)
  }
}
