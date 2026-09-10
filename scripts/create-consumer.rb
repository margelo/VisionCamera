#!/usr/bin/env ruby
# Copyright © 2026 Marc Rousavy @ Margelo

require 'fileutils'
require 'xcodeproj'

# Generate isolated public consumers without changing the maintained core example.
root = File.expand_path('..', __dir__)
manager = ARGV.fetch(0, 'spm')
selection = ARGV.fetch(1, 'combined')
abort 'Usage: create-consumer.rb spm|pods core|resizer|barcode|location|combined' unless %w[spm pods].include?(manager)
features = {
  'core' => [],
  'resizer' => ['VisionCameraResizer'],
  'barcode' => ['VisionCameraBarcodeScanner'],
  'location' => ['VisionCameraLocation'],
  'combined' => %w[VisionCameraResizer VisionCameraBarcodeScanner VisionCameraLocation]
}.fetch(selection)
# A location-only consumer intentionally has no Camera dependency.
modules = selection == 'location' ? features : ['VisionCamera'] + features
directory = File.join(root, 'build', 'consumers', manager, selection)
FileUtils.mkdir_p(directory)
project_path = File.join(directory, 'OptionalModules.xcodeproj')
FileUtils.rm_rf(project_path)
project = Xcodeproj::Project.new(project_path)
minimum = features.include?('VisionCameraBarcodeScanner') ? '16.0' : '15.1'
app = project.new_target(:application, 'OptionalModules', :ios, minimum)
tests = project.new_target(:unit_test_bundle, 'PublicConsumerTests', :ios, minimum)
tests.add_dependency(app)
sources = project.main_group.new_group('Sources')
Dir.glob(File.join(root, 'OptionalExample/Sources/*.swift')).sort.each do |path|
  app.source_build_phase.add_file_reference(sources.new_file(path))
end
test_sources = project.main_group.new_group('Tests')
Dir.glob(File.join(root, 'OptionalExample/Tests/*.swift')).sort.each do |path|
  tests.source_build_phase.add_file_reference(test_sources.new_file(path))
end
if features.include?('VisionCameraBarcodeScanner')
  probe = File.join(root, 'Tests/VisionCameraBarcodeScannerTests/BarcodeRuntimeSupport.swift')
  tests.source_build_phase.add_file_reference(test_sources.new_file(probe))
end
imports = File.join(directory, 'SelectedModules.swift')
File.write(imports, modules.map { |name| "import #{name}" }.join("\n") + "\n")
app.source_build_phase.add_file_reference(sources.new_file(imports))

project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'SWIFT_VERSION' => '5.0',
      'PRODUCT_BUNDLE_IDENTIFIER' => "com.margelo.VisionCameraOptional.#{manager}.#{selection}.#{target.name}",
      'GENERATE_INFOPLIST_FILE' => 'YES',
      'TARGETED_DEVICE_FAMILY' => '1,2',
      'CODE_SIGNING_ALLOWED' => 'NO',
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => ['$(inherited)'] + modules.map { |name| "USE_#{name.upcase}" }
    })
    if target == app
      config.build_settings['INFOPLIST_KEY_NSCameraUsageDescription'] = 'Display the Camera and process frames in this example.' if modules.include?('VisionCamera')
      if features.include?('VisionCameraLocation')
        config.build_settings['INFOPLIST_KEY_NSLocationWhenInUseUsageDescription'] = 'Show your foreground location after you tap Enable location.'
      end
      config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
      config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
    else
      config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/OptionalModules.app/OptionalModules'
      config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
    end
  end
end

if manager == 'spm'
  package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  package.relative_path = root
  project.root_object.package_references << package
  [app, tests].each do |target|
    modules.each do |name|
      product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
      product.product_name = name
      target.package_product_dependencies << product
      build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
      build_file.product_ref = product
      target.frameworks_build_phase.files << build_file
    end
  end
else
  pods = modules.map { |name| "  pod '#{name}', :path => '#{root}'" }.join("\n")
  File.write(File.join(directory, 'Podfile'), <<~PODFILE)
    platform :ios, '#{minimum}'
    use_frameworks! :linkage => :static
    target 'OptionalModules' do
    #{pods}
      target 'PublicConsumerTests' do
        inherit! :search_paths
      end
    end
  PODFILE
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(tests)
scheme.save_as(project.path, 'OptionalModules', true)
puts directory
