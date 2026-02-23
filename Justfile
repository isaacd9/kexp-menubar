xcodebuild := "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
project    := "kexp-menubar/kexp-menubar.xcodeproj"
scheme     := "kexp-menubar"
app_name   := "KEXP Menubar"
build_dir  := "build"
repo       := "isaacd9/kexp-menubar"
min_os     := "14.0"

build:
    {{xcodebuild}} \
        -project {{project}} \
        -scheme {{scheme}} \
        -configuration Debug \
        -derivedDataPath {{build_dir}}/derived \
        CONFIGURATION_BUILD_DIR={{justfile_directory()}}/{{build_dir}}/output/debug \
        MACOSX_DEPLOYMENT_TARGET={{min_os}} \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO

build-release:
    {{xcodebuild}} \
        -project {{project}} \
        -scheme {{scheme}} \
        -configuration Release \
        -derivedDataPath {{build_dir}}/derived \
        CONFIGURATION_BUILD_DIR={{justfile_directory()}}/{{build_dir}}/output/release \
        MACOSX_DEPLOYMENT_TARGET={{min_os}} \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO

run: build
    open "{{build_dir}}/output/debug/{{app_name}}.app"

release version:
    {{xcodebuild}} \
        -project {{project}} \
        -scheme {{scheme}} \
        -configuration Release \
        -derivedDataPath {{build_dir}}/derived \
        CONFIGURATION_BUILD_DIR={{justfile_directory()}}/{{build_dir}}/output/release \
        MACOSX_DEPLOYMENT_TARGET={{min_os}} \
        MARKETING_VERSION={{version}} \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO
    codesign --sign - --force --deep "{{build_dir}}/output/release/{{app_name}}.app"
    ditto -c -k --keepParent "{{build_dir}}/output/release/{{app_name}}.app" "{{build_dir}}/{{app_name}}-{{version}}.zip"
    gh release create v{{version}} \
        "{{build_dir}}/{{app_name}}-{{version}}.zip" \
        --repo {{repo}} \
        --title "v{{version}}"

clean:
    rm -rf {{build_dir}}
