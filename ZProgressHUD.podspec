#
#  Be sure to run `pod spec lint ZProgressHUD.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "ZProgressHUD"
  s.version      = "0.0.1"
  s.summary      = "ZProgressHUD is a simple use swift HUD"

  s.description  = <<-DESC
    ZProgressHUD is a simple use swift HUD.
    It is simple use like ZProgressHUD.show()
                   DESC

  s.homepage     = "https://github.com/zevwings/ZProgressHUD"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "zevwings" => "zev.wings@gmail.com" }
  s.source       = { :git => "https://github.com/zevwings/ZProgressHUD.git", :tag => "#{s.version}" }
  s.source_files = "ZProgressHUD/**/*.swift", "ZProgressHUD/ZProgressHUD.h"
  s.resources    = "ZProgressHUD/ZProgressHUD.bundle"
  s.requires_arc = true
  s.platform     = :ios
  s.ios.deployment_target = "8.0"

end