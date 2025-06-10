#!/bin/bash
set -e

# Colors
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
NC="\033[0m"

# === Environment Setup ===
export DEBIAN_FRONTEND=noninteractive

# === 0. Update & Essentials ===
echo -e "${GREEN}[+] Updating and installing essentials...${NC}"
sudo apt update
read -p "[!] Proceed with full-upgrade? This may remove essential packages. (y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  sudo apt full-upgrade -y
else
  echo "[!] Skipping full-upgrade. Proceeding with regular upgrade."
  sudo apt upgrade -y
fi
sudo apt install -y \
  isc-dhcp-client curl wget git unzip python3 python3-pip python3-venv build-essential \
  jq net-tools docker.io docker-compose pipx cmatrix lolcat figlet zsh fzf bat ripgrep \
  fortune gedit libreadline-dev libusb-0.1-4 pkg-config libpcsclite-dev pcscd

# === 1. Shell & Aesthetics ===
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
echo 'figlet "STAY SHARP" | lolcat' >> ~/.zshrc
echo 'fortune | lolcat' >> ~/.zshrc

# === 2. Docker Setup ===
echo -e "${GREEN}[+] Configuring Docker...${NC}"
sudo systemctl enable docker --now
sudo usermod -aG docker "$USER"
# Installing pipx without the --break-system-packages flag to avoid conflicts with system-managed Python packages
python3 -m pip install --user pipx --break-system-packages
# === 3. pipx & Rust Setup ===
echo -e "${GREEN}[+] Installing CLI tools via pipx...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh -s -- -y
source $HOME/.cargo/env
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
pipx ensurepath
hash -r
hash -r
pipx install impacket
pipx install bloodhound-ce
pipx install git+https://github.com/Pennyw0rth/NetExec
pipx install git+https://github.com/login-securite/DonPAPI.git
pipx install git+https://github.com/garrettfoster13/sccmhunter

# === 4. Create /opt Layout ===
echo -e "${GREEN}[+] Creating tool directories...${NC}"

# === SSH Key Setup ===
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo -e "${GREEN}[+] Generating SSH key...${NC}"
  ssh-keygen -t ed25519 -C "cryptofox@offensive" -f "$HOME/.ssh/id_ed25519" -N ''
  eval "$(ssh-agent -s)"
  ssh-add "$HOME/.ssh/id_ed25519"
  echo -e "${ORANGE}[!] Add the following SSH key to your GitHub account:${NC}"
  echo "======================================"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo "======================================"
  echo -e "${ORANGE}Visit: https://github.com/settings/keys${NC}"
  read -p "[+] Press Enter after adding the key to continue..."
else
  echo -e "${GREEN}[+] SSH key already exists, skipping.${NC}"
fi

sudo mkdir -p /opt/{active-directory,binaries,credential-access,lateral-movement,post-exploitation,recon,webshells}
sudo chown -R "$USER:$USER" /opt/*
# === 5. Clone & Set Up Tools ===
[ -d /opt/recon/AutoRecon/.git ] || git clone https://github.com/Tib3rius/AutoRecon.git /opt/recon/AutoRecon
cd AutoRecon && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && deactivate

[ -d /opt/active-directory/BloodHoundCE/.git ] || git clone https://github.com/BloodHoundAD/BloodHound.git /opt/active-directory/BloodHoundCE
cd BloodHoundCE/docker && docker compose -f docker-compose.linux.yml up -d

# Add Proxmark3 build requirements
sudo apt install -y \
  gcc-arm-none-eabi \
  libbz2-dev \
  libssl-dev \
  libclang-dev \
  libbluetooth-dev \
  libpython3-dev
  
# === 6. Proxmark3 (RFID Recon) ===
cd /opt/recon
[ -d /opt/recon/proxmark3/.git ] || git clone https://github.com/RfidResearchGroup/proxmark3.git /opt/recon/proxmark3
# create global link
mkdir -p "$HOME/bin"
# Add Proxmark3 build requirements
sudo apt install -y \
  gcc-arm-none-eabi \
  libbz2-dev \
  libssl-dev \
  libclang-dev \
  libbluetooth-dev \
  libpython3-dev

# === 8. Python Venv Tools ===
install_python_tool() {
  REPO=$1; FOLDER=$2; DEST=$3
  cd "/opt/$DEST" && git clone "$REPO" "$FOLDER"
  cd "$FOLDER"; python3 -m venv venv && source venv/bin/activate
  pip install -r requirements.txt || true
  deactivate
}
install_python_tool https://github.com/ly4k/Certipy.git Certipy-5.0.2 active-directory
install_python_tool https://github.com/0xJs/BobTheSmuggler.git BobTheSmuggler recon

# === 9. Unit6 Healthcheck ===
cat << 'EOF' | sudo tee /opt/unit6_healthcheck.sh > /dev/null
#!/bin/bash
LOG="/var/log/unit6_healthcheck.log"
echo "=== $(date) ===" >> "$LOG"
if systemctl is-active --quiet docker; then echo "Docker OK" >> "$LOG"; else echo "Docker FAIL — restarting" >> "$LOG" && systemctl restart docker; fi
if docker ps --filter "name=bloodhound_ce" --filter "status=running" | grep -q .; then echo "BloodHound OK" >> "$LOG"; else echo "BloodHound FAIL — bringing up" >> "$LOG" && cd /opt/active-directory/BloodHoundCE/docker && docker compose -f docker-compose.linux.yml up -d >> "$LOG" 2>&1; fi
echo "" >> "$LOG"
EOF

sudo chmod +x /opt/unit6_healthcheck.sh

cat << 'EOF' | sudo tee /etc/systemd/system/unit6-healthcheck.service > /dev/null
[Unit]
Description=Unit6 Offensive Tools Healthcheck
After=network-online.target docker.service
[Service]
ExecStart=/opt/unit6_healthcheck.sh
Type=oneshot
[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' | sudo tee /etc/systemd/system/unit6-healthcheck.timer > /dev/null
[Unit]
Description=Daily Unit6 Healthcheck Timer
[Timer]
OnBootSec=2min
OnUnitActiveSec=1d
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now unit6-healthcheck.timer

# === 10. Final Cleanup ===
sudo apt update
sudo apt upgrade -y
sudo apt -s autoremove
sudo apt autoremove -y
sudo apt autoclean -y
if dpkg -l | awk '/^rc/ {print $2}' | grep -q .; then
  sudo apt purge -y $(dpkg -l | awk '/^rc/ {print $2}') || true
else
  echo "No packages in 'rc' state to purge."
fi

# === 11. Final Checks ===
echo -e "${ORANGE}Press 'c' to cancel, 'd' to delay, or any other key to proceed with the reboot.${NC}"
read -n 1 -t 60 user_input
if [[ "$user_input" == "c" ]]; then
  echo -e "${GREEN}[+] Reboot canceled.${NC}"
  exit 0
elif [[ "$user_input" == "d" ]]; then
  exit 0
else
  echo -e "${ORANGE}[!] Proceeding with reboot.${NC}"
fi
sleep 60
elif [[ "$user_input" == "d" ]]; then
  echo -e "${ORANGE}[!] Delaying reboot. Please reboot manually when ready.${NC}"
  exit 0
else
  echo -e "${ORANGE}[!] Proceeding with reboot.${NC}"
fi

# === Final Reboot Block ===
echo -e "${ORANGE}[!] Rebooting in 60 seconds to finalize setup.${NC}"
echo -e "${ORANGE}Cancel with CTRL+C or run 'init 6' if needed sooner.${NC}"
sleep 60
sudo reboot