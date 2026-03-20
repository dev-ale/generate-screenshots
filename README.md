# rCoon App Store Screenshot Generator

Generates App Store screenshots for rCoon by compositing iPhone screenshots onto styled backgrounds with headlines and subtitles.

**Target:** iPhone 15/16 Pro Max — 1290 x 2796px

## Prerequisites

- **ImageMagick 7+** — `brew install imagemagick`
- **Poppins font** — downloaded automatically to `/tmp/poppins-font/` (Bold + Medium)

To download the fonts manually:

```bash
mkdir -p /tmp/poppins-font
curl -sL "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf" -o /tmp/poppins-font/Poppins-Bold.ttf
curl -sL "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Medium.ttf" -o /tmp/poppins-font/Poppins-Medium.ttf
```

## Usage

```bash
# Generate all dark screenshots (default config)
./generate.sh

# Generate all bright screenshots
./generate.sh -c bright

# Generate specific screenshots by number
./generate.sh 1 3 7

# Combine config variant with specific numbers
./generate.sh -c bright 1 3 7
```

## Project Structure

```
.
├── generate.sh                  # Main generator script
├── screenshots.conf             # Dark screenshot config (12 entries)
├── screenshots_bright.conf      # Bright screenshot config (10 entries)
├── iphones/                     # iPhone screenshots (raw PNGs from device)
│   ├── home_dark.png
│   ├── home_bright.png
│   ├── similiar_photos_overview_dark.png
│   └── ...
├── backgrounds/                 # Cached backgrounds (auto-generated)
│   └── warm_blobs_light.png
├── output/                      # Generated App Store screenshots
│   ├── warm_blobs_light_home_dark.png
│   ├── warm_blobs_light_home_bright.png
│   └── ...
└── README.md
```

## Config Format

Each `.conf` file defines one screenshot per line:

```
iphone_file|headline|subtitle
```

- **iphone_file** — filename in `iphones/` without `.png` extension
- **headline** — main text, use `\n` for line breaks
- **subtitle** — smaller text below the headline
- Lines starting with `#` are comments

Example:

```
home_dark|Your phone, analyzed.|3 AI scans. One tap.
similiar_photos_overview_dark|More duplicates\nthan you think.|AI finds them. You decide.
```

## Output Naming

Output files are named by combining the background and iPhone names:

```
{background}_{iphone}.png
```

Example: `warm_blobs_light_home_dark.png`

## Layout

The script automatically adjusts layout based on headline line count:

- **1-line headlines** — pushed down with more top margin, closer to the phone
- **2-line headlines** — positioned higher with standard top margin
- **Subtitle** — always positioned dynamically with a tight 25px gap below the headline
- **Phone** — scaled to 82% width with a drop shadow, bleeding off the bottom edge

## Customization

Key layout variables in `generate.sh`:

| Variable | Default | Description |
|---|---|---|
| `PHONE_SCALE` | 82 | Phone width as % of screenshot width |
| `TOP_PAD` | 60 | Top margin for 2-line headlines |
| `HEADLINE_SIZE` | 90 | Headline font size (pt) |
| `SUBTITLE_SIZE` | 64 | Subtitle font size (pt) |
| `SUBTITLE_GAP` | 25 | Pixels between headline and subtitle |
| `PHONE_Y` | 460 | Phone Y offset from top |
| `BG_FILE` | warm_blobs_light.png | Background filename in `backgrounds/` |

## Adding a New Config Variant

1. Create `screenshots_myvariant.conf` with the same pipe-delimited format
2. Run `./generate.sh -c myvariant`

## Adding a New Background

Place a 1290x2796 PNG in `backgrounds/` and update `BG_FILE` in `generate.sh`. If no cached background exists, the script generates one with warm light blobs and saves it automatically.
