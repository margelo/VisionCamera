# ``CameraSession``

## Topics

### Creating and configuring a session

- ``init()``
- ``init(isMultiCamEnabled:)``
- ``configure(_:configuration:)``

### Starting and stopping capture

- ``start()``
- ``stop()``
- ``isRunning``

### Observing session events

- ``observeStarted(_:)``
- ``observeStopped(_:)``
- ``observeErrors(_:)``
- ``observeInterruptionStarted(_:)``
- ``observeInterruptionEnded(_:)``

### Accessing AVFoundation

- ``session``
