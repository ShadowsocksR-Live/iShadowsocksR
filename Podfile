source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.0'
use_frameworks!

def library
    pod 'ICSMainFramework', :path => "./Library/ICSMainFramework/"
    pod 'KeychainAccess', '~> 3.1.1'
end

def model
    pod 'RealmSwift', '~> 2.10.2'
end

target "iShadowsocksR" do
    pod 'Aspects', :path => "./Library/Aspects/"
    pod 'Cartography', '~> 3.0.4'
    pod 'AsyncSwift'
    pod 'SwiftColor'
    pod 'Appirater'
    pod 'MBProgressHUD'
    pod 'ICDMaterialActivityIndicatorView', '~> 0.1.0'
    pod 'ICSPullToRefresh', '~> 0.6'
    pod 'ISO8601DateFormatter', '~> 0.8'
    pod 'Alamofire'
    pod 'ObjectMapper'
    pod 'PSOperations', '~> 4.0.1'
    library
    model
end

target "TodayWidget" do
    pod 'Cartography', '~> 3.0.4'
    pod 'SwiftColor'
    library
    model
end

target "PotatsoLibrary" do
    library
    model
end

target "PotatsoModel" do
    model
end
