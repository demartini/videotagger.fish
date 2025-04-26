#!/usr/bin/env fish
#
# videotagger.test.fish
#
# Integration tests for videotagger.fish using fishtape
#
# Test groups:
# 1. Environment/Dependency checks
# 2. Basic operations (find videos, recursion, empty dir)
# 3. Error handling (invalid options, missing logs)
# 4. File renaming behavior (correct naming, tag stripping)
#
# Each test is isolated and creates its own temporary environment when necessary.

set -l testdir (dirname (status --current-filename))
set -l assetdir "$testdir/assets"

functions --query videotagger || exit 1

# Helper: Runs a block inside a temp dir
function _with_temp_dir --argument cmd
    set -l temp (mktemp -d)
    pushd $temp
    eval $cmd
    set -l code $status
    popd
    rm -rf $temp
    echo $code
end

# --- Environment / Dependency Checks ---
@test "videotagger is available" (functions --query videotagger; echo $status) -eq 0

@test "fails without ffprobe" (
    set old_path $PATH
    set PATH ""
    videotagger --dry-run 2>&1 | string match -q '*ffprobe*'
    set code $status
    set PATH $old_path
    echo $code
) -eq 0

# --- Basic Operations ---
@test "finds video files" (
    pushd $assetdir
    videotagger --dry-run | grep -q "🎬 File:"
    set code $status
    popd
    echo $code
) -eq 0

@test "finds files recursively" (
    _with_temp_dir "
        mkdir -p subdir;
        cp $assetdir/simple.mp4 subdir/;
        videotagger --dry-run --recursive | grep -q '🎬 File:.*simple.mp4'
    "
) -eq 0

@test "no files in empty dir" (
    _with_temp_dir "videotagger --dry-run | grep -q '📂 No video files found'"
) -eq 0

# --- Error Handling ---
@test "fails on unknown option" (
    videotagger -w 2>&1 | string match -q '*Unknown option*'
    set code $status
    echo $code
) -eq 0

@test "undo without log fails cleanly" (
    pushd $assetdir
    videotagger --undo 2>&1 | string match -q '*No renaming log found*'
    set code $status
    popd
    echo $code
) -eq 0

# --- Rename Behavior ---
@test "renames file correctly" (
    _with_temp_dir "
        cp $assetdir/simple.mp4 .;
        videotagger --rename >/dev/null 2>&1;
        ls | grep -q 'simple.64p.WEB-DL.AAC2.0.H264.mp4'
    "
) -eq 0

@test "strips existing tags" (
    _with_temp_dir "
        cp $assetdir/simple.mp4 simple.720p.WEB-DL.AAC2.0.H264.mp4;
        videotagger --rename >/dev/null 2>&1;
        ls | grep -q 'simple.64p.WEB-DL.AAC2.0.H264.mp4'
    "
) -eq 0
