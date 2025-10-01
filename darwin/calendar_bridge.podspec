#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint calendar_bridge.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'calendar_bridge'
  s.version          = '1.0.0'
  s.summary          = 'A cross-platform Flutter plugin for accessing and managing device calendars.'
  s.description      = <<-DESC
A cross-platform Flutter plugin for accessing and managing device calendars on Android, iOS, and macOS with clean architecture.
                       DESC
  s.homepage         = 'https://github.com/ahmtydn/calendar_bridge'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ahmet Aydın' => 'ahmet@ahmetaydin.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  
  # Platform support
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '11'
  
  # Dependencies
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' 
  }
  s.swift_version = '5.0'
end