#!/usr/bin/env bash
set -euo pipefail

[[ $EUID -ne 0 ]] || { echo "root가 아닌 일반 유저로 실행하세요"; exit 1; }

sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

GREEN='\033[0;32m'
NC='\033[0m'

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 시스템 업데이트 시작"
echo "\n"

sudo pacman -Syu --noconfirm

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 시스템 업데이트 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Pacman 패키지 정리 시작"
echo "\n"

mapfile -t orphans < <(pacman -Qdtq || true)
if (( ${#orphans[@]} )); then
  sudo pacman -Rns --noconfirm "${orphans[@]}"
fi

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Pacman 패키지 정리 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] yay 설치 시작"
echo "\n"

sudo pacman -S --needed --noconfirm git base-devel
tmpdir="$(mktemp -d)"
git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
(cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
rm -rf "$tmpdir"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] yay 설치 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 필요한 AUR 패키지 설치 시작"
echo "\n"

yay -S --needed --noconfirm clion clion-jre kdotool qview cachydpi

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 필요한 AUR 패키지 설치 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] yay 캐시 정리 시작"
echo "\n"

yay -Sc --noconfirm
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/yay"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] yay 캐시 정리 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 기본 폴더 영문화 시작"
echo "\n"

LC_ALL=C.UTF-8 xdg-user-dirs-update --force
rm -rf ~/바탕화면 ~/문서 ~/다운로드 ~/음악 ~/사진 ~/비디오 ~/공개 ~/프로젝트 ~/서식
rm -rf ~/.local/share/user-places.xbel

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 기본 폴더 영문화 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 환경 변수 등록 시작"
echo "\n"

sudo tee /etc/environment >/dev/null <<'EOF'
XMODIFIERS=@im=fcitx
KWIN_WAYLAND_SUPPORT_XX_PIP_V1=1
EOF

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 환경 변수 등록 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 필요 서비스 시작"
echo "\n"

sudo systemctl enable --now paccache.timer bluetooth.service fstrim.timer keyd cachydpi.service cronie.service

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 필요 서비스 시작 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] mitigation 끄기"
echo "\n"

grep -q 'mitigations=off' /etc/kernel/cmdline || \
  sudo sed -i '1s/$/ rw quiet mitigations=off/' /etc/kernel/cmdline

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] mitigation 끄기 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 전원 관리 performance 설정 시작"
echo "\n"

sudo sed -i 's/$/ cpufreq.default_governor=performance/' /etc/kernel/cmdline

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 전원 관리 performance 설정 ${GREEN}완료${NC}"
echo "\n"

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 구형 시리얼 포트 드라이버 비활성화 시작"
echo "\n"

sudo sed -i 's/$/ 8250.nr_uarts=0/' /etc/kernel/cmdline

echo "\n"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 구형 시리얼 포트 드라이버 비활성화 ${GREEN}완료${NC}"
echo "\n"

sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Arch Linux Zen" --loader '\EFI\Linux\arch-linux-zen.efi' --unicode
sudo bootctl remove

sudo systemctl disable NetworkManager-wait-online.service
systemctl --user mask plasma-powerdevil.service
sudo systemctl mask systemd-udev-settle.service
sudo systemctl mask serial-getty@ttyS0.service

sudo sed -i -E '/^HOOKS=/ {
    s/\budev\b/systemd/g
    s/\b(keymap|consolefont)\b/sd-vconsole/g
    s/\b(usr|resume)\b//g
    s/sd-vconsole[[:space:]]+sd-vconsole/sd-vconsole/g
    s/[[:space:]]+/ /g
    s/\([[:space:]]+/(/g
    s/[[:space:]]+\)/)/g
}' /etc/mkinitcpio.conf

sudo mkinitcpio -P

# 1. NetworkManager 즉시 완료 처리
sudo mkdir -p /etc/systemd/system/NetworkManager.service.d
sudo tee /etc/systemd/system/NetworkManager.service.d/override.conf > /dev/null << 'EOF'
[Service]
Type=simple
EOF

# 2. plasmalogin 네트워크 대기 및 udevadm 10초 타임아웃 제거
sudo mkdir -p /etc/systemd/system/plasmalogin.service.d
sudo tee /etc/systemd/system/plasmalogin.service.d/override.conf > /dev/null << 'EOF'
[Unit]
After=
After=systemd-user-sessions.service

[Service]
ExecStartPre=
EOF

# 3. systemd 설정 일괄 반영
sudo systemctl daemon-reload

chezmoi init --apply https://github.com/hanminsik/dotfiles_kde.git

sudo mkdir -p /etc/keyd
sudo ln -s "$HOME/.config/keyd/default.conf" /etc/keyd/default.conf
sudo keyd reload

kwriteconfig6 --file kwalletrc --group Wallet --key Enabled false
killall kwalletd6 kwalletd5 2>/dev/null

read -rp "설정 완료. 지금 재부팅할까요? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  sudo systemctl reboot
fi
