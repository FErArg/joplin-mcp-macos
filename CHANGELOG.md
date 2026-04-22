# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.1] - 2026-04-21

### Added
- MCP tools `create_notebook`, `create_note`, and `update_note` to manage notebooks and notes directly from clients

### Changed
- Refactored `server.py` request helper to support POST/PUT operations with JSON payloads
- Updated documentation and scripts to reflect version 2.1.1

## [2.1] - 2026-04-21

### Changed
- Updated the project version from 1.3 to 2.1 across `install.sh`, `server.py`, `joplin-mcp-doctor.sh`, and `README.md`
- Refreshed repository references in `README.md` and `INSTALL.md` to use `joplin-mcp-macos`

## [1.3] - 2025-04-21

### Changed
- **Complete Translation to British English**:
  - Translated all user-facing text in `install.sh`, `joplin-mcp-doctor.sh`, `uninstall.sh`
  - Translated tool descriptions in `server.py` to British English
  - Translated complete `README.md` and `INSTALL.md` documentation
  - Applied British spelling throughout: "colour", "centre", "analyse", "organisation"

### Added
- **Project Attribution**:
  - Added links to [JoplinApp](https://joplinapp.org/) in README.md
  - Added links to [OpenCode](https://github.com/anomalyco/opencode) in README.md
  - Documented MCP Protocol version (2024-11-05)
  - Added "Acknowledgements" section with project references

### Security
- **Privacy Verification**:
  - Verified no personal information leaks in codebase
  - Confirmed no hardcoded tokens, passwords, or private paths
  - All sensitive data uses placeholders (`TOKEN_JOPLIN`)

## [1.2] - 2025-04-21

### Fixed
- **Installation Menu Logic** (`install.sh`):
  - Fixed menu to show "Instalar" option for fresh installations
  - Now correctly differentiates between fresh install and existing installation
  - Shows appropriate options based on installation state

- **Backup Self-Copy Error** (`install.sh`):
  - Fixed backup function trying to copy directory into itself
  - Added exclusion of `backup/` directory during backup process
  - Added fallback to `find` command when `rsync` is not available

- **Version Consistency**:
  - Updated all version references from v1.1 to v1.2
  - Synchronized versions across: install.sh, server.py, joplin-mcp-doctor.sh, README.md

- **Personal Information Removal**:
  - Removed hardcoded personal path from `test_mcp.sh`
  - Now uses `$(dirname "$0")` for portability

## [1.1] - 2025-04-21

### Added
- **Automated Installer** (`install.sh`) - Complete installation automation with:
  - OS detection (Linux, macOS, Windows WSL)
  - Dependency checking (Python 3.9+, pip, curl)
  - Automatic token detection from Joplin settings
  - Interactive token prompt with validation
  - Automatic backup of configurations
  - Post-installation testing
  - Idempotent reinstallation support
  
- **Uninstaller** (`uninstall.sh`) - Clean removal with:
  - Backup before removal
  - Automatic cleanup of OpenCode configuration
  - Preservation of user data
  
- **Diagnostic Tool** (`joplin-mcp-doctor.sh`) - Comprehensive health checks:
  - Installation verification
  - Token validation
  - Joplin connectivity testing
  - MCP server response testing
  - Configuration validation
  
- **Logging System** - Installation and operation logs:
  - `~/.joplin-mcp/logs/install.log`
  - Timestamped entries
  - Error tracking
  
- **Backup System** - Automatic backups:
  - Pre-installation backup of `opencode.json`
  - Backup of Joplin settings
  - Timestamped backup directories
  - Easy restoration process
  
- **Version Tracking** - `~/.joplin-mcp/VERSION` file

### Changed
- Improved `run_mcp.sh` as a template for installer generation
- Enhanced error handling throughout
- Better user feedback with coloured output
- More robust JSON manipulation using Python

### Security
- Token stored only in user's home directory (`~/.joplin-mcp/`)
- Repository contains only placeholders
- Automatic backup prevents configuration loss
- Input validation for tokens

## [1.0] - 2025-04-21

### Added
- Initial stable release
- Three MCP tools:
  - `search_notes` - Search notes by keyword
  - `read_note` - Read full note content
  - `list_notebooks` - List all notebooks
  
- Wrapper script support for OpenCode integration
- Environment variable configuration via `JOPLIN_TOKEN`
- MCP protocol implementation with stdio transport
- Support for Joplin Web Clipper API
- Configuration examples for:
  - OpenCode
  - Claude Desktop
  
- Basic documentation and README
- `.gitignore` for Python projects

### Security
- Token placeholder in repository (`TOKEN_JOPLIN`)
- User configures token locally in wrapper script
- No sensitive data in git history
