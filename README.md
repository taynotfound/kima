# KIMA - Unified Linux Package Manager

KIMA is a beautiful, interactive, and unified package manager script for Linux. It provides a single interface to manage packages across multiple package managers (dnf, snap, apt, rpm, yay, pacman, flatpak) with a modern, user-friendly CLI and TUI.

## Features
- Detects and works with all major Linux package managers
- Search for packages across all managers
- Install, uninstall, and upgrade packages everywhere
- List installed, outdated, and orphaned packages
- Show package details, dependencies, reverse dependencies, and files
- Copy install command to clipboard
- Show package homepage/URL
- System stats and cleanup
- Interactive TUI mode
- **NEW:** Compare a package's availability and version across all managers

## Commands
- `install <package>`: Install a package (tries all managers)
- `upgrade <package>`: Upgrade a package everywhere
- `uninstall <package>`: Uninstall a package (tries all managers)
- `search <package>`: Search for a package across all managers
- `descsearch <term>`: Search by description
- `list`: List installed packages from all managers
- `files <package>`: Show files installed by a package
- `info <package>`: Show package information
- `details <package>`: Show package details from all managers
- `deps <package>`: Show dependencies
- `rdeps <package>`: Show reverse dependencies
- `update`: Update all packages
- `cleanup`: Clean up unused packages and cache
- `outdated`: List outdated packages
- `orphaned`: Find orphaned packages
- `check <package>`: Check if package is installed
- `stats`: Show system package statistics
- `copycmd <package>`: Copy install command to clipboard
- `home <package>`: Show package homepage/URL
- `ui`: Start interactive TUI mode
- `help`: Show help menu
- `compare <package>`: **Compare package availability and version across all managers**

## Installation
1. Download `kima.sh` to a directory of your choice.
2. Make it executable:
   ```bash
   chmod +x kima.sh
   ```
3. (Optional) Move it to a directory in your PATH to use it system-wide:
   ```bash
   sudo mv kima.sh /usr/local/bin/kima
   ```
   Now you can run it anywhere with:
   ```bash
   kima [command]
   ```

## Requirements
- Bash
- At least one supported package manager (apt, dnf, pacman, yay, rpm, snap, flatpak)
- `column` utility (usually in `util-linux`)
- Optional: `xclip` or `pbcopy` for clipboard features

## Usage Examples
- Search for a package:
  ```bash
  kima search neofetch
  ```
- Compare a package across all managers:
  ```bash
  kima compare neofetch
  ```
- Start the interactive TUI:
  ```bash
  kima ui
  ```

## License
[Your License Here] 