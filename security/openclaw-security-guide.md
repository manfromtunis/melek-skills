# How I Secured My OpenClaw VPS in 30 Minutes (So Hackers Can't Turn My AI Agent Against Me)

135,000 OpenClaw instances were found exposed to the internet in early 2026. 20% of ClawHub skills are malicious. A critical RCE vulnerability lets attackers take over your agent with one click.

I just set up OpenClaw on a fresh Contabo VPS. Here's exactly how I locked it down.

---

## Part 1: SSH Hardening

Your VPS is a door. Default config leaves it wide open with a "Welcome" mat.

### 1.1 SSH Key Authentication (Bitwarden)

I used Bitwarden's built-in SSH agent — private key never touches the filesystem.

**Generate key in Bitwarden:**
- Bitwarden Desktop > + New Item > SSH Key
- Generate SSH Key (Ed25519)
- Name it after your server

**Enable Bitwarden SSH Agent (Windows):**
```powershell
# Disable Windows OpenSSH Agent — Bitwarden replaces it
Get-Service ssh-agent | Stop-Service
Set-Service ssh-agent -StartupType Disabled
```
Then: Bitwarden Desktop > Settings > SSH Agent > Enable

**Add public key to VPS:**
```bash
mkdir -p ~/.ssh && echo "YOUR_PUBLIC_KEY" >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

**Test key login works before proceeding.**

### 1.2 Disable Password Authentication

```bash
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart ssh
```

### 1.3 Change SSH Port

Default port 22 gets hammered by bots. Moving to a non-standard port eliminates 99% of automated attacks.

```bash
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
systemctl restart ssh
```

### 1.4 Firewall

```bash
ufw allow 2222/tcp
ufw deny 22/tcp
ufw enable
```

### 1.5 Fail2ban

3 failed attempts in 10 minutes = banned for 1 hour.

```bash
apt install fail2ban -y
nano /etc/fail2ban/jail.local
```

Add:
```
[sshd]
enabled = true
port = 2222
maxretry = 3
bantime = 3600
findtime = 600
```

```bash
systemctl enable fail2ban --now
```

### 1.6 Automatic Security Updates

```bash
apt install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades
```

---

## Part 2: OpenClaw Hardening

SSH protects the door. Now protect what's inside.

### 2.1 Bind Gateway to Localhost

By default, OpenClaw binds to `0.0.0.0:18789` — every IP on the internet can reach it. This is how 135,000 instances got exposed.

```bash
openclaw config set gateway.bind "loopback"
```

### 2.2 Disable ClawHub Auto-Install

Cisco found 20% of ClawHub skills are malicious. They run with the same permissions as your agent — full system access.

On OpenClaw 2026.3.7, skills are manual-install only by default. Verify:
```bash
openclaw config get skills
```

If you see `autoInstall: true`, disable it.

### 2.3 Update OpenClaw

CVE-2026-25253 (CVSS 8.8) — one-click remote code execution, even on localhost-bound instances.

```bash
openclaw update
```

### 2.4 Set Gateway Auth Token

```bash
openclaw config set gateway.token "$(openssl rand -hex 32)"
```

### 2.5 Enable Sandbox

```bash
openclaw config set sandbox.enabled true
```

### 2.6 Audit Installed Skills

```bash
openclaw skills list
```

Remove anything you didn't install yourself.

### 2.7 Run Security Audit

```bash
openclaw security audit
openclaw security audit --deep
```

---

## Quick Verification Checklist

Run these to confirm everything is locked down:

```bash
# SSH: key-only on port 2222
ssh -p 2222 root@YOUR_VPS_IP

# Firewall: only 2222 open
ufw status

# OpenClaw: not exposed publicly
ss -tlnp | grep 18789
# Should show 127.0.0.1:18789, NOT 0.0.0.0:18789

# Fail2ban: active
systemctl status fail2ban

# Tailscale: connected
tailscale status

# No unknown skills
openclaw skills list

# Security audit clean
openclaw security audit
```

---

## Part 3: Tailscale (Zero-Trust Network)

SSH hardening protects the port. Tailscale removes the port from the internet entirely.

With Tailscale, your VPS is only reachable by your own devices — no public IP exposure, no open ports needed.

### 3.1 Install on VPS

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

With Tailscale SSH (replaces OpenSSH for device-to-device access):
```bash
sudo tailscale up --ssh
```

### 3.2 Install on Your Devices

Install Tailscale on each device you want to connect from, then:

```bash
tailscale up
```

Or with SSH enabled:
```bash
sudo tailscale up --ssh
```

### 3.3 Verify Connection

```bash
tailscale status
tailscale ping <device-name>
```

### 3.4 Access VPS via Tailscale

Instead of `ssh -p 2222 root@PUBLIC_IP`, use:

```bash
ssh user@<tailscale-device-name>
# or
ssh user@<tailscale-ip>
```

No public IP, no open port, no bot traffic.

### 3.5 Lock It Down Further

**Do:**
- Use Tailscale SSH when possible (no SSH keys to manage)
- Set up ACLs / policy rules in the Tailscale admin console
- Enable device approval (new devices need manual approval)
- Enable MFA on your Tailscale account

**Never share publicly:**
- Auth keys or reusable setup tokens
- Tailnet name
- Internal Tailscale IPs
- Real hostnames (use generic names if showing on stream)

### 3.6 Firewall Update

Once Tailscale is working, you can close the public SSH port entirely:

```bash
ufw deny 2222/tcp
ufw allow in on tailscale0
ufw reload
```

Now the VPS is only reachable through your Tailscale network.

---

## What We Didn't Do (And Why)

- **2FA for SSH** — Not needed. Key-based auth is already stronger than password + 2FA.
- **Docker isolation** — Worth adding later for production. Our sandbox mode covers the basics.

---

## Total Time: ~30 minutes

**Before:** Default VPS, password auth, OpenClaw exposed to the internet.

**After:** Key-only SSH on non-standard port, firewall, fail2ban, auto-updates, OpenClaw locked to localhost with auth token and sandbox.

Your AI agent is powerful. Make sure you're the only one controlling it.

---

*Built live on stream with Claude Code. Full checklist available in the GitHub repo.*
