#!/bin/bash

#### Colors ####
NC="\033[0m"
BLACK="\033[0;30m"
D_GRAY="\033[1;30m"
L_GRAY="\033[0;37m"
WHITE="\033[1;37m"
RED="\033[0;31m"
L_RED="\033[1;31m"
GREEN="\033[0;32m"
L_GREEN="\033[1;32m"
ORANGE="\033[0;33m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
L_BLUE="\033[1;34m"
PURPLE="\033[0;35m"
L_PURPLE="\033[1;35m"
CYAN="\033[0;36m"
L_CYAN="\033[1;36m"

#### Environment Setup ####
# ----------------------- KEEP KALI AWAKE -----------------------#
export DISPLAY=:0 #                                              #
export XAUTHORITY=/home/kali/.Xauthority #                       #
#                                                                #
## Kill screen lockers (optional)                                #
pkill gnome-screensaver 2>/dev/null #                            #
pkill xscreensaver 2>/dev/null #                                 #
#                                                                #
## Disable blanking and power-saving                             #
xset s off           # disable screen saver                      #
xset -dpms           # disable DPMS (Energy Star)                #
xset s noblank       # never blank the screen                    #
#                                                                #
## Gnome session idle timeout                                    #
gsettings set org.gnome.desktop.session idle-delay 0             #
gsettings set org.gnome.desktop.screensaver lock-enabled false # #
# ---------------------------------------------------------------#

#### GitHub SSH fingerprint fix ####
echo -e "${YELLOW}[!] Fixing GitHub SSH fingerprints...${NC}"

## Fetch and verify GitHub SSH fingerprints ##
declare -A GITHUB_KEYS
GITHUB_KEYS["rsa"]="SHA256:nThbg6z1Yx3Y1s6J1j8EY8V3R3VM5NlH4r9QCnd6F1lg"
GITHUB_KEYS["ecdsa"]="SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM"
GITHUB_KEYS["ed25519"]="SHA256:Hi1sPfbx91Q6sXQpF1s1dFfNZSQ2oP8gtG8j09m4sDYI"

## Timeout and validate ##
if ! timeout 5s ssh-keyscan github.com 2>/dev/null | tee /tmp/github_keys | tee -a ~/.ssh/known_hosts > /dev/null; then
  echo -e "${RED}[X] Failed to fetch GitHub SSH keys. Exiting.${NC}"
  exit 1
fi

while read -r line; do
  key_type=$(echo "$line" | awk '{print $2}')
  pub_key=$(echo "$line" | cut -d' ' -f2-)
  fingerprint=$(echo "$line" | ssh-keygen -lf /dev/stdin <<< "$line" | awk '{print $2}')
  expected_fp="${GITHUB_KEYS[$key_type]}"

  if [[ "$fingerprint" == "$expected_fp" ]]; then
    echo -e "${GREEN}[+] $key_type fingerprint verified.${NC}"
  else
    echo -e "${RED}[X] $key_type fingerprint mismatch.${NC}"
  fi
done < /tmp/github_keys

rm -f /tmp/github_keys
echo -e "${L_GREEN}[✓] GitHub SSH check complete.${NC}"


# === 0. Update & Essentials ===
echo -e "${GREEN}[+] Setting time zone to Asia/Jerusalem...${NC}"
sudo timedatectl set-timezone Asia/Jerusalem
sudo timedatectl set-ntp true
echo -e "${GREEN}[+] Updating and installing essentials...${NC}"
sudo apt update

## Automatically accept service restarts (needrestart) ===
sudo apt install -y needrestart
echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/99-auto.conf

## Make it timeout or skip safely + Allow bypassing boolean prompts ===
if [[ "$1" == "-y" ]]; then
  confirm="y"
else
read -t 10 -p "[!] Proceed with full-upgrade? (y/N, default=N in 10s):" confirm || confirm="n"
confirm=${confirm:-n}
fi
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  sudo apt full-upgrade -y
else
  echo -e "${YELLOW}[!] Skipping full-upgrade. Proceeding with regular upgrade.${NC}"
  sudo apt upgrade -y
fi
sudo apt install -y \
  isc-dhcp-client curl wget git unzip python3 python3-pip python3-venv build-essential \
  jq net-tools docker.io docker-compose cmatrix lolcat figlet  zsh fzf bat ripgrep \
  htop fortune gedit libreadline-dev libusb-0.1-4 pkg-config libpcsclite-dev pcscd starship


# === 1. Shell & Aesthetics ===
#echo 'eval "$(starship init zsh)"' >> ~/.zshrc
#echo 'figlet "STAY SHARP" | lolcat' >> ~/.zshrc
#echo 'fortune | lolcat' >> ~/.zshrc


