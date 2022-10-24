Pod::Spec.new do |s|
  s.name         = "TapTapUIButton"
  s.version      = "1.0"
  s.summary      = 'UIButton double click event extension(Objc, swift, xib, selected)'
  s.homepage     = 'https://github.com/Meterwhite/TapTapUIButton'
  s.license      = 'MIT'
  s.author       = { "Meterwhite" => "meterwhite@outlook.com" }
  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.requires_arc = true
  s.source       = { :git => "https://github.com/Meterwhite/TapTapUIButton.git", :tag => s.version}
  s.source_files = 'TapTapUIButton/**/*.{h,m}'
end
