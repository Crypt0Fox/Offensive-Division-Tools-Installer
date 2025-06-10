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
# Install essentials (no inline comments in the package list)
sudo apt install -y \
  isc-dhcp-client curl wget \
  git unzip python3 python3-pip python3-venv build-essential \
  jq net-tools docker.io docker-compose cmatrix lolcat figlet zsh fzf bat ripgrep

# Install Starship prompt
curl -sS https://starship.rs/install.sh -o install_starship.sh
echo "b3d1f1e5d5c3e4a6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0  install_starship.sh" | sha256sum -c --status
if [ $? -eq 0 ]; then
  sh install_starship.sh -y
  rm install_starship.sh
  # Ensure PATH persists across sessions
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  fi
  if [ -f "$HOME/.zshrc" ] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  fi
else
  echo "Checksum verification failed for Starship installer. Aborting."
  exit 1
fi

# Ensure starship and pipx are installed before using them
if ! command -v starship &> /dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
if ! command -v pipx &> /dev/null; then
  python3 -m pip install --user pipx
  export PATH="$HOME/.local/bin:$PATH"
fi
RUST_INSTALL_SCRIPT_URL="https://sh.rustup.rs"
RUST_INSTALL_SCRIPT_CHECKSUM="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" # Replace with actual checksum
curl -sSf "$RUST_INSTALL_SCRIPT_URL" -o rustup-init.sh
echo "$RUST_INSTALL_SCRIPT_CHECKSUM rustup-init.sh" | sha256sum --check --status
if [ $? -eq 0 ]; then
  sh rustup-init.sh -y
  rm rustup-init.sh
else
  echo "Checksum verification failed for Rust installation script."
  exit 1
fi
sudo usermod -aG docker "$USER"
echo -e "${ORANGE}[!] You need to log out or reboot for Docker group changes to take effect.${NC}"
# === 2. Docker Setup ===
echo -e "${GREEN}[+] Configuring Docker...${NC}"
sudo systemctl enable docker --now
sudo usermod -aG docker "$USER"

# === 3. pipx & Rust Setup ===
echo -e "${GREEN}[+] Installing CLI tools via pipx...${NC}"
if [ -f "$HOME/.cargo/env" ]; then
  source $HOME/.cargo/env
else
  echo "Rust environment file not found. Ensure Rust installation completed successfully."
  exit 1
fi
export PATH="$HOME/.local/bin:$PATH"
pipx ensurepath
pipx ensurepath
hash -r
pipx install impacket
pipx install bloodhound-ce
pipx install git+https://github.com/Pennyw0rth/NetExec
pipx install git+https://github.com/login-securite/DonPAPI.git
pipx install git+https://github.com/garrettfoster13/sccmhunter
if [ -f "$HOME/.ssh/id_ed25519" ]; then
  echo -e "${ORANGE}[!] SSH key already exists.${NC}"
  read -p "[!] Overwrite existing SSH key? (y/N): " overwrite
  if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}[+] Skipping SSH key generation.${NC}"
    exit 0
  fi
fi

echo -e "${GREEN}[+] Generating SSH key...${NC}"
ssh-keygen -t ed25519 -C "cryptofox@offensive" -f "$HOME/.ssh/id_ed25519" -N ''
eval "$(ssh-agent -s)"
echo -e "${ORANGE}[!] Add the following SSH key to your GitHub account:${NC}"
echo "======================================"
cat "$HOME/.ssh/id_ed25519.pub"
echo "======================================"
echo -e "${ORANGE}Visit: https://github.com/settings/keys${NC}"
read -p "[+] Press Enter after adding the key to continue..."
fi

sudo mkdir -p /opt/{active-directory,binaries,credential-access,lateral-movement,post-exploitation,recon,webshells}
sudo chown -R "$USER:$USER" /opt/*
# === 5. Clone & Set Up Tools ===
cd /opt/recon && git clone https://github.com/Tib3rius/AutoRecon.git
cd AutoRecon && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && deactivate

cd /opt/active-directory && git clone https://github.com/BloodHoundAD/BloodHound.git BloodHoundCE
cd BloodHoundCE/docker && docker compose -f docker-compose.linux.yml up -d

# Add Proxmark3 build requirements
sudo apt install -y \
  gcc-arm-none-eabi \
  libbz2-dev \
  libssl-dev \
sudo apt install -y \
  gcc-arm-none-eabi \
  libbz2-dev \
  libssl-dev \
  libclang-dev \
  libbluetooth-dev \
  libpython3-dev
make clean && make -j$(nproc)
sudo make install
wget -nc -q https://github.com/jpillora/chisel/releases/download/v1.7.3/chisel_1.7.3_linux_amd64 -O chisel
chmod +x chisel
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
rc_packages=$(dpkg -l | awk '/^rc/ {print $2}')
if [[ -n "$rc_packages" ]]; then
  echo "Purging packages in 'rc' state: $rc_packages"
  sudo apt purge -y $rc_packages || {
    echo "Error occurred while purging packages. Please check manually."
rc_packages=$(dpkg -l | awk '/^rc/ {print $2}')
if [[ -n "$rc_packages" ]]; then
  echo "Purging packages in 'rc' state: $rc_packages"
  sudo apt purge -y $rc_packages || {
    echo "Error occurred while purging packages. Please check manually."
    exit 1
  }
fi
  echo -e "${GREEN}[+] Reboot canceled.${NC}"
  exit 0
elif [[ "$user_input" == "d" ]]; then
  echo -e "${ORANGE}[!] Delaying reboot. Please reboot manually when ready.${NC}"
  exit 0
elif [[ -z "$user_input" ]]; then
  echo -e "${ORANGE}[!] Timeout reached. Proceeding with reboot.${NC}"
  sudo reboot
else
  echo -e "${ORANGE}[!] Invalid input. Proceeding with reboot.${NC}"
  sudo reboot
fi