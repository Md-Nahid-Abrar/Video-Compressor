#!/bin/bash
#
# Builds FFmpeg for iOS and packages it, together with FFmpeg's command-line front end,
# as Vendor/FFmpeg/FFmpegCmd.xcframework (a dynamic framework, as the LGPL requires).
#
# Usage: Scripts/build-ffmpeg.sh [simulator|device|all]     (default: all)
#
# The result is committed to the repository, so this only needs to be run again to
# change the FFmpeg version or its configuration.
set -euo pipefail

VERSION="8.1"
SHA256="b072aed6871998cce9b36e7774033105ca29e33632be5b6347f3206898e0756a"
MIN_IOS="26.0"
BUNDLE_ID="com.mdnahidabrar.FFmpegCmd"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# FFmpeg's build system cannot handle spaces in paths, so the work area lives outside the project.
WORK="${FFMPEG_BUILD_DIR:-$HOME/Library/Caches/VideoCompressorFFmpeg}"
case "$WORK" in *" "*) echo "error: FFMPEG_BUILD_DIR must not contain spaces" >&2; exit 1 ;; esac
SRC="$WORK/ffmpeg-$VERSION"
SHIM="$ROOT/Vendor/FFmpegCommand"
OUT="$ROOT/Vendor/FFmpeg"
WHAT="${1:-all}"

# Only what the app uses: read MP4/MOV with H.264, HEVC and common audio; write HEVC + AAC in MP4.
# Everything here is LGPL; no GPL or non-free components are enabled.
CONFIGURE_FLAGS=(
    --enable-cross-compile --target-os=darwin --arch=arm64
    --enable-static --disable-shared --enable-pic
    --disable-debug --disable-doc --disable-autodetect
    --disable-ffplay --disable-ffprobe --enable-ffmpeg
    --disable-avdevice --disable-network
    --disable-everything
    --enable-videotoolbox --enable-audiotoolbox
    --enable-protocol=file
    --enable-demuxer=mov
    --enable-muxer=mp4
    --enable-decoder=h264,hevc,aac,aac_latm,alac,mp3,ac3,eac3,pcm_s16le,pcm_s16be,pcm_s24le,pcm_s24be,pcm_f32le
    --enable-encoder=hevc_videotoolbox,aac
    --enable-parser=h264,hevc,aac
    --enable-bsf=aac_adtstoasc,extract_extradata,h264_mp4toannexb,hevc_mp4toannexb
    --enable-filter=scale,fps,format,null,setsar,transpose,hflip,vflip,rotate,aformat,aresample,anull
)

fetch_source() {
    mkdir -p "$WORK"
    local archive="$WORK/ffmpeg-$VERSION.tar.xz"
    if [ ! -f "$archive" ]; then
        echo "Downloading FFmpeg $VERSION…"
        curl -fsSL -o "$archive" "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.xz"
    fi
    echo "$SHA256  $archive" | shasum -a 256 -c - >/dev/null || {
        echo "error: checksum mismatch for $archive" >&2
        exit 1
    }
    if [ ! -d "$SRC" ]; then
        tar -xf "$archive" -C "$WORK"
    fi
}

# Adapts fftools/ffmpeg.c to be called repeatedly from inside an app:
#   - main() becomes ffmpeg_main(), with a thin main() kept so the stock program still links
#   - signal handlers are not installed (the host app owns them)
#   - counters that the stock program leaves set at exit are reset before each run
#   - cancellation can be requested without a signal
patch_source() {
    python3 - "$SRC/fftools/ffmpeg.c" <<'PY'
import sys
path = sys.argv[1]
source = open(path).read()
marker = "/* FFmpegCmd in-process additions */"
if marker in source:
    sys.exit(0)

def replace_once(text, old, new):
    if text.count(old) != 1:
        sys.exit(f"error: expected exactly one occurrence of: {old!r}")
    return text.replace(old, new)

source = replace_once(source, "int main(int argc, char **argv)\n{", "int ffmpeg_main(int argc, char **argv);\nint ffmpeg_main(int argc, char **argv)\n{")
source = replace_once(source, "void term_init(void)\n{", "void term_init(void)\n{\n    /* FFmpegCmd: leave signal handling to the host app. */\n    return;\n")
source += f'''
{marker}
void ffcmd_reset_state(void);
void ffcmd_request_cancel(void);

void ffcmd_reset_state(void)
{{
    received_sigterm    = 0;
    received_nb_signals = 0;
    atomic_store(&transcode_init_done, 0);
    ffmpeg_exited       = 0;
    copy_ts_first_pts   = AV_NOPTS_VALUE;
    nb_input_files      = 0;
    nb_output_files     = 0;
    nb_filtergraphs     = 0;
    nb_decoders         = 0;
}}

void ffcmd_request_cancel(void)
{{
    received_sigterm = SIGINT;
    received_nb_signals++;
}}

int main(int argc, char **argv)
{{
    return ffmpeg_main(argc, argv);
}}
'''
open(path, "w").write(source)
PY
}