# === 2. Docker Setup ===
echo -e "${GREEN}[+] Configuring Docker...${NC}"
sudo systemctl enable docker --now
sudo usermod -aG docker "$USER"

## Installing pipx without the --break-system-packages flag to avoid conflicts with system-managed Python packages ===
python3 -m pip install --user pipx --break-system-packages


# === 3. pipx & Rust Setup ===
echo -e "${GREEN}[+] Installing CLI tools via pipx...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh -s -- -y
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$PATH"
sleep 2 && hash -r
pipx ensurepath
hash -r
pipx install impacket
pipx install bloodhound-ce
pipx install git+https://github.com/Pennyw0rth/NetExec
pipx install git+https://github.com/login-securite/DonPAPI.git
pipx install git+https://github.com/garrettfoster13/sccmhunter


# === 4. Create /opt Layout ===
echo -e "${GREEN}[+] Creating tool directories...${NC}"

## SSH Key Setup ===
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo -e "${GREEN}[+] Generating SSH key...${NC}"
  ssh-keygen -t ed25519 -C "cryptofox@offensive" -f "$HOME/.ssh/id_ed25519" -N ''
  eval "$(ssh-agent -s)"
  ssh-add "$HOME/.ssh/id_ed25519"
  echo -e "${YELLOW}[!] Add the following SSH key to your GitHub account:${NC}"
  echo "======================================"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo "======================================"
  echo -e "${L_BLUE}Visit: https://github.com/settings/keys${NC}"
  echo -e "${CYAN}[+] Press Enter ONLY after adding the key to continue...${NC}"
  read -p "Waiting for you champ! When you are ready - Please Press Enter 🦊"
else
  echo -e "${L_GREEN}[✓] SSH key already exists, skipping.${NC}"
