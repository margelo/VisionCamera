import AVFoundation
import SwiftUI
import XCTest

@testable import VisionCamera

final class SwiftUICameraTests: XCTestCase {
  @MainActor
  func testConfigurationEqualityUsesOrderedOutputIdentityAndConstraintValues() {
    let photo = PhotoOutput()
    let movie = MovieFileVideoOutput()
    let first = CameraViewConfiguration(
      device: .position(.back), outputs: [photo, movie], constraints: [.fps(FPSConstraint(fps: 60))])
    let rebuilt = CameraViewConfiguration(
      device: .position(.back), outputs: [photo, movie], constraints: [.fps(FPSConstraint(fps: 60))])
    XCTAssertEqual(first, rebuilt)

    var changed = rebuilt
    changed.outputs.reverse()
    XCTAssertNotEqual(first, changed)
    changed = rebuilt
    changed.outputs = [PhotoOutput(), movie]
    XCTAssertNotEqual(first, changed)
    changed = rebuilt
    changed.constraints = [.fps(FPSConstraint(fps: 30))]
    XCTAssertNotEqual(first, changed)
    changed = rebuilt
    changed.device = .position(.front)
    XCTAssertNotEqual(first, changed)
    changed = rebuilt
    changed.sessionConfiguration.allowHapticsAndSystemSoundsPlayback = true
    XCTAssertNotEqual(first, changed)
    changed = rebuilt
    changed.mirrorMode = .off
    XCTAssertNotEqual(first, changed)
  }

  @MainActor
  func testResolutionBiasPreservesExplicitThenPreviewThenOutputOrder() {
    let preview = PreviewOutput()
    let photo = PhotoOutput()
    let movie = MovieFileVideoOutput()
    let configuration = CameraViewConfiguration(
      device: .position(.back), outputs: [photo, movie],
      constraints: [.fps(FPSConstraint(fps: 60)), .resolutionBias(ResolutionBiasConstraint(resolutionBias: movie))])
    let connection = configuration.connection(preview: preview, initialZoom: 2, initialExposureBias: -1)
    let expectedOutputs: [any CameraOutput] = [preview, photo, movie]
    XCTAssertTrue(connection.outputs.map(\.output).elementsEqual(expectedOutputs, by: { $0 === $1 }))
    XCTAssertEqual(connection.initialZoom, 2)
    XCTAssertEqual(connection.initialExposureBias, -1)
    XCTAssertTrue(connection.constraints[0].isEquivalent(to: .fps(FPSConstraint(fps: 60))))
    let biases = connection.constraints.compactMap { constraint -> (any CameraOutput)? in
      guard case .resolutionBias(let bias) = constraint else { return nil }
      return bias.resolutionBias
    }
    let expectedBiases: [any CameraOutput] = [movie, preview, photo, movie]
    XCTAssertTrue(biases.elementsEqual(expectedBiases, by: { $0 === $1 }))
  }

  @MainActor
  func testControlAndClosureChangesDoNotChangeTheSessionConfiguration() {
    let camera = Camera(device: .position(.back), isActive: false)
    let changed =
      camera
      .zoom(2)
      .exposureBias(-1)
      .torchMode(.on)
      .controllerConfiguration(CameraControllerConfiguration(enableLowLightBoost: true))
      .initialZoom(4)
      .initialExposureBias(-2)
      .orientationSource(nil)
      .resizeMode(.contain)
      .enableTapToFocusGesture()
      .onError { _ in }
      .onConfigured { _ in }
    XCTAssertEqual(camera.options.configuration, changed.options.configuration)
  }

  @MainActor
  func testFixedZoomWithNativePinchStaysStoppedUntilTheConflictIsRemoved() async {
    var configurations = 0
    var conflicts = 0
    let coordinator = CameraCoordinator { connections, _ in
      if !connections.isEmpty { configurations += 1 }
      return []
    }
    let camera = Camera(device: .position(.back), isActive: true)
      .zoom(2)
      .enableZoomGesture()
      .onError { error in
        if error.localizedDescription.contains("fixed zoom") { conflicts += 1 }
      }
    let preview = PreviewView()
    coordinator.mount(camera: camera, preview: preview)
    await coordinator.scheduler.waitUntilIdle()
    coordinator.update(camera: camera.exposureBias(1))
    await coordinator.scheduler.waitUntilIdle()
    XCTAssertEqual(configurations, 0)
    XCTAssertEqual(conflicts, 1)
    XCTAssertFalse(coordinator.requestedRunning)
    XCTAssertFalse(coordinator.session.isRunning)
    XCTAssertNil(coordinator.deviceOrientationManager)
    coordinator.update(camera: camera.enableZoomGesture(false).orientationSource(nil))
    await coordinator.scheduler.waitUntilIdle()
    XCTAssertEqual(configurations, 1)
    coordinator.dismantle()
    await coordinator.scheduler.waitUntilIdle()
  }

