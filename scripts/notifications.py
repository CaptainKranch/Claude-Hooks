"""
Claude Code Notification Hooks for Slack and Telegram

Sends notifications when:
- Claude Code is awaiting input
- Tasks complete
- Errors occur
- Long-running operations finish

Setup:
1. Set environment variables for your tokens/webhooks
2. Configure which notifications you want to receive
"""

import json
import sys
import os
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
# Use current working directory instead of script location when running from Nix
env_path = Path.cwd() / '.env'
if env_path.exists():
    load_dotenv(env_path)


class NotificationConfig:
    """Configuration for notifications"""
    
    def __init__(self):
        # Slack configuration
        self.slack_webhook_url = os.getenv('CLAUDE_SLACK_WEBHOOK_URL')
        self.slack_channel = os.getenv('CLAUDE_SLACK_CHANNEL', '#claude-notifications')
        self.slack_username = os.getenv('CLAUDE_SLACK_USERNAME', 'Claude Code')
        self.slack_emoji = os.getenv('CLAUDE_SLACK_EMOJI', ':robot_face:')
        
        # Telegram configuration
        self.telegram_bot_token = os.getenv('CLAUDE_TELEGRAM_BOT_TOKEN')
        self.telegram_chat_id = os.getenv('CLAUDE_TELEGRAM_CHAT_ID')
        
        # Notification preferences
        self.notify_on_waiting = os.getenv('CLAUDE_NOTIFY_WAITING', 'true').lower() == 'true'
        self.notify_on_completion = os.getenv('CLAUDE_NOTIFY_COMPLETION', 'true').lower() == 'true'
        self.notify_on_errors = os.getenv('CLAUDE_NOTIFY_ERRORS', 'true').lower() == 'true'
        
        # Minimum time between notifications (seconds)
        self.rate_limit = int(os.getenv('CLAUDE_NOTIFY_RATE_LIMIT', '60'))


class SlackNotifier:
    """Send notifications to Slack"""
    
    def __init__(self, config):
        self.config = config
    
    def send_message(self, message, color="good"):
        """Send a message to Slack"""
        if not self.config.slack_webhook_url:
            return False, "No Slack webhook URL configured"
        
        payload = {
            "channel": self.config.slack_channel,
            "username": self.config.slack_username,
            "icon_emoji": self.config.slack_emoji,
            "attachments": [
                {
                    "color": color,
                    "text": message,
                    "ts": int(datetime.now().timestamp())
                }
            ]
        }
        
        try:
            data = json.dumps(payload).encode('utf-8')
            req = urllib.request.Request(
                self.config.slack_webhook_url,
                data=data,
                headers={'Content-Type': 'application/json'}
            )
            
            with urllib.request.urlopen(req) as response:
                return response.status == 200, response.read().decode()
                
        except urllib.error.URLError as e:
            return False, str(e)
        except Exception as e:
            return False, str(e)


class TelegramNotifier:
    """Send notifications to Telegram"""
    
    def __init__(self, config):
        self.config = config
    
    def send_message(self, message):
        """Send a message to Telegram"""
        if not self.config.telegram_bot_token or not self.config.telegram_chat_id:
            return False, "Telegram bot token or chat ID not configured"
        
        url = f"https://api.telegram.org/bot{self.config.telegram_bot_token}/sendMessage"
        
        payload = {
            'chat_id': self.config.telegram_chat_id,
            'text': message,
            'parse_mode': 'Markdown'
        }
        
        try:
            data = urllib.parse.urlencode(payload).encode('utf-8')
            req = urllib.request.Request(url, data=data)
            
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode())
                return result.get('ok', False), result
                
        except urllib.error.URLError as e:
            return False, str(e)
        except Exception as e:
            return False, str(e)


