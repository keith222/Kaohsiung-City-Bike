# Uncomment this line to define a global platform for your project
 platform :ios, '8.0'
# Uncomment this line if you're using Swift
 use_frameworks!

target 'Kaohsiung City Bike' do

  #Pods about Swift Language
  pod 'SwifterSwift'

  #Pods about internet request/response/parse
  pod 'Alamofire'

  #Pods about UI
  pod 'PKHUD'
 
  #Google Firebase  
  pod 'Firebase/Core'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'
  pod 'Firebase/Crashlytics'
  
end

target 'Kaohsiung CityBike WatchApp Extension' do
    platform :watchos, '2.0'
end

target 'Kaohsiung CityBike Widget' do
    
    #Pods about internet request/response/parse
    pod 'Alamofire'
    
    #Google Firebase
    pod 'Firebase/Core'
    pod 'Firebase/Messaging'
    pod 'Firebase/Crashlytics'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
       if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 9.0
         config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
       end
    end
    target.build_configurations.each do |config|
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
    end
  end
end
