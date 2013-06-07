Pod::Spec.new do |s|
  s.name     = 'LKDBHelper'
  s.version  = '1.0'
  s.summary  = 'this is sqlite ORM (an automatic database operation)'
  s.homepage = 'https://github.com/mcgtts/LKDBHelper'
  s.license  = 'Apache 2.0'
  s.author   = { 'gtts' => 'gtts@outlook.com' }
  s.source   = { :git => 'https://github.com/mcgtts/LKDBHelper', :tag => "1.1"}
  s.platform     = :ios
  s.source_files = 'LKDBHelper/Helper/*.{h,m}'
end