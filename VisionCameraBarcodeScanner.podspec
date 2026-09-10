Pod::Spec.new do |s|
  s.name = 'VisionCameraBarcodeScanner'
  s.version = '0.1.0'
  s.summary = 'On-device barcode detection with Apple Vision.'
  s.homepage = 'https://github.com/margelo/VisionCamera'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Marc Rousavy' => 'me@mrousavy.com' }
  s.source = { :git => 'https://github.com/margelo/VisionCamera.git', :tag => s.version.to_s }
  s.module_name = 'VisionCameraBarcodeScanner'
  s.ios.deployment_target = '16.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/VisionCameraBarcodeScanner/**/*.swift', 'Sources/VisionCameraBarcodeScanner/Documentation.docc/**/*'
  s.frameworks = 'Vision', 'UIKit', 'CoreVideo', 'ImageIO'
  s.dependency 'VisionCamera', s.version.to_s

  s.test_spec 'Tests' do |tests|
    tests.source_files = 'Tests/VisionCameraBarcodeScannerTests/**/*.swift'
    tests.frameworks = 'XCTest'
  end
end
