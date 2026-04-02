xcodebuild := "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
project    := "kexp-menubar/kexp-menubar.xcodeproj"
scheme     := "kexp-menubar"
app_name   := "KEXP Menubar"
bundle_id  := "isaac.kexp-menubar"
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
        MARKETING_VERSION="$(tr -d '\n' < "{{justfile_directory()}}/VERSION")" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO

run: build
    -osascript -e 'tell application id "{{bundle_id}}" to quit'
    -pkill -x "{{app_name}}"
    sleep 0.2
    open -n "{{justfile_directory()}}/{{build_dir}}/output/debug/{{app_name}}.app"

release: build-release
    codesign --sign - --force --deep "{{build_dir}}/output/release/{{app_name}}.app"
    ditto -c -k --keepParent "{{build_dir}}/output/release/{{app_name}}.app" "{{build_dir}}/{{app_name}}-$(tr -d '\n' < "{{justfile_directory()}}/VERSION").zip"
    gh release create "v$(tr -d '\n' < "{{justfile_directory()}}/VERSION")" \
        "{{build_dir}}/{{app_name}}-$(tr -d '\n' < "{{justfile_directory()}}/VERSION").zip" \
        --repo {{repo}} \
        --title "v$(tr -d '\n' < "{{justfile_directory()}}/VERSION")"

clean:
    rm -rf {{build_dir}}