# build <name> <sdk> <target triple> <platform name for Info.plist>
build() {
    local name="$1" sdk="$2" target="$3" platform="$4"
    local build="$WORK/build-$name"
    local sysroot cc flags
    sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
    cc="$(xcrun --sdk "$sdk" -f clang)"
    flags="-target $target -isysroot $sysroot"

    echo "== Configuring FFmpeg for $name =="
    mkdir -p "$build"
    cd "$build"
    "$SRC/configure" "${CONFIGURE_FLAGS[@]}" \
        --cc="$cc" --extra-cflags="$flags" --extra-ldflags="$flags" > configure.log

    echo "== Compiling FFmpeg for $name =="
    make -j"$(sysctl -n hw.ncpu)" > make.log 2>&1 || { tail -30 make.log; exit 1; }

    echo "== Linking FFmpegCmd for $name =="
    "$cc" $flags -O2 -I"$SRC" -I"$build" -I"$SHIM" -c "$SHIM/ffcmd.c" -o ffcmd.o
    local framework="$build/FFmpegCmd.framework"
    rm -rf "$framework"
    mkdir -p "$framework/Headers" "$framework/Modules"
    # shellcheck disable=SC2046
    "$cc" $flags -dynamiclib -o "$framework/FFmpegCmd" \
        $(find fftools -name '*.o') ffcmd.o \
        libavfilter/libavfilter.a libavformat/libavformat.a libavcodec/libavcodec.a \
        libswresample/libswresample.a libswscale/libswscale.a libavutil/libavutil.a \
        -framework VideoToolbox -framework AudioToolbox -framework CoreMedia \
        -framework CoreVideo -framework CoreFoundation -framework CoreServices \
        -lm -lpthread \
        -install_name "@rpath/FFmpegCmd.framework/FFmpegCmd" \
        -Wl,-exported_symbols_list,"$SHIM/exports.txt" -Wl,-dead_strip
    cp "$SHIM/FFmpegCmd.h" "$framework/Headers/"
    cp "$SHIM/module.modulemap" "$framework/Modules/"
    cat > "$framework/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleExecutable</key><string>FFmpegCmd</string>
	<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>FFmpegCmd</string>
	<key>CFBundlePackageType</key><string>FMWK</string>
	<key>CFBundleShortVersionString</key><string>$VERSION</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>
	<key>MinimumOSVersion</key><string>$MIN_IOS</string>
</dict>
</plist>
PLIST
    cd "$ROOT"
}

package() {
    local frameworks=()
    for name in device simulator; do
        if [ -d "$WORK/build-$name/FFmpegCmd.framework" ]; then
            frameworks+=(-framework "$WORK/build-$name/FFmpegCmd.framework")
        fi
    done
    mkdir -p "$OUT"
    rm -rf "$OUT/FFmpegCmd.xcframework"
    xcodebuild -create-xcframework "${frameworks[@]}" -output "$OUT/FFmpegCmd.xcframework" | tail -1
    cp "$SRC/COPYING.LGPLv2.1" "$OUT/COPYING.LGPLv2.1"
}

fetch_source
patch_source
case "$WHAT" in
    simulator) build simulator iphonesimulator "arm64-apple-ios$MIN_IOS-simulator" iPhoneSimulator ;;
    device)    build device iphoneos "arm64-apple-ios$MIN_IOS" iPhoneOS ;;
    all)
        build simulator iphonesimulator "arm64-apple-ios$MIN_IOS-simulator" iPhoneSimulator
        build device iphoneos "arm64-apple-ios$MIN_IOS" iPhoneOS
        ;;
    *) echo "usage: $0 [simulator|device|all]" >&2; exit 1 ;;
esac
package
