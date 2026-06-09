#!/usr/bin/env bash
# TABIAN OS - Phase 2 Provisioner

set -e

# ==========================================
# ROOT PRIVILEGE CHECK
# ==========================================
if [ "$EUID" -ne 0 ]; then
    echo " ERROR: Tabian OS Setup requires root privileges."
    echo " Please run this script using: sudo $0"
    exit 1
fi

echo -e  " \e[36m Initializing Tabian OS Core Configurations...\e[0m"

# Ensure the local environment is fully synchronized 
# (Fast because packages from core.packages are already present)
sudo apt-get update -y

# Configure a baseline firewall layout
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable

# Enable core background daemons
sudo systemctl enable NetworkManager

echo -e "\e[36m Global baseline configured successfully!\e[0m"
# Force the magenta/pink color scheme
export NEWT_COLORS='root=,magenta;window=,lightgray;textbox=,lightgray;button=black,;actbutton=white,black;actcheckbox=,cyan;checkbox=,black;actlistbox=black,cyan'
# Initialize all flags to 0 (OFF)
INSTALL_GUI=0
INSTALL_NVIDIA=0
INSTALL_DEV=0
INSTALL_AI=0
INSTALL_FLATPAK=0
INSTALL_BRAVE=0
INSTALL_VLC=0
INSTALL_TEXT_EDITOR=0

# Initialize state machine
STEP=1

while [ $STEP -le 2 ]; do
    if [ $STEP -eq 1 ]; then
        # ==========================================
        # STAGE 1: CORE ARCHITECTURE
        # ==========================================
        set +e
        CORE_CHOICES=$(whiptail --title " Tabian OS - Step 1: Core Architecture " \
        --ok-button "Proceed" \
        --cancel-button "Cancel Setup" \
        --checklist "Select your base system components.\n\n[!] IMPORTANT: If you want to install desktop apps later (like Web Browsers, Media Players, or IDEs), you MUST select the 'GUI' option here!\n\n(Use Space to select, Tab to change buttons)" 22 75 5 \
        "GUI" "Desktop Environment (KDE Plasma & SDDM)" OFF \
        "NVIDIA" "Bare-Metal Nvidia Drivers & CUDA" OFF \
        "DEV" "ISO Builder Suite & Developer Tools" OFF \
        "AI" "Ollama AI Engine Core" OFF \
        "FLATPAK" "Flatpak Core System Layer" OFF \
        3>&1 1>&2 2>&3)
        EXIT_CODE=$?
        set -e

        # On Step 1, any non-zero code (Cancel button OR Esc key) exits entirely
        if [ $EXIT_CODE -ne 0 ]; then
            clear; echo -e " \e[36mSetup cancelled by user. System remains unmodified.\e[0m"; exit 0
        fi

        # Reset variables
        INSTALL_GUI=0; INSTALL_NVIDIA=0; INSTALL_DEV=0; INSTALL_AI=0; INSTALL_FLATPAK=0

        [[ $CORE_CHOICES == *"\"GUI\""* ]] && INSTALL_GUI=1
        [[ $CORE_CHOICES == *"\"NVIDIA\""* ]] && INSTALL_NVIDIA=1
        [[ $CORE_CHOICES == *"\"DEV\""* ]] && INSTALL_DEV=1
        [[ $CORE_CHOICES == *"\"AI\""* ]] && INSTALL_AI=1
        [[ $CORE_CHOICES == *"\"FLATPAK\""* ]] && INSTALL_FLATPAK=1

        STEP=2 

    elif [ $STEP -eq 2 ]; then
        # ==========================================
        # STAGE 2: GRAPHICAL APPS (The Clean Skip)
        # ==========================================
        if [ $INSTALL_GUI -eq 0 ]; then
            STEP=3 
            break
        fi

        set +e
        APP_CHOICES=$(whiptail --title " Tabian OS - Step 2: GUI Applications " \
        --ok-button "Proceed" \
        --cancel-button "Go Back" \
        --checklist "Select optional graphical software:\n(Note: Selecting any app will automatically install Flatpak behind the scenes)\n\n(Use Space to select, Tab to change buttons)" 20 75 4 \
        "BRAVE" "Brave Web Browser" OFF \
        "VLC" "VLC Media Player" OFF \
        "TEXT_EDITOR" "a simple text editor" OFF \
        3>&1 1>&2 2>&3)
        EXIT_CODE=$?
        set -e

        # Explicit routing based on button vs keyboard action:
        if [ $EXIT_CODE -eq 255 ]; then
            # User smashed ESC key -> Immediate abort
            clear; echo -e " \e[36mSetup cancelled by user. System remains unmodified.\e[0m"; exit 0
        elif [ $EXIT_CODE -eq 1 ]; then
            # User tabbed over and selected "Go Back" button -> Return to Step 1
            STEP=1
            continue
        fi

        # Reset app variables
        INSTALL_BRAVE=0; INSTALL_VLC=0; INSTALL_TEXT_EDITOR=0

        [[ $APP_CHOICES == *"\"BRAVE\""* ]] && { INSTALL_BRAVE=1; INSTALL_FLATPAK=1; }
        [[ $APP_CHOICES == *"\"VLC\""* ]] && { INSTALL_VLC=1; INSTALL_FLATPAK=1; }
        [[ $APP_CHOICES == *"\"TEXT_EDITOR\""* ]] && { INSTALL_TEXT_EDITOR=1; INSTALL_FLATPAK=1; }

        STEP=3 
    fi
