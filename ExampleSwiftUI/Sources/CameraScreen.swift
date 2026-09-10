import SwiftUI
import VisionCamera

@MainActor
struct CameraScreen: View {
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var model = CameraModel()

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if let device = model.device, let videoOutput = model.videoOutput {
        Camera(
          device: device,
          isActive: model.isActive,
          outputs: [model.photoOutput, videoOutput],
          constraints: [.frameRate(30)]
        )
        .zoom($model.zoom)
        .enableZoomGesture()
        .enableTapToFocusGesture()
        .onConfigured { _ in model.didConfigure() }
        .onStarted { model.didStart() }
        .onStopped { model.didStop() }
        .onInterruptionStarted { model.didInterrupt($0) }
        .onInterruptionEnded { model.didEndInterruption() }
        .onError { model.report($0) }
        .ignoresSafeArea()
      }

      VStack {
        HStack {
          if let thumbnail = model.thumbnail {
            Image(uiImage: thumbnail)
              .resizable()
              .scaledToFit()
              .frame(width: 96, height: 128)
              .background(.black.opacity(0.5))
              .accessibilityLabel("Last captured photo")
          }
          Spacer()
          Text(String(format: "%.1f×", model.zoom))
            .monospacedDigit()
            .padding(12)
            .background(.black.opacity(0.5), in: Capsule())
        }
        Spacer()
        controls
      }
      .padding(20)
      .foregroundStyle(.white)
    }
    .task {
      await model.prepare()
    }
    .task(id: scenePhase) {
      await model.setActive(scenePhase == .active)
    }
    .onDisappear {
      Task { await model.setActive(false) }
    }
    .preferredColorScheme(.dark)
  }

  private var controls: some View {
    VStack(spacing: 12) {
      Text(model.status)
        .font(.callout)
        .multilineTextAlignment(.center)
      Picker(
        "Recording backend",
        selection: Binding(get: { model.recordingMode }, set: { model.setRecordingMode($0) })
      ) {
        ForEach(RecordingMode.allCases, id: \.self) { mode in
          Text(mode.rawValue).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .disabled(!model.controlsEnabled || model.isRecording)
      Text("Persistent recording lets you flip cameras while recording.")
        .font(.caption)
        .multilineTextAlignment(.center)
      HStack {
        Button("Photo") { Task { await model.capturePhoto() } }
          .disabled(!model.controlsEnabled)
        Spacer()
        Button(model.isRecording ? "Stop" : "Record") { Task { await model.toggleRecording() } }
          .disabled(!model.controlsEnabled)
        Spacer()
        Button("Flip") { model.switchCamera() }
          .disabled(!model.canSwitchCamera)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
    }
    .padding(16)
    .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
  }
}
