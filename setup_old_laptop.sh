#!/usr/bin/env bash
set -euo pipefail



[[ $EUID -ne 0 ]] || { echo "root가 아닌 일반 유저로 실행하세요"; exit 1; }



sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &



GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 시스템 업데이트 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

sudo pacman -Syu --noconfirm

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 시스템 업데이트 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] Pacman 패키지 정리 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

mapfile -t orphans < <(pacman -Qdtq || true)
if (( ${#orphans[@]} )); then
  sudo pacman -Rns --noconfirm "${orphans[@]}"
fi

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] Pacman 패키지 정리 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] yay 설치 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

sudo pacman -S --needed --noconfirm git base-devel
tmpdir="$(mktemp -d)"
git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
(cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
rm -rf "$tmpdir"

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] yay 설치 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 필요한 AUR 패키지 설치 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

yay -S --needed --noconfirm kdotool qview helium-browser-bin

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 필요한 AUR 패키지 설치 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] yay 캐시 정리 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

yay -Sc --noconfirm
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/yay"

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] yay 캐시 정리 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 기본 폴더 영문화 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

LC_ALL=C.UTF-8 xdg-user-dirs-update --force
rm -rf ~/바탕화면 ~/문서 ~/다운로드 ~/음악 ~/사진 ~/비디오 ~/공개 ~/프로젝트 ~/서식
rm -rf ~/.local/share/user-places.xbel

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 기본 폴더 영문화 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 환경 변수 등록 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

sudo tee /etc/environment >/dev/null <<'EOF'
XMODIFIERS=@im=fcitx
KWIN_WAYLAND_SUPPORT_XX_PIP_V1=1
EOF

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 환경 변수 등록 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 필요 서비스 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

sudo systemctl enable --now paccache.timer bluetooth.service fstrim.timer keyd cronie.service

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 필요 서비스 시작 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 커널 파라미터 최적화 설정\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

for param in "mitigations=off" "cpufreq.default_governor=performance"; do
  if ! grep -q "$param" /etc/kernel/cmdline; then
    sudo sed -i "s/$/ $param/" /etc/kernel/cmdline
  fi
done

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 커널 파라미터 최적화 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 부팅 속도 최적화 시작\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

sudo systemctl disable NetworkManager-wait-online.service
systemctl --user mask plasma-powerdevil.service 2>/dev/null || true
sudo systemctl mask systemd-udev-settle.service serial-getty@ttyS0.service

sudo mkinitcpio -P

sudo mkdir -p /etc/systemd/system/NetworkManager.service.d
sudo tee /etc/systemd/system/NetworkManager.service.d/override.conf > /dev/null << 'EOF'
[Service]
Type=simple
EOF

sudo mkdir -p /etc/systemd/system/plasmalogin.service.d
sudo tee /etc/systemd/system/plasmalogin.service.d/override.conf > /dev/null << 'EOF'
[Unit]
After=
After=systemd-user-sessions.service

[Service]
ExecStartPre=
EOF

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] 부팅 속도 최적화 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] kwallet 비활성화\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"

kwriteconfig6 --file kwalletrc --group Wallet --key Enabled false
killall kwalletd6 kwalletd5 2>/dev/null || true

echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] kwallet 비활성화 ${GREEN}완료${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"
echo -e "${GREEN}#########################################################${NC}\n"





echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}설정 완료${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}설정 완료${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}설정 완료${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}설정 완료${NC}\n"
echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}설정 완료${NC}\n"





read -rp "설정 완료. 지금 재부팅할까요? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  sudo systemctl reboot
fi
