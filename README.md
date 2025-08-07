# Notem

A very simple bash markdown notes tool for creating and managing notes, including daily "diary"-style entries.

## Features

- Create daily notes with automatic date-based organization
- Use customizable templates for notes
- Simple configuration system
- Support for XDG config directory
- Automatic YAML frontmatter generation
- Template variable substitution (date, author, etc.)

## Installation

1. Download the script:
```bash
git clone https://github.com/leblancja/notem.git
cd notem
```

2. Make it executable:
```bash
chmod +x notem.sh
```

3. Optionally, move it to your PATH:
```bash
sudo mv notem.sh /usr/local/bin/notem
```

## Configuration

On first run, Notem will create a configuration file in one of these locations (in order of preference):
- `$XDG_CONFIG_HOME/notem/config`
- `$HOME/.notemrc`

You can customize the following settings:

| Setting | Description | Default |
|---------|-------------|---------|
| `NOTES_ROOT` | Base directory for all notes | `$HOME/notes` |
| `REGULAR_NOTES_DIR` | Directory for non-daily notes | Same as `NOTES_ROOT` |
| `TEMPLATES_DIR` | Directory for note templates | `$HOME/.templates` |

## Usage

### Basic Usage

```bash
notem [-d] [-t template_name] [-n note_name]
```

### Options

- `-d`: Create a daily note. Notes will be organized in `NOTES_ROOT/daily/YEAR/MONTH/daily-YYYY-MM-DD.md`
- `-t`: Specify a template to use (template should exist in `TEMPLATES_DIR`)
- `-n`: Specify a name for the note (only applies to non-daily notes)

### Examples

1. Create a daily note:
```bash
notem -d
```

2. Create a note using a template:
```bash
notem -t meeting
```

3. Create a named note:
```bash
notem -n "project-ideas"
```

4. Create a named note with a template:
```bash
notem -n "meeting-minutes" -t meeting
```

## Templates

Templates are markdown files stored in `TEMPLATES_DIR`. They support the following variables:

- `{{date}}` - Current date (YYYY-MM-DD)
- `{{author}}` - Current user
- `{{year}}` - Current year
- `{{month}}` - Current month
- `{{day}}` - Current day
- `{{weekday}}` - Current day of the week

If no template is specified, a basic YAML frontmatter will be added automatically:

```yaml
---
date: YYYY-MM-DD HH:MM:SS
timezone: +HHMM
author: username
---
```

## Directory Structure

```
NOTES_ROOT/
├── daily/
│   └── YEAR/
│       └── MONTH/
│           └── daily-YYYY-MM-DD.md
└── other-notes.md
```

## License

This software is released into the public domain (Unlicense). See the LICENSE file for more details.

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.
