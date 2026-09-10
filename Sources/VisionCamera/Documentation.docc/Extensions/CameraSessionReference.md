# ``CameraSession``

## Topics

### Creating and configuring a session

- ``init(enableMultiCam:)``
- ``configure(connections:config:)``

### Starting and stopping capture

- ``start()``
- ``stop()``
- ``isRunning``

### Observing session events

- ``addOnStartedListener(onStarted:)``
- ``addOnStoppedListener(onStopped:)``
- ``addOnErrorListener(onError:)``
- ``addOnInterruptionStartedListener(onInterruptionStarted:)``
- ``addOnInterruptionEndedListener(onInterruptionEnded:)``

### Accessing AVFoundation

- ``session``
