Pod::Spec.new do |s|
  s.name         = "ZhugeioAnalytics"
  s.version      = "3.4.25"
  s.summary      = "iOS tracking library for Zhugeio Analytics, The function is all ready finishing."
  s.homepage     = "http://zhugeio.com"
  s.license      = "MIT"
  s.author       = { "Zhugeio,Inc" => "info@zhugeio.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/zhugesdk/Zhugeio-iOS.git", :tag => s.version }
  s.requires_arc = true
  s.source_files = 'Zhugeio/**/*.{m,h}'
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
  s.user_target_xcconfig = {
    'GENERATE_INFOPLIST_FILE' => 'YES'
  }
  s.pod_target_xcconfig = {
    'GENERATE_INFOPLIST_FILE' => 'YES'
  }
  # s.libraries = 'z'
  # s.default_subspec = 'ZhugeioAnalytics'

  
  # s.subspec 'ZhugeioAnalytics' do |ss|
  #   ss.source_files = 'Zhugeio/**/*.{m,h}'
  #   ss.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
  #   ss.libraries = 'z'
  # end
end
