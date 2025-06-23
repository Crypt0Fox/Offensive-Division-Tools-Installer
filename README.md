# 🦊 Offensive-Division-Tool-Installer

A plug & play battle-ready arsenal for **Kali Linux** — built for Red Teamers, Ethical Hackers, and Cyber Operators.
get your hands on the Offensive-Division Battle Station!

# 🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸

## ⚙️ What's Inside

- 🚀 Fully automated install script (1 run → full setup)
- 🧠 `pipx`, `venv`, and Docker-based isolation
- 🧪 Battle-tested tools: BloodHound CE, Impacket, AutoRecon, DonPAPI, NetExec, SCCMHunter, Certipy, Proxmark3, and more
- 📂 Clean `/opt/` structure for categorized tools (recon, AD abuse, lateral, post-ex)
- 🔁 Daily systemd healthcheck service (Unit6)
- 🎨 Terminal bling: figlet, lolcat, cmatrix, fortune
- 🔧 Shell aliases, prompt, banners, and rebuild-safe

## 🔌 Pre-Requisites

VMware Workstation 17.x (preferably) with Kali Linux VM machine already on your system, listed on VMware VM machines.
Get the latest official Kali Linux VM machine from their official website: https://www.kali.org/get-kali/#kali-virtual-machines
The latest package true to the time of writing this Readme is: https://cdimage.kali.org/kali-2025.2/kali-linux-2025.2-vmware-amd64.7z 

Ideal hardware settings recommendation (it is, if your host computer is strong enough - mine is: RTX 3080 Ti, 64 GB RAM):
<img width="536" alt="2025-06-23 19_37_53-Virtual Machine Settings" src="https://github.com/user-attachments/assets/5cb20052-dbbc-4ecf-a56f-7f9962136a37" />

## 🧰 Install

cd /home/kali/Documents/ && sudo apt update && echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections && sudo apt install -y git needrestart && echo '$nrconf{restart} = "a";' | sudo tee /etc/needrestart/conf.d/99-auto.conf && sudo git clone https://github.com/Crypt0Fox/Offensive-Division-Tools-Installer.git && cd Offensive-Division-Tools-Installer && sudo chown kali * && sudo chmod +x install.sh && sudo ./install.sh -y


## 📎 Tools Deployed

- BloodHound CE (Docker + ingestors)
- AutoRecon, Certipy, BobTheSmuggler
- Impacket, NetExec, DonPAPI, SCCMHunter
- Responder, Chisel, ProxMark3
- Plus dozens more from your 🔥 Foxy Arsenal

## 📍 Logs & Health

- Healthcheck logs: `/var/log/unit6_healthcheck.log`
- Tool location: `/opt/[category]/[toolname]`
- Extra binaries: `$HOME/bin/`

## 🧼 After Install

✔️ Reboot completes Docker group setup  
✔️ Type `cmatrix` if you want to feel like a cyber god 😎 (... or whenever you need to hide your battlescreen 😜)
✔️ Enjoy the banner every terminal launch

## 📜 License

[MIT](LICENSE)

# 🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸🔸
# - Built by CryptoFox.
## Stay Sharp. Stay Frosty. Stay Offensive. 🦊

