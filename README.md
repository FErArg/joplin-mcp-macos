# Joplin MCP Server

[![Version](https://img.shields.io/badge/version-2.1.1-blue.svg)](CHANGELOG.md)
[![Python](https://img.shields.io/badge/python-3.9+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/license-GPL3-blue.svg)](LICENSE)

A Model Context Protocol (MCP) server for interacting with Joplin notes.

## Features

- **create_notebook**: Create notebooks directly from the MCP client
- **create_note**: Add new Markdown notes to a specific notebook
- **update_note**: Modify the title and/or body of an existing note
- **search_notes**: Search notes by keyword across all notebooks
- **read_note**: Read full note content in Markdown format
- **list_notebooks**: List all notebooks (folders) in Joplin

## Installation

📖 **Complete installation guide**: See [INSTALL.md](INSTALL.md) for detailed installation, configuration, and uninstallation instructions.

### Quick Installation

```bash
git clone <repository-url> joplin-mcp-macos
cd joplin-mcp-macos
./install.sh
```

The automatic installer will detect your Joplin token, configure the environment, and validate the installation. For more options and manual configuration, consult [INSTALL.md](INSTALL.md).

## macOS Compatibility

This fork is specifically optimised for macOS compatibility while maintaining Linux support.

### Requirements

- **macOS 12.3+** (Monterey or later)
- **Python 3.9+** (included with macOS 12.3+)
- **Xcode Command Line Tools**:
  ```bash
  xcode-select --install
  ```

### macOS-Specific Features

- ✅ Automatic Joplin detection at `~/Library/Application Support/Joplin/`
- ✅ BSD-compatible commands (no GNU dependencies required)
- ✅ Native Python 3.9+ support
- ✅ Works with macOS-native tools (no Homebrew required)

### What Works Differently on macOS

| Feature | Linux (GNU) | macOS (BSD) |
|---------|-------------|-------------|
| Python version detection | Uses GNU grep | Uses Python directly |
| Port checking | `netstat -tuln` | `netstat -an` |
| Process detection | `pgrep -f` | `ps aux \| grep` |
| File operations | GNU find extensions | POSIX shell globs |

See [MACOS.md](MACOS.md) for detailed compatibility analysis.

## Available Tools

### search_notes

Search for notes by keyword.

**Input**: `{"query": "search term"}`

**Example**:
```
⚙ joplin_search_notes [query="AI"]
Result:
- Machine Learning Notes (ID: abc123)
- AI Research Paper (ID: def456)
```

### read_note

Read the full content of a specific note.

**Input**: `{"note_id": "note-id-here"}`

**Example**:
```
⚙ joplin_read_note [note_id="abc123"]
Result:
# Machine Learning Notes

This is the markdown content of the note...
```

### list_notebooks

List all notebooks/folders in Joplin.

**Example**:
```
⚙ joplin_list_notebooks
Result:
- Work (ID: folder-abc)
- Personal (ID: folder-def)
- Research (ID: folder-ghi)
```

## Troubleshooting

### Error 403: Authentication failed

```bash
# Verify that the token works
curl "http://localhost:41184/notes?token=YOUR_TOKEN&limit=1"

# If it fails, reinstall with new token
./install.sh
```

### Error: Joplin server not available

```bash
# Verify that Joplin responds
~/.joplin-mcp/joplin-mcp-doctor.sh

# Ensure that:
# 1. Joplin desktop is running
# 2. Web Clipper is enabled (Options > Web Clipper > Enable)
# 3. Port 41184 is available
```

### Error: MCP server not responding

```bash
# Verify installation
~/.joplin-mcp/joplin-mcp-doctor.sh

# View logs
cat ~/.joplin-mcp/logs/install.log

# Reinstall if necessary
./install.sh
```

### Recover backup

If something goes wrong, you can restore the backup:

```bash
# View available backups
ls -la ~/.joplin-mcp/backup/

# Restore opencode configuration
cp ~/.joplin-mcp/backup/20250121_143022/opencode.json.backup ~/.config/opencode/opencode.json

# Or restore a JSONC config
cp ~/.joplin-mcp/backup/20250121_143022/opencode.jsonc.backup ~/.config/opencode/opencode.jsonc

# Or restore everything
rm -rf ~/.joplin-mcp
cp -r ~/.joplin-mcp-backup-20250121_143022 ~/.joplin-mcp
```

## Development

### Project Structure

```
joplin-mcp-macos/
├── install.sh              # Main installer
├── uninstall.sh            # Uninstaller
├── joplin-mcp-doctor.sh    # Diagnostic script
├── run_mcp.sh              # Wrapper template
├── server.py               # MCP server
├── requirements.txt        # Python dependencies
├── mcp_config.json         # Example for Claude Desktop
├── CHANGELOG.md            # Change history
└── README.md               # This file
```

### Testing

```bash
# Manual server test
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' | ~/.joplin-mcp/run_mcp.sh

# Full diagnostic
~/.joplin-mcp/joplin-mcp-doctor.sh
```

## Changelog

### v2.1.1 (2026-04-21)
- Added MCP tools to create notebooks, create notes, and update existing note content
- Refactored the server request helper to support POST/PUT with JSON payloads

### v2.1 (2026-04-21)
- Updated the project version to 2.1 across scripts, server metadata, and documentation
- Refreshed repository references in the documentation for `joplin-mcp-macos`

### v1.3 (2025-04-21)
- Complete translation to British English
- Added project attribution (JoplinApp, OpenCode, MCP Protocol)
- Updated all version references to 1.3
- Security verification: no personal information leaks

### v1.2 (2025-04-21)
- Fixed installation menu logic
- Fixed backup self-copy error
- Updated all version references to 1.2

### v1.1 (2025-04-21)
- **New**: Automatic installer (`install.sh`)
- **New**: Uninstaller (`uninstall.sh`)
- **New**: Diagnostic script (`joplin-mcp-doctor.sh`)
- **New**: Automatic token detection from Joplin settings
- **New**: Token validation during installation
- **New**: Post-installation tests
- **New**: Automatic configuration backup
- **New**: Logging system
- **Improvement**: Idempotency on reinstallations
- **Improvement**: Error handling and recovery

### v1.0 (2025-04-21)
- Initial stable release
- search_notes, read_note, list_notebooks tools
- Wrapper script support for OpenCode
- Environment variable configuration
- MCP protocol implementation

## Security Notes

- **Never commit your Joplin token to git**
- The installer saves the token in `~/.joplin-mcp/run_mcp.sh` (accessible only by your user)
- The repository only contains placeholders (`TOKEN_JOPLIN`)
- Backups are saved in `~/.joplin-mcp/backup/` (check permissions)

## License

**GPL v3 License** - See [LICENSE](LICENSE) file for details

This project is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## Project Attribution

This project is built on the following technologies:

- **[JoplinApp](https://joplinapp.org/)** - The open source note-taking application
- **[OpenCode](https://github.com/anomalyco/opencode)** - AI-powered code development framework
- **[MCP Protocol](https://modelcontextprotocol.io/)** - Model Context Protocol version 2024-11-05

## Acknowledgments

This project was developed with the assistance of:

- **[DeepSeek](https://www.deepseek.com/)** - AI model used for code development, architecture design, and documentation
- **[Kimi](https://kimi.moonshot.cn/)** - AI model used for code review, optimisation, and testing

Special thanks to the open-source AI community for making tools like these accessible to developers.

## Contributing

Contributions are welcome! Please ensure:
1. No tokens or sensitive data in commits
2. Follow existing code style
3. Update README.md if adding features
4. Test with `./joplin-mcp-doctor.sh`

## Support

For issues or questions:
1. Run `~/.joplin-mcp/joplin-mcp-doctor.sh` for diagnostics
2. Check logs: `~/.joplin-mcp/logs/install.log`
3. Open an issue on GitHub
