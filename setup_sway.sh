#!/usr/bin/env bash
set -euo pipefail

# 일반 유저로 실행하고, 필요한 곳에서만 sudo를 쓰기
[[ $EUID -ne 0 ]] || { echo "root가 아닌 일반 유저로 실행하세요"; exit 1; }

# sudo 비밀번호를 한 번만 받고 스크립트가 끝날 때까지 캐시 유지
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

# 전체 업데이트
sudo pacman -Syu --noconfirm

# 고아 패키지 제거 (없으면 건너뜀)
mapfile -t orphans < <(pacman -Qdtq || true)
if (( ${#orphans[@]} )); then
  sudo pacman -Rns --noconfirm "${orphans[@]}"
fi

# yay 설치
sudo pacman -S --needed --noconfirm git base-devel
tmpdir="$(mktemp -d)"
git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
(cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
rm -rf "$tmpdir"

# 필요 AUR 패키지 설치
yay -S --needed --noconfirm clion clion-jre

# yay 캐시 정리 (빌드 디렉터리 + 다운로드된 소스)
yay -Sc --noconfirm
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/yay"

# xdg-user-dirs: 디렉터리 이름을 영어로 고정
LC_ALL=C.UTF-8 xdg-user-dirs-update --force
rm -rf ~/.local/share/user-places.xbel
rm -rf ~/바탕화면 ~/문서 ~/다운로드 ~/음악 ~/사진 ~/비디오 ~/공개 ~/템플릿 ~/프로젝트

# 환경변수 정의
sudo tee /etc/environment >/dev/null <<'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
QT4_IM_MODULE=fcitx
QT5_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF

# 필요 서비스 실행
sudo systemctl enable --now paccache.timer bluetooth.service fstrim.timer

# mitigation 끄기
grep -q 'mitigations=off' /etc/kernel/cmdline || \
  sudo sed -i '1s/$/ rw quiet mitigations=off/' /etc/kernel/cmdline

# chezmoi로 dotfiles 설정
chezmoi init --apply https://github.com/hanminsik/dotfiles_sway.git

# 재부팅
read -rp "설정 완료. 지금 재부팅할까요? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  sudo systemctl reboot
fi
