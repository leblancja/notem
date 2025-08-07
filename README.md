HOW TO USE

This is just a shell script. 
Download it, make it executable (chmod +x).

Running it for the first time will create a config file in ~/.notemrc. Optionally you can create $XDG_CONFIG_HOME/notem/config
The script checks $XDG_CONFIG_HOME first.

Here are some optional flags:

-d   Create a daily note. Daily notes are placed in a special directory and are titled with today's date. If a daily note for today already exists, it will simply be opened.
-t   (optional) Specify a template file to use. The template file will be copied, and any placeholders such as {{day}}, {{month}}, {{year}}, {{weekday}} will be replaced with current datetime info.
-n   (optional) Specify a name for the note. Only applies to non-daily notes. Notes created with -d will ignore this flag.

Running notem with no flags will create a new regular note in the configured REGULAR_NOTES_DIR

CONFIG

NOTES_ROOT           path where all notes will reside
REGULAR_NOTES_DIR    directory where regular (non-daily) notes will be created
TEMPLATE_DIR         directory where notem will look for note templates