done
# ==========================================
# STAGE 3: VALIDATION & EXECUTION
# ==========================================
clear
echo -e " \e[36m Validating configuration profile...\e[0m"
echo "-------------------------------------------------------"

if [ $INSTALL_NVIDIA -eq 1 ]; then
    if systemd-detect-virt -q; then
        echo -e " \e[36m WARNING: Virtual Machine detected! Bypassing Nvidia driver installation to prevent boot loops.\e[0m"
        INSTALL_NVIDIA=0
        sleep 3
    else
        echo -e " \e[36m Bare-metal hardware detected. Nvidia installation approved.\e[0m"
    fi
fi
echo -e " \e[36m Profile validated! Beginning package downloads...\e[0m"
sleep 2

# --- BUNDLE: GLOBAL BASE (Always runs) ---
echo -e " \e[36mInstalling Global Base Components...\e[0m"
apt update
apt install -y linux-headers-$(uname -r) python3-pip python3-venv

# --- BUNDLE: DEVELOPER OS ---
if [ $INSTALL_DEV -eq 1 ]; then
    echo -e " \e[36m Installing Developer Tools...\e[0m"
    apt install -y distro-info-data simple-cdd
fi

# --- BUNDLE: HARDWARE GPU ---
if [ $INSTALL_NVIDIA -eq 1 ]; then
    echo -e " \e[36m Installing Nvidia Drivers & CUDA Toolkit...\e[0m"
    apt install -y nvidia-driver nvidia-cuda-toolkit
fi

# --- BUNDLE: GUI CORE ---
if [ $INSTALL_GUI -eq 1 ]; then
    echo -e " \e[36m Installing KDE Plasma Desktop Environment...\e[0m"
    apt install -y plasma-workspace kwin-wayland sddm konsole dolphin
    systemctl enable sddm
fi

# --- BUNDLE: FLATPAK CORE ---
if [ $INSTALL_FLATPAK -eq 1 ]; then
    echo -e " \e[36m Setting up Flatpak framework...\e[0m"
    apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# --- APPS (FLATPAK TARGETS) ---
if [ $INSTALL_BRAVE -eq 1 ]; then
    echo -e " \e[36m Installing Brave Browser...\e[0m"
    flatpak install -y flathub com.brave.Browser
fi

if [ $INSTALL_VLC -eq 1 ]; then
    echo -e " \e[36m Installing VLC Media Player...\e[0m"
    flatpak install -y flathub org.videolan.VLC
fi

if [ $INSTALL_TEXT_EDITOR -eq 1 ]; then
    echo -e " \e[36m Installing GNOME Text Editor (Native)...\e[0m"
    apt install -y gnome-text-editor
fi

# --- BUNDLE: LOCAL AI ---
if [ $INSTALL_AI -eq 1 ]; then
    echo -e " \e[36m Setting up Ollama Engine...\e[0m"
    if ! command -v ollama &> /dev/null; then
        curl -fsSL https://ollama.com/install.sh | sh
    else
        echo -e " \e[36m Ollama is already installed.\e[0m"
    fi
fi

echo -e " \e[36m==================================================\e[0m"
echo -e " \e[36m DEPLOYMENT COMPLETE!\e[0m"
echo -e " \e[36mIf a Desktop Environment was installed, the system will launch it upon reboot.\e[0m"
echo -e " \e[36m==================================================\e[0m"
read -p "Press Enter to reboot your system..."
systemctl reboot