fi
sudo mkdir -p /opt/{active-directory,binaries,credential-access,lateral-movement,post-exploitation,recon,webshells}
sudo chown -R "$USER:$USER" /opt/*


# === 5. Clone & Set Up Tools ===
[ -d /opt/recon/AutoRecon/.git ] || git clone https://github.com/Tib3rius/AutoRecon.git /opt/recon/AutoRecon
if [ -d /opt/recon/AutoRecon ]; then
  cd /opt/recon/AutoRecon
  python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && deactivate
else
  echo -e "${RED}[X] AutoRecon clone failed or missing.${NC}"
fi
if [ ! -d /opt/active-directory/BloodHoundCE ]; then
  mkdir -p /opt/active-directory/BloodHoundCE
fi
cd /opt/active-directory/BloodHoundCE && \
wget https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz && \
tar -xvzf bloodhound-cli-linux-amd64.tar.gz && \
chmod +x bloodhound-cli && sudo mv bloodhound-cli /usr/local/bin/
./bloodhound-cli install | tee bloodhound_install.log
command -v bloodhound-cli || echo -e "${RED}[X] bloodhound-cli still not in PATH.${NC}"
grep -i -A2 -B2 "password" bloodhound_install.log > "/home/kali/Desktop/BloodHound-Password.txt"
sudo chown "$USER:$USER" "/home/kali/Desktop/BloodHound-Password.txt"

## Add Proxmark3 build requirements ===
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

# === 7. Psudohash ===
[ -d /opt/credential-access/psudohash/.git ] || git clone https://github.com/t3l3machus/psudohash.git /opt/credential-access/psudohash

# === 8. create global link ===
mkdir -p "$HOME/bin"
[ -L "$HOME/bin/proxmark3" ] || ln -s /opt/recon/proxmark3/client/proxmark3 "$HOME/bin/proxmark3"
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"


# === 9. Python Venv Tools ===
install_python_tool() {
  REPO=$1
  FOLDER=$2
  DEST=$3
  TARGET="/opt/$DEST/$FOLDER"
  if [ -d "$TARGET/.git" ]; then
    echo -e "${L_GREEN}[✓] $FOLDER already exists, skipping clone.${NC}"
  else
    echo -e "${YELLOW}[!] Cloning $FOLDER into $TARGET...${NC}"
    rm -rf "$TARGET"
    git clone "$REPO" "$TARGET"
  fi
  cd "$TARGET" || { echo "❌ Failed to enter $TARGET"; return 1; }
  echo -e "${GREEN}[+] Setting up venv for $FOLDER...${NC}"
  python3 -m venv venv && source venv/bin/activate
  if [ -f requirements.txt ]; then
    echo -e "${GREEN}[+] Installing requirements for $FOLDER...${NC}"
    pip install -r requirements.txt
  else
    echo -e "${YELLOW}[!] No requirements.txt found for $FOLDER.${NC}"
  fi
  deactivate
}
install_python_tool https://github.com/ly4k/Certipy.git Certipy-5.0.2 active-directory

## GitHub Host Key Verification & Automation ===
if ssh-keygen -F github.com >/dev/null; then
  echo -e "${L_GREEN}[✓] GitHub already in known_hosts, skipping scan.${NC}"
else
  echo -e "${YELLOW}[!] Adding GitHub to known_hosts securely...${NC}"
  ssh-keyscan github.com >> ~/.ssh/known_hosts
  chmod 600 ~/.ssh/known_hosts
  echo -e "${L_GREEN}[✓] GitHub host key added.${NC}"
fi

ssh -T git@github.com 2>&1 | grep -q 'successfully authenticated' || {
  echo -e "${RED}[X] SSH key not registered on GitHub. Please add it first.${NC}"
  echo -e "${L_BLUE}Visit: https://github.com/settings/keys${NC}"
  exit 1
}
install_python_tool https://github.com/TheCyb3rAlpha/BobTheSmuggler.git BobTheSmuggler recon


# === 10. Unit6 Healthcheck ===
cat << 'EOF' | sudo tee /opt/unit6_healthcheck.sh > /dev/null
#!/bin/bash
LOG="/var/log/unit6_healthcheck.log"
echo "=== $(date) ===" >> "$LOG"
if systemctl is-active --quiet docker; then echo "Docker OK" >> "$LOG"; else echo "Docker FAIL — restarting" >> "$LOG" && systemctl restart docker; fi
if docker ps --filter "ancestor=bloodhoundad/bloodhound-ce" --filter "status=running" | grep -q .; then echo "BloodHound OK" >> "$LOG"; else echo "BloodHound FAIL — bringing up" >> "$LOG" && if [ -d /opt/active-directory/BloodHoundCE/docker ]; then
  cd /opt/active-directory/BloodHoundCE/docker
  docker compose -f docker-compose.linux.yml up -d
else
  echo -e "${RED}[X] BloodHoundCE/docker not found. Clone may have failed.${NC}"
fi
 >> "$LOG" 2>&1; fi
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


# === 11. Final Cleanup ===
sudo apt update
sudo apt upgrade -y
sudo apt -s autoremove
sudo apt autoremove -y
sudo apt autoclean -y
if dpkg -l | awk '/^rc/ {print $2}' | grep -q .; then
  sudo apt purge -y $(dpkg -l | awk '/^rc/ {print $2}') || true
else
  echo -e "${YELLOW}[!] No packages in 'rc' state to purge.${NC}"
fi


# === 12. A lil'bit of Off3nsiv3 B3utifi3r Gay Sauc3 ===
echo -e "${GREEN}[+] Setting custom wallpaper and lock screen...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALL_SRC="/home/kali/Documents/Offensive-Division-Tools-Installer/R&D Materials/OffensiveWallpaper.png"
WALL_DST="/usr/share/backgrounds/kali-16x9/OffensiveWallpaper.png"
if [ -f "$WALL_SRC" ]; then
  sudo cp "$WALL_SRC" "$WALL_DST"
  
  ## Ensure new users (or first login) inherit this wallpaper ===
mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
XFCE_CONF="/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
cat <<EOF | sudo tee "$XFCE_CONF" > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop">
    <property name="screen0">
      <property name="monitor0">
        <property name="image-path" type="string" value="$WALL_DST"/>
      </property>
    </property>
  </property>
</channel>
EOF

  ## XFCE Desktop wallpaper ===
  xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALL_DST" || true

  ## LightDM lock/login screen (GTK Greeter) ===
  LIGHTDM_CONF="/etc/lightdm/lightdm-gtk-greeter.conf"
  sudo sed -i '/^background=/d' "$LIGHTDM_CONF"
  echo "background=$WALL_DST" | sudo tee -a "$LIGHTDM_CONF"
else
  echo -e "${RED}[X] Wallpaper not found: $WALL_SRC.${NC}"
fi


# === 13. Final Checks + Reboot Block ===
if [[ "$1" == "--auto" ]]; then
  user_input=""
else
  echo -e "${L_CYAN}✅ \"*~*Click*~* Nice!\" You've got to the finish line! 🦊${NC}"
  echo -e "${L_YELLOW}[!] Rebooting in 60 seconds to finalize setup.${NC}"
  echo -e "${ORANGE}[*] Cancel with CTRL+C (then run ${NC}${L_RED}'sudo reboot' ${NC}${ORANGE}manualy) - But, you've got to Reboot before using the system!)${NC} ${YELLOW}(${NC}${L_RED}o${NC}^${YELLOW}_${NC}^${L_RED}o${NC}${YELLOW})${NC}"
fi
sleep 60
echo -e "${L_GREEN}[✓] Rebooting Now !${NC}" && sudo reboot
