Pod::Spec.new do |s|
  s.name = 'VisionCameraResizer'
  s.version = '0.1.0'
  s.summary = 'GPU crop, resize, rotation, and tensor conversion for Camera frames.'
  s.homepage = 'https://github.com/margelo/VisionCamera'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'Marc Rousavy' => 'me@mrousavy.com' }
  s.source = { :git => 'https://github.com/margelo/VisionCamera.git', :tag => s.version.to_s }
  s.module_name = 'VisionCameraResizer'
  s.ios.deployment_target = '15.1'
  s.swift_version = '5.0'
  s.source_files = 'Sources/VisionCameraResizer/**/*.swift', 'Sources/VisionCameraResizer/Documentation.docc/**/*'
  s.frameworks = 'Metal', 'CoreVideo'
  s.dependency 'VisionCamera', s.version.to_s
  s.resource_bundles = { 'VisionCameraResizer' => ['Sources/VisionCameraResizer/Shaders/*.metal'] }

  s.test_spec 'Tests' do |tests|
    tests.source_files = 'Tests/VisionCameraResizerTests/**/*.swift'
    tests.frameworks = 'XCTest'
  end
end
