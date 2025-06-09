```md
# 🦊 Offensive-Division-Tool-Installer

A plug & play battle-ready arsenal for **Kali Linux** — built for Red Teamers, Ethical Hackers, and Cyber Operators.

## ⚙️ What's Inside

- 🚀 Fully automated install script (1 run → full setup)
- 🧠 `pipx`, `venv`, and Docker-based isolation
- 🧪 Battle-tested tools: BloodHound CE, Impacket, AutoRecon, DonPAPI, NetExec, SCCMHunter, Certipy, Proxmark3, and more
- 📂 Clean `/opt/` structure for categorized tools (recon, AD abuse, lateral, post-ex)
- 🔁 Daily systemd healthcheck service (Unit6)
- 🎨 Terminal bling: figlet, lolcat, cmatrix, fortune
- 🔧 Shell aliases, prompt, banners, and rebuild-safe

## 🧰 Install

```

git clone [https://github.com/Crypt0Fox/Offensive-Division-Tool-Installer.git](https://github.com/Crypt0Fox/Offensive-Division-Tool-Installer.git)
cd Offensive-Division-Tool-Installer
chmod +x install.sh
sudo ./install.sh

```

## 📎 Tools Deployed

- BloodHound CE (Docker + ingestors)
- AutoRecon, Certipy, BobTheSmuggler
- Impacket, NetExec, DonPAPI, SCCMHunter
- Responder, Chisel, Proxmark3
- Plus dozens more from your 🔥 Foxy Arsenal

## 📍 Logs & Health

- Healthcheck logs: `/var/log/unit6_healthcheck.log`
- Tool location: `/opt/[category]/[toolname]`
- Extra binaries: `$HOME/bin/`

## 🧼 After Install

✔️ Reboot completes Docker group setup  
✔️ Type `cmatrix` if you want to feel like a cyber god 😎  
✔️ Enjoy the banner every terminal launch

## 📜 License

[MIT](LICENSE)

---

**Built by CryptoFox. Stay sharp. Stay offensive. 🦊💣**
```
