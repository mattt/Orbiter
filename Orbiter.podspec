Pod::Spec.new do |s|
  s.name     = 'Orbiter'
  s.version  = '2.1.0'
  s.license  = 'MIT'
  s.summary  = 'Push Notification Registration for iOS.'
  s.homepage = 'https://github.com/mattt/Orbiter'
  s.social_media_url = 'https://twitter.com/mattt'
  s.authors  = { 'Mattt Thompson' => 'm@mattt.me' }
  s.source   = { :git => 'https://github.com/mattt/Orbiter.git', :tag => '2.1.0' }
  s.source_files = 'Orbiter'

  s.requires_arc = true

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  s.dependency 'AFNetworking', '~> 3.0'
end