  @MainActor
  func testSchedulerCoalescesPendingWorkAndNeverOverlapsOperations() async {
    let scheduler = CameraUpdateScheduler()
    var events: [String] = []
    let started = expectation(description: "First update started")
    var release: CheckedContinuation<Void, Never>?
    scheduler.schedule {
      events.append("first-start")
      await withCheckedContinuation { continuation in
        release = continuation
        started.fulfill()
      }
      events.append("first-end")
    }
    await fulfillment(of: [started], timeout: 2)
    scheduler.schedule { events.append("superseded") }
    scheduler.schedule { events.append("latest") }
    XCTAssertEqual(events, ["first-start"])
    release?.resume()
    await scheduler.waitUntilIdle()
    XCTAssertEqual(events, ["first-start", "first-end", "latest"])
    scheduler.schedule { events.append("next") }
    await scheduler.waitUntilIdle()
    XCTAssertEqual(events.last, "next")
  }

  func testQueuedSubscriptionRegistersThenRemovesOnItsOwnerQueue() async {
    let queue = DispatchQueue(label: "VisionCameraTests.subscription")
    let key = DispatchSpecificKey<Bool>()
    queue.setSpecific(key: key, value: true)
    var events: [String] = []
    let subscription = CameraQueuedSubscription(queue: queue) {
      XCTAssertEqual(DispatchQueue.getSpecific(key: key), true)
      events.append("subscribe")
      return ListenerSubscription {
        XCTAssertEqual(DispatchQueue.getSpecific(key: key), true)
        events.append("remove")
      }
    }
    subscription.remove()
    subscription.remove()
    await queue.perform { XCTAssertEqual(events, ["subscribe", "remove"]) }
  }

  @MainActor
  func testUnmountSupersedesPendingMountAndReleasesResources() async {
    var coordinator: CameraCoordinator? = CameraCoordinator()
    let isCoordinatorReleased = { [weak coordinator] in coordinator == nil }
    let isOutputReleased = { [weak output = coordinator?.previewOutput] in output == nil }
    let scheduler = coordinator!.scheduler
    let session = coordinator!.session
    let preview = PreviewView()
    let camera = Camera(device: .position(.back), isActive: true)
      .onConfigured { _ in XCTFail("A removed Camera must not configure") }
      .onError { _ in XCTFail("A pending mount must be superseded by removal") }
      .onPreviewChanged { _ in XCTFail("A removed pending preview must not be announced") }
    coordinator?.mount(camera: camera, preview: preview)
    coordinator?.dismantle()
    coordinator = nil
    await scheduler.waitUntilIdle()
    XCTAssertNil(preview.previewOutput)
    XCTAssertTrue(preview.gestureControllers.isEmpty)
    XCTAssertFalse(session.isRunning)
    XCTAssertTrue(session.session.connections.isEmpty)
    XCTAssertTrue(isCoordinatorReleased())
    XCTAssertTrue(isOutputReleased())
  }

  @MainActor
  func testSessionListenersUseLatestClosuresAndAreRemovedOnDismantle() async {
    let coordinator = CameraCoordinator()
    let preview = PreviewView()
    var oldEvents = 0
    var latestEvents = 0
    let camera = Camera(device: .position(.back), isActive: false).onStarted { oldEvents += 1 }
    coordinator.mount(camera: camera, preview: preview)
    coordinator.update(camera: camera.onStarted { latestEvents += 1 })
    NotificationCenter.default.post(name: AVCaptureSession.didStartRunningNotification, object: coordinator.session.session)
    XCTAssertEqual(oldEvents, 0)
    XCTAssertEqual(latestEvents, 1)
    coordinator.dismantle()
    NotificationCenter.default.post(name: AVCaptureSession.didStartRunningNotification, object: coordinator.session.session)
    XCTAssertEqual(latestEvents, 1)
    await coordinator.scheduler.waitUntilIdle()
  }

