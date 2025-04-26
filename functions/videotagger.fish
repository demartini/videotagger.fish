function videotagger --description "Smart Video Tagger"

    # -----------------------
    # MODE & OPTIONS
    set -l mode preview
    set -l recursive 0

    for arg in $argv
        switch $arg
            case -v --version
                echo "videotagger, version 0.1.0"
                return
            case --dry-run -d
                set mode dry-run
            case --recursive -R
                set recursive 1
            case --rename -r
                set mode rename
            case --undo -u
                set mode undo
            case --help -h
                echo "🎬 videotagger - Smart Video Tagger"
                echo
                echo "🧰 Usage:"
                echo "  videotagger                    → Show preview for all videos"
                echo "  videotagger -d, --dry-run      → Show only files that would be renamed"
                echo "  videotagger -h, --help         → Display available options"
                echo "  videotagger -R, --recursive    → Search videos in subfolders"
                echo "  videotagger -r, --rename       → Apply renaming and save log"
                echo "  videotagger -u, --undo         → Undo last renaming using log"
                echo "  videotagger -v, --version      → Print version information"
                echo
                return
            case '*'
                echo "❌ Unknown option: $arg"
                echo "ℹ️ Use --help to see available options."
                return 1
        end
    end

    # -----------------------
    # DEPENDENCY CHECK
    if not type -q ffprobe
        echo "❌ 'ffprobe' (from ffmpeg) is required but not found in your system."
        echo "💡 Please install ffmpeg to use videotagger."
        return 1
    end

    set -l log_file ".videotagger.log"

    # -----------------------
    # FUNCTIONS

    # _videotagger_get_resolution
    # → Returns video height (e.g., 720) using ffprobe
    function _videotagger_get_resolution --argument file
        ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$file"
    end

    # _videotagger_get_video_codec
    # → Returns video codec name in uppercase (e.g., H264, HEVC)
    function _videotagger_get_video_codec --argument file
        ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file" | tr '[:lower:]' '[:upper:]'
    end

    # _videotagger_get_audio_info
    # → Parses all audio streams and returns:
    #    - audio tag (lang-codec-channels)
    #    - human-readable display string
    function _videotagger_get_audio_info --argument file
        set -l audio_streams (ffprobe -v error -select_streams a -show_entries stream=index:stream_tags=language -show_entries stream=codec_name,channels -of default=noprint_wrappers=1 "$file")
        set -l codec_channel_parts
        set -l audio_display_parts
        set -l languages
        set -l current_codec ""
        set -l current_channels ""

        for line in $audio_streams
            switch $line
                case "codec_name=*"
                    set current_codec (string replace "codec_name=" "" "$line" | tr '[:lower:]' '[:upper:]')
                case "channels=*"
                    set ch (string replace "channels=" "" "$line")
                    set current_channels "$ch.0"
                case "TAG:language=*"
                    set lang (string replace "TAG:language=" "" "$line" | tr '[:lower:]' '[:upper:]')
                    if test -z "$lang"
                        set lang UND
                    end

                    set codec_channel_parts $codec_channel_parts "$current_codec$current_channels"
                    set languages $languages "$lang"
                    set audio_display_parts $audio_display_parts "$current_codec$current_channels ($lang)"
            end
        end

        set audio_tag (string join "-" $codec_channel_parts)

        set audio_count (count $codec_channel_parts)

        if test $audio_count -eq 2
            set audio_tag "DUAL-$audio_tag"
        else if test $audio_count -gt 2
            set audio_tag "MULT-$audio_tag"
        else if test $audio_count -eq 1
            if test "$languages[1]" != UND
                set audio_tag "$languages[1]-$audio_tag"
            end
        end

        echo "$audio_tag:::"(string join " + " $audio_display_parts)
    end

    # _videotagger_get_subtitle_info
    # → Parses subtitle languages and returns:
    #    - subtitle tag (e.g., ENGSub, MSubs)
    #    - readable label (e.g., ENG, Multiple languages)
    function _videotagger_get_subtitle_info --argument file
        set subtitle_langs (ffprobe -v error -select_streams s -show_entries stream_tags=language -of default=nw=1:nk=1 "$file" | grep -v '^$' | tr '[:lower:]' '[:upper:]')
        set subtitle_langs (string split \n -- $subtitle_langs | sort -u)
        set subtitle_count (count $subtitle_langs)

        set subtitle_tag ""
        set subtitle_msg None

        if test $subtitle_count -gt 1
            set subtitle_tag MSubs
            set subtitle_msg "MULT | "(string join " / " $subtitle_langs)
        else if test $subtitle_count -eq 1
            set lang $subtitle_langs[1]
            if test -n "$lang" -a "$lang" != UND
                set subtitle_tag $lang"Sub"
                set subtitle_msg $lang
            end
        end

        echo "$subtitle_tag:::$subtitle_msg"
    end

    # _videotagger_build_new_filename
    # → Constructs the new filename from its components
    function _videotagger_build_new_filename
        set base $argv[1]
        set ext $argv[2]
        set res_tag $argv[3]
        set audio_tag $argv[4]
        set video_codec $argv[5]
        set subtitle_tag $argv[6]

        set newname "$res_tag.WEB-DL.$audio_tag.$video_codec"
        if test -n "$subtitle_tag"
            set newname "$newname.$subtitle_tag"
        end
        echo "$base.$newname.$ext"
    end

    # _videotagger_strip_existing_tags
    # → Cleans previous tags from filename to avoid duplication
    function _videotagger_strip_existing_tags --argument filename
        set cleaned $filename
        set cleaned (string replace -r '\.\d{3,4}p\.WEB-DL\.[A-Z0-9\-+]+\.[A-Z0-9]+(\.[A-Z0-9]+)?(\.(MSubs|[A-Z]{2,3}Sub))?' '' $cleaned)
        set cleaned (string replace -r '\.(WEB-DL|H264|HEVC|AAC2\.0|AC3|EAC3|FLAC|OPUS|MSubs|[A-Z]{2,3}Sub)' '' $cleaned)
        set cleaned (string replace -r '\.\d{3,4}p' '' $cleaned)
        echo $cleaned
    end

    # _videotagger_find_video_files
    # → Returns a list of video files based on current mode (recursive or not)
    #    If --recursive is active, searches subdirectories
    function _videotagger_find_video_files --argument do_recursive
        if test "$do_recursive" = 1
            find . -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" \)
        else
            for ext in mp4 mkv mov
                for f in *.$ext
                    if test -e "$f"
                        echo "$f"
                    end
                end
            end
        end
    end

    # -----------------------
    # UNDO MODE
    if test "$mode" = undo
        if not test -f "$log_file"
            echo "⚠️ No renaming log found."
            return 1
        end

        echo "↩️ Reverting renamed files:"
        echo

        for line in (cat "$log_file")
            set from (string split ' → ' -- $line)[2]
            set to (string split ' → ' -- $line)[1]

            echo "🔁 From: $from"
            echo "➡️   To:   $to"

            if test -e "$from"
                mv "$from" "$to"
            else
                echo "⚠️ File not found: $from"
            end

            echo
        end

        rm -f "$log_file"
        echo "✅ Undo complete. Log removed."
        return
    end

    # -----------------------
    # MAIN LOOP
    set -l files (_videotagger_find_video_files $recursive)

    if test (count $files) -eq 0
        echo "📂 No video files found in this directory."
        echo "💡 Supported formats: .mp4, .mkv, .mov"
        return
    end

    echo

    for file in $files
        if not test -e "$file"
            continue
        end

        set height (_videotagger_get_resolution "$file")

        if test -z "$height"
            echo "⚠️ Skipping $file (could not extract resolution)"
            echo -----------------------------------------------------
            continue
        end

        set res_tag "$height"p
        set video_codec (_videotagger_get_video_codec "$file")

        set audio_info (_videotagger_get_audio_info "$file")
        set audio_tag (string split ":::" $audio_info)[1]
        set audio_display (string split ":::" $audio_info)[2]

        set subtitle_info (_videotagger_get_subtitle_info "$file")
        set subtitle_tag (string split ":::" $subtitle_info)[1]
        set subtitle_msg (string split ":::" $subtitle_info)[2]

        set ext (string split "." -- "$file")[-1]
        set full_name (string join "." (string split "." -- "$file")[1..-2])
        set base (_videotagger_strip_existing_tags $full_name)
        set newname (_videotagger_build_new_filename "$base" "$ext" "$res_tag" "$audio_tag" "$video_codec" "$subtitle_tag")

        if test "$mode" = dry-run
            if test "$file" = "$newname"
                continue
            end
        end

        echo "🎬 File:        $file"
        echo "📺 Resolution:  $res_tag"
        echo "🎥 Video:       $video_codec"
        echo "🔊 Audio:       $audio_display"
        echo "💬 Subtitle:    $subtitle_msg"
        echo "📝 New name:    $newname"

        if test "$mode" = rename
            if test "$file" != "$newname"
                mv -v "$file" "$newname"
                echo "$file → $newname" >>"$log_file"
            else
                echo "⚠️ Filename already correct."
            end
        end

        echo -----------------------------------------------------
    end

    echo

    switch $mode
        case preview
            echo "ℹ️ Preview complete. No changes made."
            echo "📝 Use --rename to apply changes, or --dry-run to filter only rename candidates."
        case dry-run
            echo "ℹ️ Dry-run complete. These files would be renamed."
        case rename
            echo "✅ Renaming complete."
            echo "🪵 Log saved to: $log_file"
    end
end
