# Selfspy Advanced User Guide

This guide covers advanced usage, configuration, and features of Selfspy for power users who want to get the most out of their activity monitoring.

## Table of Contents

- [Advanced Configuration](#advanced-configuration)
- [Environment Variables](#environment-variables)
- [Database Management](#database-management)
- [Security & Privacy](#security--privacy)
- [Advanced Statistics](#advanced-statistics)
- [Automation & Scripting](#automation--scripting)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)
- [Data Export & Analysis](#data-export--analysis)
- [Integration Examples](#integration-examples)

## Advanced Configuration

### Configuration File Location

Selfspy uses Pydantic settings that can be configured via:
- Environment variables (prefixed with `SELFSPY_`)
- `.env` file in your data directory
- Command-line arguments

### Key Configuration Options

```bash
# Data storage location
SELFSPY_DATA_DIR=~/.selfspy

# Database settings
SELFSPY_DATABASE_NAME=selfspy.db
SELFSPY_MAX_DATABASE_SIZE=1073741824  # 1GB

# Activity monitoring
SELFSPY_ACTIVE_WINDOW_CHECK_INTERVAL=0.1
SELFSPY_KEYSTROKE_BUFFER_TIMEOUT=1
SELFSPY_ACTIVE_THRESHOLD=180

# Privacy settings
SELFSPY_PRIVACY_MODE=false
SELFSPY_PRIVACY_EXCLUDED_APPS=1Password,Keychain Access

# Performance settings
SELFSPY_MONITOR_SUPPRESS_ERRORS=false
SELFSPY_DEBUG_LOGGING_ENABLED=false
```

### Advanced Privacy Configuration

Create a `.env` file in your data directory:

```env
# Exclude sensitive applications
SELFSPY_EXCLUDED_BUNDLES=com.apple.SecurityAgent,com.apple.systempreferences,com.1password.1password

# Screenshot settings (if enabled)
SELFSPY_ENABLE_SCREENSHOTS=false
SELFSPY_SCREENSHOT_INTERVAL=300
SELFSPY_MAX_DAILY_SCREENSHOTS=100
SELFSPY_SCREENSHOT_EXCLUDED_APPS=System Settings,1Password,Terminal

# Privacy mode - restricts logging for sensitive apps
SELFSPY_PRIVACY_MODE=true
```

## Environment Variables

### Complete Environment Variable Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `SELFSPY_DATA_DIR` | `~/.selfspy` | Where data is stored |
| `SELFSPY_DEBUG` | `false` | Enable debug logging |
| `SELFSPY_ENCRYPTION_ENABLED` | `true` | Encrypt keystroke data |
| `SELFSPY_ACTIVE_WINDOW_CHECK_INTERVAL` | `0.1` | Window check frequency (seconds) |
| `SELFSPY_KEYSTROKE_BUFFER_TIMEOUT` | `1` | Buffer flush timeout (seconds) |
| `SELFSPY_ACTIVE_THRESHOLD` | `180` | Inactive threshold (seconds) |
| `SELFSPY_MAX_DATABASE_SIZE` | `1073741824` | Max DB size before cleanup |
| `SELFSPY_AUTO_CLEANUP_THRESHOLD` | `0.9` | Cleanup trigger percentage |
| `SELFSPY_BACKUP_ENABLED` | `true` | Enable automatic backups |
| `SELFSPY_BACKUP_INTERVAL_DAYS` | `7` | Backup frequency |
| `SELFSPY_MAX_BACKUPS` | `5` | Maximum backup files to keep |

### Setting Environment Variables

**Temporary (current session):**
```bash
export SELFSPY_DEBUG=true
export SELFSPY_DATA_DIR=/custom/path
uv run selfspy start
```

**Permanent (add to ~/.zshrc or ~/.bashrc):**
```bash
echo 'export SELFSPY_DATA_DIR=/custom/selfspy/data' >> ~/.zshrc
echo 'export SELFSPY_PRIVACY_MODE=true' >> ~/.zshrc
```

## Database Management

### Database Location and Structure

The SQLite database is stored at `$SELFSPY_DATA_DIR/selfspy.db` and contains:

- **process** - Application information with bundle IDs
- **window** - Window metadata with geometry and screen info
- **keys** - Encrypted keystroke data with counts
- **click** - Mouse events with coordinates and movement

### Direct Database Access

```bash
# Access the database directly
sqlite3 ~/.selfspy/selfspy.db

# Useful queries
.tables
.schema process
SELECT COUNT(*) FROM keys;
SELECT process.name, COUNT(*) as window_count FROM window 
  JOIN process ON window.process_id = process.id 
  GROUP BY process.name ORDER BY window_count DESC;
```

### Database Maintenance

```bash
# Check database size
du -h ~/.selfspy/selfspy.db

# Manual cleanup (stops monitoring first)
uv run python -c "
from src.config import Settings
from src.activity_store import ActivityStore
import asyncio

settings = Settings()
store = ActivityStore(settings)
# Add cleanup logic here
"
```

### Database Backup and Restore

```bash
# Manual backup
cp ~/.selfspy/selfspy.db ~/.selfspy/backup-$(date +%Y%m%d).db

# Restore from backup
cp ~/.selfspy/backup-20241201.db ~/.selfspy/selfspy.db

# Automated backup script
#!/bin/bash
BACKUP_DIR=~/.selfspy/backups
mkdir -p $BACKUP_DIR
cp ~/.selfspy/selfspy.db $BACKUP_DIR/selfspy-$(date +%Y%m%d-%H%M%S).db
find $BACKUP_DIR -name "selfspy-*.db" -mtime +30 -delete
```

## Security & Privacy

### Encryption Details

Selfspy uses industry-standard encryption for keystroke data:
- **Algorithm**: Fernet (AES 128 in CBC mode with PKCS7 padding)
- **Key Derivation**: PBKDF2 with SHA256, 100,000 iterations
- **Salt**: Fixed application salt (consider rotating for maximum security)

### Password Management

```bash
# Use keyring for password storage
uv run selfspy start  # Will prompt to save to keyring

# Set password via environment (less secure)
export SELFSPY_PASSWORD=mypassword
uv run selfspy start --password "$SELFSPY_PASSWORD"

# Disable encryption entirely (not recommended)
uv run selfspy start --no-text
```

### Application Exclusions

Configure applications to exclude from monitoring:

```python
# In your .env file or environment
SELFSPY_EXCLUDED_BUNDLES=com.apple.SecurityAgent,com.apple.systempreferences,com.1password.1password,com.apple.keychainaccess

# Privacy mode excludes additional sensitive apps
SELFSPY_PRIVACY_MODE=true
SELFSPY_PRIVACY_EXCLUDED_APPS=1Password,Keychain Access,System Settings,Terminal
```

### Data Minimization

```bash
# Monitor only mouse/window activity (no keystrokes)
uv run selfspy start --no-text

# Reduce data collection frequency
export SELFSPY_ACTIVE_WINDOW_CHECK_INTERVAL=1.0  # Check windows every second instead of 0.1s
export SELFSPY_KEYSTROKE_BUFFER_TIMEOUT=5        # Buffer keystrokes for 5 seconds
```

## Advanced Statistics

### Command-Line Statistics

```bash
# Basic stats for last 7 days
uv run selfspy stats summary

# Custom time ranges
uv run selfspy stats summary --days 30
uv run selfspy stats summary --days 1

# With custom data directory
uv run selfspy stats summary --data-dir /custom/path --days 14
```

### Programmatic Data Access

```python
#!/usr/bin/env python3
"""
Advanced statistics script
"""
import asyncio
from datetime import datetime, timedelta
from src.config import Settings
from src.activity_store import ActivityStore
from sqlalchemy import select, func
from src.models import Process, Window, Keys, Click

async def generate_custom_stats():
    settings = Settings()
    store = ActivityStore(settings, password="your_password")
    
    async with store.async_session() as session:
        # Most active applications
        query = select(
            Process.name,
            func.count(Window.id).label('window_count'),
            func.sum(Keys.count).label('keystrokes')
        ).select_from(Process).join(Window).join(Keys).group_by(Process.name)
        
        result = await session.execute(query)
        for row in result:
            print(f"{row.name}: {row.window_count} windows, {row.keystrokes} keystrokes")

if __name__ == "__main__":
    asyncio.run(generate_custom_stats())
```

### Time-based Analysis

```python
#!/usr/bin/env python3
"""
Hourly activity analysis
"""
import asyncio
from datetime import datetime, timedelta
from src.config import Settings
from src.activity_store import ActivityStore
from sqlalchemy import select, func, extract
from src.models import Keys, Click

async def hourly_activity():
    settings = Settings()
    store = ActivityStore(settings, password="your_password")
    
    async with store.async_session() as session:
        # Activity by hour of day
        query = select(
            extract('hour', Keys.created_at).label('hour'),
            func.sum(Keys.count).label('keystrokes'),
            func.count(Click.id).label('clicks')
        ).select_from(Keys).outerjoin(Click).group_by('hour').order_by('hour')
        
        result = await session.execute(query)
        print("Hour | Keystrokes | Clicks")
        print("-" * 25)
        for row in result:
            print(f"{row.hour:2d}   | {row.keystrokes:8d} | {row.clicks:6d}")

if __name__ == "__main__":
    asyncio.run(hourly_activity())
```

## Automation & Scripting

### Systemd Service (Linux)

Create `/etc/systemd/user/selfspy.service`:

```ini
[Unit]
Description=Selfspy Activity Monitor
After=graphical-session.target

[Service]
Type=simple
ExecStart=/path/to/uv run selfspy start
Restart=always
RestartSec=10
Environment=SELFSPY_DATA_DIR=/home/%i/.selfspy
Environment=SELFSPY_DEBUG=false

[Install]
WantedBy=default.target
```

Enable and start:
```bash
systemctl --user enable selfspy.service
systemctl --user start selfspy.service
```

### macOS LaunchAgent

Create `~/Library/LaunchAgents/com.selfspy.monitor.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.selfspy.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/uv</string>
        <string>run</string>
        <string>selfspy</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/path/to/selfspy3</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>SELFSPY_DATA_DIR</key>
        <string>/Users/username/.selfspy</string>
    </dict>
</dict>
</plist>
```

Load the service:
```bash
launchctl load ~/Library/LaunchAgents/com.selfspy.monitor.plist
```

### Cron Jobs for Maintenance

```bash
# Add to crontab (crontab -e)

# Daily backup at 2 AM
0 2 * * * cp ~/.selfspy/selfspy.db ~/.selfspy/backup-$(date +\%Y\%m\%d).db

# Weekly cleanup of old backups (keep 30 days)
0 3 * * 0 find ~/.selfspy -name "backup-*.db" -mtime +30 -delete

# Monthly statistics report
0 9 1 * * /path/to/uv run selfspy stats summary --days 30 > ~/monthly-stats.txt
```

## Performance Optimization

### Reducing Resource Usage

```bash
# Lower monitoring frequency
export SELFSPY_ACTIVE_WINDOW_CHECK_INTERVAL=0.5  # Default: 0.1

# Increase buffer timeout to reduce I/O
export SELFSPY_KEYSTROKE_BUFFER_TIMEOUT=5        # Default: 1

# Suppress non-critical errors
export SELFSPY_MONITOR_SUPPRESS_ERRORS=true
```

### Database Optimization

```sql
-- Run these queries periodically to optimize the database
PRAGMA optimize;
PRAGMA vacuum;
PRAGMA integrity_check;

-- Add custom indexes for common queries
CREATE INDEX IF NOT EXISTS idx_keys_created_process ON keys(created_at, process_id);
CREATE INDEX IF NOT EXISTS idx_window_created_process ON window(created_at, process_id);
```

### Memory Management

```python
# Custom cleanup script
#!/usr/bin/env python3
import asyncio
from datetime import datetime, timedelta
from src.config import Settings
from src.activity_store import ActivityStore

async def cleanup_old_data(days_to_keep=90):
    settings = Settings()
    store = ActivityStore(settings)
    
    cutoff_date = datetime.now() - timedelta(days=days_to_keep)
    
    async with store.async_session() as session:
        # Delete old keystroke data
        await session.execute(
            "DELETE FROM keys WHERE created_at < ?", (cutoff_date,)
        )
        # Delete old click data
        await session.execute(
            "DELETE FROM click WHERE created_at < ?", (cutoff_date,)
        )
        await session.commit()
    
    print(f"Cleaned up data older than {days_to_keep} days")

if __name__ == "__main__":
    asyncio.run(cleanup_old_data(90))
```

## Troubleshooting

### Common Issues and Solutions

**1. Permission Denied Errors**
```bash
# Check current permissions
uv run selfspy check-permissions

# Reset permissions (macOS)
tccutil reset Accessibility com.apple.Terminal
# Then re-grant permissions in System Settings
```

**2. Database Locked Errors**
```bash
# Check for running processes
ps aux | grep selfspy

# Kill any hanging processes
pkill -f selfspy

# Check database integrity
sqlite3 ~/.selfspy/selfspy.db "PRAGMA integrity_check;"
```

**3. High Resource Usage**
```bash
# Monitor resource usage
top -p $(pgrep -f selfspy)

# Reduce monitoring frequency
export SELFSPY_ACTIVE_WINDOW_CHECK_INTERVAL=1.0
export SELFSPY_KEYSTROKE_BUFFER_TIMEOUT=10
```

**4. Import Errors**
```bash
# Reinstall dependencies
uv sync --group dev --extra macos

# Check Python version
python --version  # Should be 3.10+

# Verify installation
uv run python -c "import src.cli; print('OK')"
```

### Debug Mode

```bash
# Enable debug logging
uv run selfspy start --debug

# Or via environment
export SELFSPY_DEBUG=true
uv run selfspy start
```

### Log Analysis

```bash
# View systemd logs (Linux)
journalctl --user -u selfspy -f

# macOS Console.app or:
log stream --predicate 'process == "Python"' --level debug
```

## Data Export & Analysis

### CSV Export Script

```python
#!/usr/bin/env python3
"""
Export Selfspy data to CSV
"""
import asyncio
import csv
from datetime import datetime, timedelta
from src.config import Settings
from src.activity_store import ActivityStore
from src.models import Process, Window, Keys, Click

async def export_to_csv(output_file, days=30):
    settings = Settings()
    store = ActivityStore(settings, password="your_password")
    
    cutoff_date = datetime.now() - timedelta(days=days)
    
    with open(output_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['timestamp', 'type', 'application', 'window_title', 'data'])
        
        async with store.async_session() as session:
            # Export window changes
            windows = await session.execute(
                select(Window, Process.name).join(Process)
                .where(Window.created_at >= cutoff_date)
                .order_by(Window.created_at)
            )
            
            for window, app_name in windows:
                writer.writerow([
                    window.created_at.isoformat(),
                    'window_change',
                    app_name,
                    window.title,
                    ''
                ])
            
            # Export keystroke counts (not actual keystrokes for privacy)
            keys = await session.execute(
                select(Keys, Process.name).join(Process)
                .where(Keys.created_at >= cutoff_date)
                .order_by(Keys.created_at)
            )
            
            for key, app_name in keys:
                writer.writerow([
                    key.created_at.isoformat(),
                    'keystrokes',
                    app_name,
                    '',
                    str(key.count)
                ])

if __name__ == "__main__":
    asyncio.run(export_to_csv('selfspy_export.csv', days=30))
```

### JSON Export for Analysis Tools

```python
#!/usr/bin/env python3
"""
Export to JSON for analysis tools like Jupyter notebooks
"""
import asyncio
import json
from datetime import datetime, timedelta
from src.config import Settings
from src.activity_store import ActivityStore
from src.models import Process, Window, Keys, Click

async def export_to_json(output_file, days=7):
    settings = Settings()
    store = ActivityStore(settings, password="your_password")
    
    cutoff_date = datetime.now() - timedelta(days=days)
    data = {
        'export_date': datetime.now().isoformat(),
        'period_days': days,
        'applications': [],
        'activity_by_hour': [0] * 24,
        'total_stats': {}
    }
    
    async with store.async_session() as session:
        # Application statistics
        apps = await session.execute(
            select(
                Process.name,
                func.count(Window.id).label('windows'),
                func.sum(Keys.count).label('keystrokes')
            ).select_from(Process)
            .join(Window)
            .outerjoin(Keys)
            .where(Window.created_at >= cutoff_date)
            .group_by(Process.name)
        )
        
        for app in apps:
            data['applications'].append({
                'name': app.name,
                'windows': app.windows,
                'keystrokes': app.keystrokes or 0
            })
    
    with open(output_file, 'w') as f:
        json.dump(data, f, indent=2)

if __name__ == "__main__":
    asyncio.run(export_to_json('selfspy_data.json'))
```

## Integration Examples

### Slack Status Automation

```python
#!/usr/bin/env python3
"""
Update Slack status based on current application
"""
import asyncio
import requests
from src.config import Settings
from src.activity_store import ActivityStore

SLACK_TOKEN = "xoxp-your-token-here"
APP_STATUS_MAP = {
    'Code': {'text': 'Coding', 'emoji': ':computer:'},
    'Slack': {'text': 'In meetings', 'emoji': ':speech_balloon:'},
    'Chrome': {'text': 'Research', 'emoji': ':mag:'},
}

async def update_slack_status():
    settings = Settings()
    store = ActivityStore(settings)
    
    # Get current active window
    # Implementation depends on your current tracking setup
    current_app = "Code"  # Placeholder
    
    if current_app in APP_STATUS_MAP:
        status = APP_STATUS_MAP[current_app]
        
        response = requests.post(
            'https://slack.com/api/users.profile.set',
            headers={'Authorization': f'Bearer {SLACK_TOKEN}'},
            json={
                'profile': {
                    'status_text': status['text'],
                    'status_emoji': status['emoji']
                }
            }
        )
        
        if response.json().get('ok'):
            print(f"Updated Slack status to: {status['text']}")

if __name__ == "__main__":
    asyncio.run(update_slack_status())
```

### Time Tracking Integration

```python
#!/usr/bin/env python3
"""
Generate time tracking reports from Selfspy data
"""
import asyncio
from datetime import datetime, timedelta
from collections import defaultdict
from src.config import Settings
from src.activity_store import ActivityStore
from src.models import Process, Window

async def generate_time_report(days=1):
    settings = Settings()
    store = ActivityStore(settings, password="your_password")
    
    cutoff_date = datetime.now() - timedelta(days=days)
    app_time = defaultdict(int)
    
    async with store.async_session() as session:
        windows = await session.execute(
            select(Window, Process.name).join(Process)
            .where(Window.created_at >= cutoff_date)
            .order_by(Window.created_at)
        )
        
        prev_window = None
        prev_time = None
        
        for window, app_name in windows:
            if prev_window and prev_time:
                duration = (window.created_at - prev_time).total_seconds()
                if duration < 300:  # Only count sessions < 5 minutes as focused time
                    app_time[prev_window] += duration
            
            prev_window = app_name
            prev_time = window.created_at
    
    # Generate report
    print(f"Time Report - Last {days} day(s)")
    print("=" * 40)
    
    for app, seconds in sorted(app_time.items(), key=lambda x: x[1], reverse=True):
        hours = seconds / 3600
        print(f"{app:<20} {hours:6.1f}h")

if __name__ == "__main__":
    asyncio.run(generate_time_report(1))
```

### Health Break Reminders

```python
#!/usr/bin/env python3
"""
Send notifications for health breaks based on activity
"""
import asyncio
import subprocess
from datetime import datetime, timedelta
from src.config import Settings
from src.activity_store import ActivityStore
from src.models import Keys, Click

async def check_break_needed():
    settings = Settings()
    store = ActivityStore(settings)
    
    # Check activity in last hour
    one_hour_ago = datetime.now() - timedelta(hours=1)
    
    async with store.async_session() as session:
        activity_count = await session.execute(
            select(func.sum(Keys.count)).where(Keys.created_at >= one_hour_ago)
        )
        
        keystrokes = activity_count.scalar() or 0
        
        if keystrokes > 1000:  # High activity threshold
            # Send macOS notification
            subprocess.run([
                'osascript', '-e',
                'display notification "Consider taking a break!" with title "Health Reminder"'
            ])
            print("Break reminder sent!")

if __name__ == "__main__":
    asyncio.run(check_break_needed())
```

---

## Security Considerations

- **Never commit passwords** or API keys to version control
- **Use environment variables** for sensitive configuration
- **Regularly rotate encryption passwords** if maximum security is needed
- **Monitor file permissions** on your data directory (should be 700)
- **Consider full-disk encryption** for additional security
- **Backup encrypted** - your backups are only as secure as your original data

## Performance Monitoring

```bash
# Monitor Selfspy resource usage
watch -n 5 'ps -o pid,ppid,cmd,%mem,%cpu -p $(pgrep -f selfspy)'

# Database size monitoring
watch -n 60 'du -h ~/.selfspy/selfspy.db'

# Check for memory leaks
valgrind --tool=memcheck uv run selfspy start --no-text
```

This advanced guide should help power users get the most out of Selfspy while maintaining security and performance. Remember to always test configuration changes in a safe environment first!