  @MainActor
  func testPreviewRemovalIsPairedWithTheHandlerThatReceivedTheView() async {
    let coordinator = CameraCoordinator { _, _ in return [] }
    let preview = PreviewView()
    var originalEvents: [Bool] = []
    var replacementEvents: [Bool] = []
    let camera = Camera(device: .position(.back), isActive: false)
      .onError { _ in }
      .onPreviewChanged { originalEvents.append($0 != nil) }
    coordinator.mount(camera: camera, preview: preview)
    await coordinator.scheduler.waitUntilIdle()
    coordinator.update(camera: camera.onPreviewChanged { replacementEvents.append($0 != nil) })
    await coordinator.scheduler.waitUntilIdle()
    coordinator.dismantle()
    await coordinator.scheduler.waitUntilIdle()
    XCTAssertEqual(originalEvents, [true, false])
    XCTAssertTrue(replacementEvents.isEmpty)
  }

  @MainActor
  func testGesturesKeepIdentityAcrossUpdatesAndDetachWhenDisabled() async {
    let coordinator = CameraCoordinator()
    let preview = PreviewView()
    var zoom = 1.0
    let binding = Binding(get: { zoom }, set: { zoom = $0 })
    let camera = Camera(device: .position(.back), isActive: false)
      .zoom(binding)
      .enableZoomGesture()
      .enableTapToFocusGesture()
    coordinator.mount(camera: camera, preview: preview)
    let pinch = coordinator.zoomGesture
    let tap = coordinator.focusGesture
    XCTAssertNotNil(pinch)
    XCTAssertNotNil(tap)
    coordinator.update(camera: camera.exposureBias(1))
    XCTAssertTrue(coordinator.zoomGesture === pinch)
    XCTAssertTrue(coordinator.focusGesture === tap)
    XCTAssertEqual(preview.gestureControllers.count, 2)
    XCTAssertTrue(preview.gestureControllers[0] === tap)
    XCTAssertTrue(preview.gestureControllers[1] === pinch)
    coordinator.update(camera: camera.enableZoomGesture(false).enableTapToFocusGesture(false))
    XCTAssertTrue(preview.gestureControllers.isEmpty)
    XCTAssertNil(pinch?.gestureRecognizer.view)
    XCTAssertNil(tap?.gestureRecognizer.view)
    coordinator.dismantle()
    await coordinator.scheduler.waitUntilIdle()
  }

  @MainActor
  func testCustomOrientationDoesNotModifyOutputOrInventUIRotation() async {
    let coordinator = CameraCoordinator()
    let output = PhotoOutput()
    output.outputOrientation = .left
    let camera = Camera(device: .position(.back), isActive: false, outputs: [output])
      .orientationSource(nil)
      .onUIRotationChanged { _ in XCTFail("Custom orientation has no single output angle") }
    coordinator.camera = camera
    coordinator.interfaceOrientation = .up
    coordinator.deviceOrientation = .right
    await coordinator.updateOutputOrientation()
    XCTAssertEqual(output.outputOrientation, .left)
    XCTAssertNil(coordinator.deviceOrientationManager)
    coordinator.camera = nil
  }

  @MainActor
  func testUIRotationUsesShortestSignedCardinalDifference() {
    XCTAssertEqual(CameraCoordinator.uiRotation(output: .up, interface: .up), 0)
    XCTAssertEqual(CameraCoordinator.uiRotation(output: .right, interface: .up), -90)
    XCTAssertEqual(CameraCoordinator.uiRotation(output: .left, interface: .up), 90)
    XCTAssertEqual(CameraCoordinator.uiRotation(output: .up, interface: .down), 180)
  }

  @MainActor
  func testAddingUIRotationHandlerReceivesTheKnownOrientationWithoutReconfiguring() async {
    let coordinator = CameraCoordinator()
    let camera = Camera(device: .position(.back), isActive: false).orientationSource(.interface)
    coordinator.camera = camera
    coordinator.interfaceOrientation = .right
    await coordinator.updateOutputOrientation()
    var rotations: [Double] = []
    coordinator.camera = camera.onUIRotationChanged { rotations.append($0) }
    await coordinator.updateOutputOrientation()
    await coordinator.updateOutputOrientation()
    XCTAssertEqual(rotations, [0])
    XCTAssertNil(coordinator.attemptedConfiguration)
    coordinator.camera = nil
  }

