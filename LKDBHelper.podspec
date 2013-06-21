Pod::Spec.new do |s|
  s.name         = "LKDBHelper"
  s.version      = "1.1"
  s.summary      = "this is sqlite ORM (an automatic database operation) 
thread-safe and not afraid of recursive deadlock."

  s.homepage     = "https://github.com/li6185377/LKDBHelper-SQLite-ORM.git"
  s.license      = 'MIT'

  s.author       = { "li6185377" => "li6185377@163.com" }

  s.source       = { :git => "https://github.com/li6185377/LKDBHelper-SQLite-ORM.git", :tag => s.version.to_s }

  s.platform     = :ios, '4.3'

  s.source_files = 'LKDBHelper/Helper/*.{h,m}'
  s.requires_arc = true

  s.dependency 'FMDB'
end
