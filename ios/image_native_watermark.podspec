#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint image_native_watermark.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'image_native_watermark'
  s.version          = '0.0.1'
  s.summary          = 'High-performance native camera frame image processing and watermarking.'
  s.description      = <<-DESC
High-performance native Android & iOS camera frame processing and watermarking (NV21/BGRA to JPEG, rotation, flipping, resizing, and text overlay).
                       DESC
  s.homepage         = 'https://github.com/andikatp/image_native_watermark'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Andika Tri Prasetya' => 'triprasetya_andika@yahoo.com' }
  s.source           = { :path => '.' }
  s.source_files = 'image_native_watermark/Sources/image_native_watermark/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'image_native_watermark_privacy' => ['image_native_watermark/Sources/image_native_watermark/PrivacyInfo.xcprivacy']}
end