  @MainActor
  func testInFlightConfigurationUsesLatestInputsAndSuppressesStaleErrors() async {
    let entered = expectation(description: "First configuration entered")
    var resume: CheckedContinuation<Void, Never>?
    var configuredInputs: [TargetCameraPosition] = []
    var disconnects = 0
    var errors: [String] = []
    let coordinator = CameraCoordinator { connections, _ in
      guard let connection = connections.first else {
        disconnects += 1
        return []
      }
      guard case .position(let position) = connection.input else {
        XCTFail("The test supplied a position")
        return []
      }
      configuredInputs.append(position)
      if configuredInputs.count == 1 {
        await withCheckedContinuation { continuation in
          resume = continuation
          entered.fulfill()
        }
        throw CameraError(message: "superseded")
      }
      throw CameraError(message: "current")
    }
    let preview = PreviewView()
    coordinator.mount(
      camera: Camera(device: .position(.back), isActive: true)
        .orientationSource(nil)
        .onError { error in
          if error is CameraError { XCTFail("A stale configuration must not call its old handler") }
        },
      preview: preview)
    await fulfillment(of: [entered], timeout: 2)
    let latest = Camera(device: .position(.front), isActive: false)
      .orientationSource(nil)
      .onError { error in
        if error is CameraError { errors.append(error.localizedDescription) }
      }
    coordinator.update(camera: latest)
    coordinator.update(camera: latest.exposureBias(1))
    resume?.resume()
    await coordinator.scheduler.waitUntilIdle()
    XCTAssertEqual(configuredInputs, [.back, .front])
    XCTAssertEqual(errors.count, 1)
    XCTAssertTrue(errors.first?.contains("current") == true)
    XCTAssertFalse(coordinator.session.isRunning)
    XCTAssertNil(coordinator.controller)
    coordinator.update(camera: latest.onError { _ in XCTFail("Changing only callbacks must not retry configuration") })
    await coordinator.scheduler.waitUntilIdle()
    XCTAssertEqual(configuredInputs.count, 2)
    coordinator.dismantle()
    await coordinator.scheduler.waitUntilIdle()
    XCTAssertEqual(disconnects, 1)
  }

  @MainActor
  func testDismantleWaitsForInFlightConfigurationThenDisconnectsWithoutNewSubscriptions() async {
    let entered = expectation(description: "Configuration suspended")
    var resume: CheckedContinuation<Void, Never>?
    var events: [String] = []
    let coordinator = CameraCoordinator { connections, _ in
      if connections.isEmpty {
        events.append("disconnect")
        return []
      }
      events.append("configure")
      await withCheckedContinuation { continuation in
        resume = continuation
        entered.fulfill()
      }
      events.append("finish")
      return []
    }
    let preview = PreviewView()
    coordinator.mount(
      camera: Camera(device: .position(.back), isActive: true)
        .orientationSource(nil)
        .onError { error in
          if error is CameraError { XCTFail("A removed Camera must not report late configuration results") }
        }
        .onConfigured { _ in XCTFail("A removed Camera must not announce configuration") },
      preview: preview)
    await fulfillment(of: [entered], timeout: 2)
    coordinator.dismantle()
    XCTAssertNil(preview.previewOutput)
    XCTAssertTrue(coordinator.subscriptions.isEmpty)
    resume?.resume()
    await coordinator.scheduler.waitUntilIdle()
    XCTAssertEqual(events, ["configure", "finish", "disconnect"])
    XCTAssertNil(coordinator.controller)
    XCTAssertNil(coordinator.subjectSubscription)
    XCTAssertFalse(coordinator.session.isRunning)
  }

  func testEmptySessionConfigurationDoesNotRequireCameraPermission() async throws {
    let session = CameraSession()
    let controllers = try await session.configure(connections: [])
    XCTAssertTrue(controllers.isEmpty)
    XCTAssertTrue(session.session.inputs.isEmpty)
    XCTAssertTrue(session.session.outputs.isEmpty)
    XCTAssertFalse(session.isRunning)
  }
}
