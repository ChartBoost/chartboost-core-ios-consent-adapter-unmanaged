Pod::Spec.new do |spec|
  spec.name        = 'ChartboostCoreConsentAdapterUnmanaged'
  spec.version     = '1.1.0.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/chartboost-core-ios-consent-adapter-unmanaged'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Chartboost Core iOS SDK Unmanaged Consent Adapter.'
  spec.description = 'Unmanaged CMP adapter for mediating through Chartboost Core.'

  # Source
  spec.module_name  = 'ChartboostCoreConsentAdapterUnmanaged'
  spec.source       = { :git => 'https://github.com/ChartBoost/chartboost-core-ios-consent-adapter-unmanaged.git', :tag => spec.version }
  spec.source_files = 'Source/**/*.{swift}'

  # Minimum supported versions
  spec.swift_version         = '5.3'
  spec.ios.deployment_target = '13.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']
  
  # This adapter is compatible with Chartboost Core 1.0+ versions of the SDK.
  spec.dependency 'ChartboostCoreSDK', '~> 1.0'

  # CMP SDK and version that this adapter is certified to work with.
  # spec.dependency 'n/a', '~> 1.0.0'

  # The CMP SDK is a static framework which requires the static_framework option.
  spec.static_framework = true
end
