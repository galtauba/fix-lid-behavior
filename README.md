# fix-lid-behavior

A simple Bash script to prevent your Ubuntu laptop from suspending when the lid is closed.

## 🔧 Features

- Disables suspend-on-lid-close behavior (even when docked or on battery)
- Verifies and updates `/etc/systemd/logind.conf`
- Creates a backup of the original config
- Displays clear progress steps with color
- Logs all actions to a timestamped log file in the same directory
- Includes safe pre-checks:
  - System is running `systemd`
  - User has `sudo` privileges
  - Configuration file exists
  - Script directory is writable

## 🚀 Usage

1. Download or clone this repository:

```bash
git clone https://github.com/yourusername/fix-lid-behavior.git
cd fix-lid-behavior
```

2. Make the script executable:

```bash
chmod +x fix-lid-behavior.sh
```

3. Run the script:

```bash
./fix-lid-behavior.sh
```

4. A log file will be created in the same directory, named like:

```
fix-lid-behavior-2025-04-18_20-35-12.log
```

## 📁 What it does

The script sets the following values inside `/etc/systemd/logind.conf`:

```ini
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=ignore
```

It then restarts the `systemd-logind` service to apply changes.

## ⚠️ Requirements

- Ubuntu or any Linux system using `systemd`
- `sudo` access
- `/etc/systemd/logind.conf` must exist

## 📄 License

MIT License. Use freely and modify as needed.

## 🙋‍♂️ Contributions

Pull requests, issues, and improvements are welcome!
