# INSTALL.md - Joplin MCP Installation Guide

This guide covers all aspects of installing, configuring, and uninstalling the Joplin MCP Server.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Automatic Installation (Recommended)](#automatic-installation-recommended)
- [Manual Installation](#manual-installation)
- [Configuration](#configuration)
  - [OpenCode](#opencode)
  - [Claude Desktop](#claude-desktop)
- [Installation Management](#installation-management)
- [Uninstallation](#uninstallation)
- [Troubleshooting](#troubleshooting)
- [Backup Recovery](#backup-recovery)

---

## Prerequisites

Before installing, ensure you have:

- **Python 3.9 or higher**
  ```bash
  python3 --version  # Must show 3.9.x or higher
  ```

- **Joplin Desktop** running with Web Clipper enabled:
  1. Open Joplin
  2. Go to **Options > Web Clipper**
  3. Enable **"Enable Web Clipper"**
  4. Optionally, copy the token (the installer can detect it automatically)

- **System dependencies** (normally already installed):
  - `curl` - for validating the connection with Joplin
  - `git` - for cloning the repository

---

## Automatic Installation (Recommended)

The easiest and quickest way to install is using the automatic installer:

```bash
# 1. Clone the repository
git clone <repository-url> joplin-mcp-macos
cd joplin-mcp-macos

# 2. Run the installer
./install.sh
```

### What does the installer do?

The `install.sh` installer automates the entire process:

1. **System verification**
   - Detects your operating system (Linux, macOS, Windows WSL)
   - Verifies you have Python 3.9+ installed
   - Checks dependencies (pip, curl)

2. **Joplin token detection**
   - Automatically searches for your token in `~/.config/joplin-desktop/settings.json`
   - If not found, prompts you for it interactively
   - Validates that the token works before continuing

3. **Environment installation**
   - Creates the `~/.joplin-mcp/` directory
   - Creates a Python virtual environment
   - Installs all dependencies from `requirements.txt`
   - Generates the `run_mcp.sh` script with your token

4. **OpenCode configuration**
   - Performs **automatic backup** of `~/.config/opencode/opencode.json` or `~/.config/opencode/opencode.jsonc`
   - Adds the Joplin MCP configuration
   - Preserves your existing configuration

5. **Validation**
   - Tests that the MCP server responds
   - Verifies that the tools are available
   - Shows installation summary

---

## Manual Installation

If you prefer to install manually or need more control over the process:

### Step 1: Prepare the environment

```bash
# Create installation directory
mkdir -p ~/.joplin-mcp
cd ~/.joplin-mcp

# Copy necessary files from the cloned repository
cp /path/to/repo/joplin-mcp-macos/server.py .
cp /path/to/repo/joplin-mcp-macos/requirements.txt .
```

### Step 2: Create Python virtual environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Verify installation
pip list | grep -E "mcp|httpx"
```

### Step 3: Configure the Joplin token

You need to obtain your Joplin Web Clipper token:

1. Open **Joplin Desktop**
2. Go to **Options > Web Clipper**
3. Enable **"Enable Web Clipper"**
4. Copy the value of **"API Token"**

### Step 4: Create the wrapper script

Create the `run_mcp.sh` file with your token:

```bash
cat > ~/.joplin-mcp/run_mcp.sh << 'EOF'
#!/bin/bash
export JOPLIN_TOKEN="PASTE_YOUR_TOKEN_HERE"
export JOPLIN_PORT="41184"
exec ~/.joplin-mcp/venv/bin/python ~/.joplin-mcp/server.py
EOF

# Make executable
chmod +x ~/.joplin-mcp/run_mcp.sh
```

⚠️ **Important**: Replace `PASTE_YOUR_TOKEN_HERE` with your actual Joplin token.

### Step 5: Configure OpenCode manually

Edit the file `~/.config/opencode/opencode.json` or `~/.config/opencode/opencode.jsonc`:

```bash
# Create the directory if it doesn't exist
mkdir -p ~/.config/opencode

# Add configuration (if the file already exists, add only the mcp.joplin_mcp section)
cat >> ~/.config/opencode/opencode.json << 'EOF'
{
  "mcp": {
    "joplin_mcp": {
      "type": "local",
      "command": ["/home/YOUR_USER/.joplin-mcp/run_mcp.sh"],
      "enabled": true
    }
  }
}
EOF
```

**Note**: Replace `/home/YOUR_USER/` with your actual path (use `echo $HOME` to verify).

### Step 6: Verify the installation

```bash
# Test the MCP server
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' | ~/.joplin-mcp/run_mcp.sh

# If you see a JSON response, everything is working!
```

---

## Configuration

### OpenCode

The installer automatically configures your existing `~/.config/opencode/opencode.jsonc` when present, otherwise `~/.config/opencode/opencode.json`:

```json
{
  "mcp": {
    "joplin_mcp": {
      "type": "local",
      "command": ["/home/YOUR_USER/.joplin-mcp/run_mcp.sh"],
      "enabled": true
    }
  }
}
```

The installer preserves existing OpenCode settings and can merge into files that use JSONC features such as comments or trailing commas.

If you need to configure it manually:

```bash
# Add to ~/.config/opencode/opencode.json or ~/.config/opencode/opencode.jsonc
{
  "mcp": {
    "joplin_mcp": {
      "type": "local",
      "command": ["~/.joplin-mcp/run_mcp.sh"],
      "enabled": true
    }
  }
}
```

### Claude Desktop

Add to your configuration (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "joplin_mcp": {
      "command": "uv",
      "args": [
        "run",
        "--with",
        "mcp[cli]",
        "--with",
        "httpx",
        "/home/YOUR_USER/.joplin-mcp/server.py"
      ],
      "env": {
        "JOPLIN_TOKEN": "YOUR_TOKEN_HERE",
        "JOPLIN_PORT": "41184"
      }
    }
  }
}
```

---

## Installation Management

### Useful Commands

```bash
# Diagnosis and verification
~/.joplin-mcp/joplin-mcp-doctor.sh

# Uninstall completely
~/.joplin-mcp/uninstall.sh

# Reinstall or update
cd /path/to/repo/joplin-mcp-macos
./install.sh
```

### Installation Structure

```
~/.joplin-mcp/
├── server.py              # MCP Server
├── requirements.txt       # Dependencies
├── run_mcp.sh            # Wrapper script (with your token)
├── venv/                 # Python virtual environment
├── logs/                 # Installation and operation logs
│   └── install.log
├── backup/               # Automatic backups
│   └── 20250121_143022/
│       ├── opencode.json.backup / opencode.jsonc.backup
│       └── joplin-settings.json.backup
├── joplin-mcp-doctor.sh  # Diagnostic script
├── uninstall.sh          # Uninstaller
└── VERSION               # Installed version
```

---

## Uninstallation

To completely uninstall Joplin MCP:

### Method 1: Use the uninstaller (Recommended)

```bash
# Run the uninstaller
~/.joplin-mcp/uninstall.sh
```

This script:
1. Creates a backup of your current installation
2. Removes the MCP entry from `~/.config/opencode/opencode.json` or `~/.config/opencode/opencode.jsonc`
3. Removes the `~/.joplin-mcp/` directory
4. Shows the backup location

### Method 2: Manual uninstallation

```bash
# 1. Remove OpenCode configuration
# Edit ~/.config/opencode/opencode.json or ~/.config/opencode/opencode.jsonc and remove the mcp.joplin_mcp section

# 2. Remove installation directory
rm -rf ~/.joplin-mcp

# 3. Verify no active processes remain
pkill -f "joplin-mcp" 2>/dev/null || true
```

### Complete cleanup (including backups)

```bash
# Remove installation and all backups
rm -rf ~/.joplin-mcp
rm -rf ~/.joplin-mcp-backup-*
```

---

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

# Check logs
cat ~/.joplin-mcp/logs/install.log

# Reinstall if necessary
./install.sh
```

### Error: Permission denied

```bash
# Ensure that scripts are executable
chmod +x ~/.joplin-mcp/run_mcp.sh
chmod +x ~/.joplin-mcp/joplin-mcp-doctor.sh
chmod +x ~/.joplin-mcp/uninstall.sh
```

---

## Backup Recovery

If something goes wrong, you can restore the backup:

### View available backups

```bash
# List all backups
ls -la ~/.joplin-mcp/backup/

# View the most recent backup
cat ~/.joplin-mcp/LATEST_BACKUP
```

### Restore OpenCode configuration

```bash
# Restore from a specific backup
cp ~/.joplin-mcp/backup/20250121_143022/opencode.json.backup ~/.config/opencode/opencode.json

# Or restore a JSONC config
cp ~/.joplin-mcp/backup/20250121_143022/opencode.jsonc.backup ~/.config/opencode/opencode.jsonc

# Or restore from the automatic uninstaller backup
cp ~/.joplin-mcp-backup-*/opencode.json.backup ~/.config/opencode/opencode.json 2>/dev/null || echo "No JSON backup"
cp ~/.joplin-mcp-backup-*/opencode.jsonc.backup ~/.config/opencode/opencode.jsonc 2>/dev/null || echo "No JSONC backup"
```

### Restore complete installation

```bash
# If you uninstalled but have backup
rm -rf ~/.joplin-mcp  # If a partial installation exists
cp -r ~/.joplin-mcp-backup-20250121_143022 ~/.joplin-mcp

# Reconfigure permissions
chmod +x ~/.joplin-mcp/run_mcp.sh
chmod +x ~/.joplin-mcp/*.sh
```

---

## Security Notes

- **Never share your Joplin token**: The token allows full access to your notes
- **File permissions**: The token is stored in `~/.joplin-mcp/run_mcp.sh` with user permissions (0o600)
- **Backups**: Backups contain your token, protect them appropriately
- **Repository**: Never commit files with real tokens

---

## Support

If you encounter problems during installation:

1. Run the diagnostic: `~/.joplin-mcp/joplin-mcp-doctor.sh`
2. Check the logs: `~/.joplin-mcp/logs/install.log`
3. Open an issue on GitHub with the diagnostic output
