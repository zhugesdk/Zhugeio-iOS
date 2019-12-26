Pod::Spec.new do |s|
  s.name         = "ZhugeioAnalytics"
  s.version      = "3.4.2"
  s.summary      = "iOS tracking library for Zhugeio Analytics, The function is all ready finishing."
  s.homepage     = "http://zhugeio.com"
  s.license      = "MIT"
  s.author       = { "Zhugeio,Inc" => "info@zhugeio.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/zhugesdk/Zhugeio-iOS.git", :tag => s.version }
  s.requires_arc = true
  s.source_files = 'Zhugeio/**/*.{m,h}'
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
  # s.libraries = 'z'
  # s.default_subspec = 'ZhugeioAnalytics'

  
  # s.subspec 'ZhugeioAnalytics' do |ss|
  #   ss.source_files = 'Zhugeio/**/*.{m,h}'
  #   ss.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
  #   ss.libraries = 'z'
  # end
end
