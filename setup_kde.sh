#!/usr/bin/env bash
set -euo pipefail

[[ $EUID -ne 0 ]] || { echo "root가 아닌 일반 유저로 실행하세요"; exit 1; }

sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

sudo pacman -Syu --noconfirm

mapfile -t orphans < <(pacman -Qdtq || true)
if (( ${#orphans[@]} )); then
  sudo pacman -Rns --noconfirm "${orphans[@]}"
fi

sudo pacman -S --needed --noconfirm git base-devel
tmpdir="$(mktemp -d)"
git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
(cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
rm -rf "$tmpdir"

yay -S --needed --noconfirm clion clion-jre kdotool qview cachydpi

yay -Sc --noconfirm
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/yay"

LC_ALL=C.UTF-8 xdg-user-dirs-update --force
rm -rf ~/바탕화면 ~/문서 ~/다운로드 ~/음악 ~/사진 ~/비디오 ~/공개 ~/프로젝트 ~/서식
rm -rf ~/.local/share/user-places.xbel

sudo tee /etc/environment >/dev/null <<'EOF'
XMODIFIERS=@im=fcitx
KWIN_WAYLAND_SUPPORT_XX_PIP_V1=1
EOF

sudo systemctl enable --now paccache.timer bluetooth.service fstrim.timer keyd cachydpi.service cronie.service

grep -q 'mitigations=off' /etc/kernel/cmdline || \
  sudo sed -i '1s/$/ rw quiet mitigations=off/' /etc/kernel/cmdline

sudo sed -i 's/$/ cpufreq.default_governor=performance/' /etc/kernel/cmdline

sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Arch Linux Zen" --loader '\EFI\Linux\arch-linux-zen.efi' --unicode
sudo bootctl remove

sudo systemctl disable NetworkManager-wait-online.service
systemctl --user mask plasma-powerdevil.service

sudo mkinitcpio -P

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
