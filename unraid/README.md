# Unraid Scripts 🚀

A collection of useful scripts for **Unraid User Scripts**.

## 📌 Available Scripts

### 🔹 Boot Backup
**Description:** Backs up the USB stick.
- 🕒 **Schedule:** Every 1 hour
- 🔒 **Security:** The created ZIP archive is password-protected.

### 🔹 Nextcloud Login Audit
**Description:** Monitors the `nextcloud.log` for failed login attempts.
- 🛑 **What it does:**
  - Extracts **IP address, username, and request ID** of failed logins.
  - Logs the details and sends a notification via **Unraid Notification System** (Telegram, Email, etc.).
  - Ensures the same request ID is ignored in future scans.

---
📢 Stay tuned for updates and improvements! 🚀
