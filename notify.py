import os
import sys
import requests
import random
import string

if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass
if hasattr(sys.stderr, 'reconfigure'):
    try:
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

def read_file_if_exists(path, default=""):
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                val = f.read().strip()
                return val if val else default
        except Exception:
            return default
    return default

def get_status_info(status):
    status = status.lower()
    if status == 'start': return "🚀", "START", "Setting up build environment..."
    if status == 'download': return "⬇️", "DOWNLOAD", "Downloading base ROM..."
    if status == 'unpack': return "📦", "UNPACK", "Extracting images..."
    if status == 'build': return "⚙️", "BUILD", "Patching and modding system..."
    if status == 'pack': return "🗜️", "PACK", "Compressing to flashable zip..."
    if status == 'upload': return "☁️", "UPLOAD", "Uploading to Cloud..."
    if status == 'success': return "✅", "SUCCESS", "Build completed successfully!"
    if status == 'fail': 
        err_msg = read_file_if_exists("bin/ddevice/error_msg.txt")
        desc = err_msg if err_msg else "Execution halted. Check GitHub logs for details."
        return "❌", "FAILED", desc
    return "ℹ️", "UPDATE", status.upper()

def get_progress_bar(status):
    stages = ['start', 'download', 'unpack', 'build', 'pack', 'upload', 'success']
    status = status.lower()
    if status == 'fail':
        return "[❌ Build Failed]"
    
    current_index = -1
    if status in stages:
        current_index = stages.index(status)
        
    total = len(stages)
    filled = current_index + 1 if current_index >= 0 else 0
    bar = "█" * filled + "░" * (total - filled)
    percent = int((filled / total) * 100)
    return f"[{bar}] {percent}%"

def is_available(val):
    return val and val.strip() and val.lower() != 'không tìm thấy key' and 'not found' not in val.lower()

def send_notification(status, repo_name, rom_link, channel_id, bot_token, msg_id, build_id, builder_name, builder_id):
    icon, status_title, status_desc = get_status_info(status)
    action_url = f"https://github.com/{repo_name}/actions"
    
    device_name = read_file_if_exists("bin/ddevice/device_name.txt")
    codename = read_file_if_exists("bin/ddevice/device_code.txt")
    if not codename: codename = read_file_if_exists("bin/ddevice/device_f.txt")
    rom_os = read_file_if_exists("bin/ddevice/rom_os.txt")
    version_rom = read_file_if_exists("bin/ddevice/base_rom_code.txt")
    if not version_rom: version_rom = read_file_if_exists("bin/ddevice/base_build_id.txt")
    output_zip = read_file_if_exists("bin/ddevice/output_zip.txt")

    builder_text = builder_name if builder_name else "HalcyonOS System"

    lines = [
        f"HalcyonOS Builder",
        f"------------------",
        f"Builder: {builder_text}"
    ]

    if is_available(device_name): lines.append(f"Device: {device_name}")
    if is_available(codename): lines.append(f"Codename: {codename}")
    if is_available(version_rom): lines.append(f"OS Version: {version_rom}")
        
    lines.append(f"------------------")
    lines.append(f"Status: {status_title}")
    lines.append(f"Details: {status_desc}")
    lines.append(f"Progress: {get_progress_bar(status)}")
    lines.append("")

    if status.lower() == 'success':
        if output_zip: lines.append(f"File: {output_zip}")
        lines.append(f"Download: <a href=\"https://drive.google.com/drive/folders/1B11DL6aX7ZUKfawxwT8Do1mfX9hoxINp?usp=sharing\">Google Drive</a>")
        lines.append("")

    lines.append(f"Logs: <a href=\"{action_url}\">View GitHub</a>")

    message = "\n".join(lines)

    if msg_id:
        url = f"https://api.telegram.org/bot{bot_token}/editMessageText"
        payload = {"chat_id": channel_id, "message_id": msg_id, "text": message, "parse_mode": "HTML", "disable_web_page_preview": True}
    else:
        url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
        payload = {"chat_id": channel_id, "text": message, "parse_mode": "HTML", "disable_web_page_preview": True}

    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        res_data = response.json()
        new_msg_id = res_data.get('result', {}).get('message_id')
        
        if not msg_id and new_msg_id and "GITHUB_ENV" in os.environ:
            with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as f:
                f.write(f"TELEGRAM_MSG_ID={new_msg_id}\n")
            
        if status.lower() in ['success', 'fail'] and builder_id:
            pm_url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
            pm_text = f"BUILD SUCCESSFUL!\n\n{message}" if status.lower() == 'success' else f"BUILD FAILED!\n\n{message}\n\nPlease check the GitHub logs for details."
            pm_payload = {"chat_id": builder_id, "text": pm_text, "parse_mode": "HTML", "disable_web_page_preview": True}
            try: requests.post(pm_url, json=pm_payload)
            except Exception: pass

    except Exception as e:
        print(f"Error sending notification: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(1)

    status = sys.argv[1]
    repo_name = sys.argv[2]
    rom_link = sys.argv[3]
    prefix = sys.argv[4] if len(sys.argv) > 4 else "build"
    builder_name = sys.argv[5] if len(sys.argv) > 5 else ""
    builder_id = sys.argv[6] if len(sys.argv) > 6 else ""
    
    bot_token = os.environ.get("TELEGRAM_BOT_TOKEN")
    channel_id = os.environ.get("TELEGRAM_CHANNEL_ID")
    msg_id = os.environ.get("TELEGRAM_MSG_ID") 
    build_id = os.environ.get("TELEGRAM_BUILD_ID")

    if not build_id:
        build_id = f"{prefix}_{''.join(random.choices(string.digits, k=8))}"
        if "GITHUB_ENV" in os.environ:
            with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as f:
                f.write(f"TELEGRAM_BUILD_ID={build_id}\n")

    if bot_token and channel_id:
        send_notification(status, repo_name, rom_link, channel_id, bot_token, msg_id, build_id, builder_name, builder_id)
