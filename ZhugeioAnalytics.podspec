Pod::Spec.new do |s|
  s.name         = "ZhugeioAnalytics"
  s.version      = "4.3.1"
  s.summary      = "iOS tracking library for Zhugeio Analytics, The function is all ready finishing."
  s.homepage     = "http://zhugeio.com"
  s.license      = "MIT"
  s.author       = { "Zhugeio,Inc" => "info@zhugeio.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/zhugesdk/Zhugeio-iOS.git", :tag => s.version }
  s.requires_arc = true
  s.static_framework = true

  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
  s.default_subspecs = 'Core'
  # 隐私清单资源
  s.resource_bundles = {
    'ZhugeioAnanlytics' => ['Zhugeio/Resources/PrivacyInfo.xcprivacy']
  }
  s.subspec 'Core' do |ss|
    ss.source_files = ['Zhugeio/Classes/ZGCore/**/*.{m,h}']
  
  end

  s.subspec 'GMEncrypt' do |ss|
    ss.source_files = 'Zhugeio/Classes/GMEncrypt/**/*.{m,h}'
    ss.frameworks = "Security"
    ss.dependency "GMOpenSSL"
  end
end
