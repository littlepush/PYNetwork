# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'

target 'PYNetwork' do

pod 'PYCore'
pod 'PYData'

end

post_install do |installer|

    default_library = installer.libraries.detect { |i| i.target_definition.name == 'PYNetwork' }

    release_config_file_path = default_library.library.xcconfig_path('Release')
    debug_config_file_path = default_library.library.xcconfig_path('Debug')

    File.open("config.release.tmp", "w") do |io|
        io << File.read(release_config_file_path).gsub(/-l\"sqlite3\"/, '')
    end

    FileUtils.mv("config.release.tmp", release_config_file_path)

    File.open("config.debug.tmp", "w") do |io|
        io << File.read(debug_config_file_path).gsub(/-l\"sqlite3\"/, '')
    end

    FileUtils.mv("config.debug.tmp", debug_config_file_path)

end
