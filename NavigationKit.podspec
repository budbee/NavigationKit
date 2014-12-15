Pod::Spec.new do |s|
  s.name             = "NavigationKit"
  s.version          = "0.1.0"
  s.summary          = "Turn-by-Turn driving directions using Google or Apple Directions API"
  s.homepage         = "https://github.com/sendus/NavigationKit"
  s.license          = 'GPL'
  s.author           = { "Axel Moller" => "axelmoller5@gmail.com" }
  s.source           = { :git => "https://github.com/sendus/NavigationKit.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'NavigationKit' => ['Pod/Assets/*.png']
  }

  s.frameworks = 'MapKit'
  s.dependency 'Google-Maps-iOS-SDK'
end
