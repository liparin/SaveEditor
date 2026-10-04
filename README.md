# SaveEditor

A save file editor for games, driven by XML tables (similar to Cheat Engine tables, but for save files).

The application itself does not know any game format. It reads an XML table that describes offsets, data types, and hash settings, then applies that table to a binary save file.

## Requirements

- [Lazarus](https://www.lazarus-ide.org/) 2.0+ (or Delphi 10+ with minor adjustments)
- Free Pascal Compiler 3.0+

## Build

1. Clone the repository.
2. Open `SaveEditor.lpr` in Lazarus.
3. Press `F9` (Run) or `Ctrl+F9` (Compile).

## Usage

1. Launch the application.
2. Click **Load Table** and select an XML file (see `tables/template.xml`).
3. Click **Load Save** and select your save file.
4. Edit values in the grid.
5. Click **Save** to write changes back to the file (a `.bak` backup is created automatically).

## XML Table Format

See `tables/template.xml` for a full example.

## License

MIT
