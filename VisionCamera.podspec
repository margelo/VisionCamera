Pod::Spec.new do |s|
  s.name = 'VisionCamera'
  s.version = '0.1.0'
  s.summary = 'A native Swift camera framework for iOS.'
  s.description = 'UIKit previews, photo capture, video recording, frame and depth outputs, and camera controls built on AVFoundation.'
  s.homepage = 'https://github.com/margelo/VisionCamera'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Marc Rousavy' => 'me@mrousavy.com' }
  s.source = { :git => 'https://github.com/margelo/VisionCamera.git', :tag => s.version.to_s }
  s.module_name = 'VisionCamera'
  s.ios.deployment_target = '15.1'
  s.swift_version = '5.0'
  s.source_files = 'Sources/VisionCamera/**/*.swift'
  s.frameworks = 'AVFoundation', 'UIKit', 'CoreMedia', 'CoreVideo', 'CoreImage', 'CoreMotion', 'CoreLocation', 'ImageIO', 'CoreGraphics', 'UniformTypeIdentifiers'

  s.test_spec 'Tests' do |tests|
    tests.source_files = 'Tests/VisionCameraTests/**/*.swift'
    tests.frameworks = 'XCTest'
  end
end
