# Alias for quick access
abbr -a vt videotagger

# On installation
function _videotagger_install --on-event videotagger_install
    echo "🎬 Installing videotagger..."

    # Set alias again in case conf.d was skipped
    abbr -a vt videotagger

    # Check for ffmpeg
    if not type -q ffmpeg
        echo "⚠️ 'ffmpeg' is not installed. videotagger requires ffmpeg/ffprobe to work properly."
        echo "💡 Install it using your package manager:"
        echo "    brew install ffmpeg      # macOS"
        echo "    sudo apt install ffmpeg  # Debian/Ubuntu"
    else
        echo "✅ ffmpeg is installed."
    end
end

# On update
function _videotagger_update --on-event videotagger_update
    echo "🔄 videotagger was updated."
end

# On uninstall
function _videotagger_uninstall --on-event videotagger_uninstall
    echo "🧹 Uninstalling videotagger..."

    # Remove alias
    abbr -e vt

    # Erase all internal functions
    for func in (functions -n | string match -r '^_videotagger')
        functions -e $func
    end

    echo "✅ Cleanup complete."
end