class NotificationManager:
    """Manages sending notifications to multiple platforms"""
    
    def __init__(self):
        self.config = NotificationConfig()
        self.slack = SlackNotifier(self.config)
        self.telegram = TelegramNotifier(self.config)
        
        # Rate limiting
        self.last_notification_file = Path.home() / '.claude' / 'last_notification'
        self.last_notification_file.parent.mkdir(parents=True, exist_ok=True)
    
    def should_send_notification(self):
        """Check if we should send a notification based on rate limiting"""
        if not self.last_notification_file.exists():
            return True
        
        try:
            last_time = float(self.last_notification_file.read_text().strip())
            current_time = datetime.now().timestamp()
            
            return (current_time - last_time) >= self.config.rate_limit
        except (ValueError, FileNotFoundError):
            return True
    
    def update_last_notification_time(self):
        """Update the last notification timestamp"""
        self.last_notification_file.write_text(str(datetime.now().timestamp()))
    
    def send_notification(self, message, notification_type="info"):
        """Send notification to all configured platforms"""
        if not self.should_send_notification():
            return
        
        # Choose color for Slack based on notification type
        color_map = {
            "info": "good",
            "warning": "warning", 
            "error": "danger",
            "success": "good"
        }
        color = color_map.get(notification_type, "good")
        
        results = []
        
        # Send to Slack
        if self.config.slack_webhook_url:
            success, response = self.slack.send_message(message, color)
            results.append(f"Slack: {'✓' if success else '✗'} {response}")
        
        # Send to Telegram
        if self.config.telegram_bot_token and self.config.telegram_chat_id:
            success, response = self.telegram.send_message(message)
            results.append(f"Telegram: {'✓' if success else '✗'}")
        
        if results:
            self.update_last_notification_time()
        
        return results


def format_notification_message(input_data):
    """Format the notification message based on the hook event"""
    hook_event = input_data.get('hook_event_name', '')
    session_id = input_data.get('session_id', 'unknown')[:8]  # Short session ID
    
    if hook_event == 'Notification':
        message = input_data.get('message', 'Claude Code notification')
        return f"🤖 *Claude Code*\n`{message}`\nSession: `{session_id}`"
    
    elif hook_event == 'Stop':
        return f"✅ *Claude Code Task Complete*\nSession: `{session_id}`\nTask finished successfully"
    
    elif hook_event == 'SubagentStop':
        return f"🎯 *Claude Code Subtask Complete*\nSession: `{session_id}`\nSubtask finished"
    
    elif hook_event == 'PreToolUse':
        tool_name = input_data.get('tool_name', 'Unknown')
        return f"⚙️ *Claude Code Tool Execution*\nTool: `{tool_name}`\nSession: `{session_id}`"
    
    elif hook_event == 'PostToolUse':
        tool_name = input_data.get('tool_name', 'Unknown')
        return f"✅ *Claude Code Tool Complete*\nTool: `{tool_name}`\nSession: `{session_id}`"
    
    else:
        return f"🔔 *Claude Code Event*\nEvent: `{hook_event}`\nSession: `{session_id}`"


def get_project_context():
    """Get context about the current project"""
    cwd = os.getcwd()
    project_name = os.path.basename(cwd)
    
    # Try to get git branch if in a git repo
    try:
        import subprocess
        result = subprocess.run(
            ['git', 'branch', '--show-current'],
            capture_output=True,
            text=True,
            cwd=cwd
        )
        if result.returncode == 0:
            branch = result.stdout.strip()
            return f"📁 {project_name} ({branch})"
    except:
        pass
    
    return f"📁 {project_name}"


def main():
    try:
        # Read input from stdin
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        # If we can't parse JSON, exit silently
        sys.exit(0)
    except Exception:
        sys.exit(0)
    
    # Check if we should send notifications for this event type
    config = NotificationConfig()
    hook_event = input_data.get('hook_event_name', '')
    
    should_notify = False
    notification_type = "info"
    
    if hook_event == 'Notification' and config.notify_on_waiting:
        should_notify = True
        notification_type = "warning"
    elif hook_event in ['Stop', 'SubagentStop'] and config.notify_on_completion:
        should_notify = True
        notification_type = "success"
    elif hook_event in ['PreToolUse', 'PostToolUse']:
        # Only notify for certain tools or if explicitly configured
        tool_name = input_data.get('tool_name', '')
        if tool_name in ['Task', 'Bash'] and config.notify_on_completion:
            should_notify = True
    
    if not should_notify:
        sys.exit(0)
    
    # Create and send notification
    notifier = NotificationManager()
    
    # Format the message
    base_message = format_notification_message(input_data)
    project_context = get_project_context()
    
    full_message = f"{base_message}\n{project_context}"
    
    # Add timestamp
    timestamp = datetime.now().strftime("%H:%M:%S")
    full_message += f"\n🕐 {timestamp}"
    
    # Send the notification
    results = notifier.send_notification(full_message, notification_type)
    
    # Log results if debugging
    if os.getenv('CLAUDE_DEBUG_NOTIFICATIONS'):
        for result in results:
            print(result, file=sys.stderr)
    
    sys.exit(0)


if __name__ == '__main__':
    main()
