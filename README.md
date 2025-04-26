<div align="center">
  <img align="center" src=".github/media/logo.png?raw=true" alt="Logo" width="200">
</div>

<h1 align="center">videotagger.fish</h1>

<p align="center">Smart Video Tagger and Renamer.</p>

<div align="center">

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

</div>

## Table of Contents <!-- omit in toc -->

- [About](#about)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Example output](#example-output)
- [Contributing](#contributing)
- [Changelog](#changelog)
- [License](#license)

## About

If you run a media server (Plex, Radarr, Sonarr, etc), you know how important it is to keep your library clean and consistent.

But when downloading video files manually, filenames often come messy, inconsistent, and break automation — or just clutter your collection.

`videotagger` helps fix that.

It intelligently analyzes your video files (using `ffprobe`) and generates new, standardized filenames that reflect each file's resolution, codec, audio layout, and subtitles — all without requiring any manual tagging.

It's built for speed, flexibility, and everyday use.

<p align="right">(<a href="#top">back to top</a>)</p>

## Features

- 📺 Detects and tags resolution (e.g. `720p`, `1080p`)
- 🎥 Detects video codec (`H264`, `HEVC`, etc.)
- 🔊 Tags audio tracks by codec, channel layout and language (`AAC2.0 (ENG)`)
- 💬 Includes subtitle info (e.g. `MSubs`, `ENGSub`)
- 📝 Renames files using a consistent `scene-style` format
- 📦 Pre-processes filenames to avoid duplicate tags
- 🈳 Fallback to `UND` for undefined language streams
- 🚫 Skips files with missing resolution or invalid metadata
- 🧪 Dry-run mode for safe previews
- 🔁 Undo feature with log tracking
- 📁 Recursive support for batch folders
- 🐚 Native Fish Shell script — no external dependencies (besides `ffmpeg`)

<p align="right">(<a href="#top">back to top</a>)</p>

## Requirements

- [Fish Shell][fishshell-url] v3.0+
- [ffmpeg][ffmpeg-url] (which includes `ffprobe`, required for media analysis)

You can install `ffmpeg` via:

```console
brew install ffmpeg      # macOS (Homebrew)
sudo apt install ffmpeg  # Debian/Ubuntu
```

<p align="right">(<a href="#top">back to top</a>)</p>

## Installation

Install with [Fisher][fisher-url]:

```console
fisher install demartini/videotagger.fish
```

<p align="right">(<a href="#top">back to top</a>)</p>

## Usage

| Command                         | Description                           |
| ------------------------------- | ------------------------------------- |
| `videotagger`                   | Preview all videos in current folder  |
| `videotagger -d`, `--dry-run`   | Show only files that would be renamed |
| `videotagger -r`, `--rename`    | Rename files and save a log           |
| `videotagger -u`, `--undo`      | Undo last renaming                    |
| `videotagger -R`, `--recursive` | Recursively scan subfolders           |
| `videotagger -v`, `--version`   | Show version                          |
| `videotagger -h`, `--help`      | Display help message                  |

> 💡 Tip: You can also use `vt` as a shortcut alias for `videotagger`.

### Example output

```console
🎬 File:        Some.Movie.2023.mp4
📺 Resolution:  1080p
🎥 Video:       H264
🔊 Audio:       AAC2.0 (ENG)
💬 Subtitle:    Multiple languages (2)
📝 New name:    Some.Movie.2023.1080p.WEB-DL.ENG-AAC2.0.H264.MSubs.mp4
```

<p align="right">(<a href="#top">back to top</a>)</p>

## Contributing

If you are interested in helping contribute, please take a look at our [contribution guidelines][contributing-url] and open an [issue][issues-url] or [pull request][pull-request-url].

<p align="right">(<a href="#top">back to top</a>)</p>

## Changelog

See [CHANGELOG][changelog-url] for a human-readable history of changes.

<p align="right">(<a href="#top">back to top</a>)</p>

## License

Distributed under the MIT License. See [LICENSE][license-url] for more information.

<p align="right">(<a href="#top">back to top</a>)</p>

[changelog-url]: https://github.com/demartini/videotagger.fish/blob/main/CHANGELOG.md
[contributing-url]: https://github.com/demartini/.github/blob/main/CONTRIBUTING.md
[pull-request-url]: https://github.com/demartini/videotagger.fish/pulls

[contributors-shield]: https://img.shields.io/github/contributors/demartini/videotagger.fish.svg?style=for-the-badge&color=8bd5ca&labelColor=181926
[contributors-url]: https://github.com/demartini/videotagger.fish/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/demartini/videotagger.fish.svg?style=for-the-badge&color=8bd5ca&labelColor=181926
[forks-url]: https://github.com/demartini/videotagger.fish/network/members
[issues-shield]: https://img.shields.io/github/issues/demartini/videotagger.fish.svg?style=for-the-badge&color=8bd5ca&labelColor=181926
[issues-url]: https://github.com/demartini/videotagger.fish/issues
[license-shield]: https://img.shields.io/github/license/demartini/videotagger.fish.svg?style=for-the-badge&color=8bd5ca&labelColor=181926
[license-url]: https://github.com/demartini/videotagger.fish/blob/main/LICENSE
[stars-shield]: https://img.shields.io/github/stars/demartini/videotagger.fish.svg?style=for-the-badge&color=8bd5ca&labelColor=181926
[stars-url]: https://github.com/demartini/videotagger.fish/stargazers

[fishshell-url]: https://fishshell.com
[ffmpeg-url]: https://www.ffmpeg.org
[fisher-url]: https://github.com/jorgebucaran/fisher
