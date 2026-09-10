Pod::Spec.new do |s|
  s.name = 'VisionCameraLocation'
  s.version = '0.1.0'
  s.summary = 'Explicit foreground location authorization and updates for iOS apps.'
  s.homepage = 'https://github.com/margelo/VisionCamera'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Marc Rousavy' => 'me@mrousavy.com' }
  s.source = { :git => 'https://github.com/margelo/VisionCamera.git', :tag => s.version.to_s }
  s.module_name = 'VisionCameraLocation'
  s.ios.deployment_target = '15.1'
  s.swift_version = '5.0'
  s.source_files = 'Sources/VisionCameraLocation/**/*.swift', 'Sources/VisionCameraLocation/Documentation.docc/**/*'
  s.frameworks = 'CoreLocation', 'Foundation'

  s.test_spec 'Tests' do |tests|
    tests.source_files = 'Tests/VisionCameraLocationTests/**/*.swift'
    tests.frameworks = 'XCTest'
  end
end
