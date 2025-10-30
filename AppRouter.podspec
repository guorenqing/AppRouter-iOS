#
# Be sure to run `pod lib lint AppRouter-iOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AppRouter'
  s.version          = '0.1.0'
  s.summary          = '一个基于swift语言的iOS路由系统'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  AppRouter 是一个基于 Swift 语言的 iOS 路由系统，旨在简化应用内页面跳转和功能调用的管理，提高代码的模块化和可维护性。
                       DESC

  s.homepage         = 'https://github.com/guorenqing/AppRouter-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '郭仁庆' => 'guorenqing@sina.com' }
  s.source           = { :git => 'https://github.com/guorenqing/AppRouter-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'AppRouter/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AppRouter-iOS' => ['AppRouter-iOS/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
