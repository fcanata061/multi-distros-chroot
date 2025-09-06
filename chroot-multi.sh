#!/bin/bash
# Script: chroot-multi.sh
# Orquestra Gentoo (host), Arch e Void em tmux com tema + status

set -e

# ============================
# CONFIGURAÇÃO
# ============================
VOID_ROOT=/mnt/void
ARCH_ROOT=/mnt/arch
DISPLAY_NUMBER=:0
XAUTH_FILE="$HOME/.Xauthority"

SESSION_NAME="multi"

# ============================
# FUNÇÕES
# ============================
bind_mounts() {
    local root="$1"
    echo "[*] Bind mounts para $root..."
    for dir in dev proc sys run; do
        sudo mount --bind /$dir "$root/$dir" || true
    done
    sudo mount --bind /dev/dri "$root/dev/dri" || true
    sudo mount --bind /dev/snd "$root/dev/snd" || true
    sudo mount --bind /tmp/.X11-unix "$root/tmp/.X11-unix" || true
}

setup_xauth() {
    local root="$1"
    echo "[*] Configurando xauth para $root..."
    sudo cp "$XAUTH_FILE" "$root/root/.Xauthority" || true
}

setup_tmux_conf() {
    echo "[*] Preparando tema do tmux em ~/.tmux.conf..."
    cat > ~/.tmux.conf <<'EOF'
# ============================
# THEME E ATALHOS DO TMUX
# ============================

# Prefixo
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Atalhos para splits
bind | split-window -h
bind - split-window -v
bind x kill-pane

# Atalhos para janelas
bind c new-window
bind & kill-window
bind n next-window
bind p previous-window

# Navegação entre splits com Ctrl + setas
bind -n C-Left select-pane -L
bind -n C-Right select-pane -R
bind -n C-Up select-pane -U
bind -n C-Down select-pane -D

# Atalhos diretos para sistemas
bind -n F1 select-window -t gentoo-1
bind -n F2 select-window -t arch-2
bind -n F3 select-window -t void-3

# Mouse
set -g mouse on

# Estilo das janelas
set -g status-interval 2
set -g status-justify centre
set -g status-bg black
set -g status-fg white

# Painel esquerdo: sessão e janela
set -g status-left-length 40
set -g status-left "#[fg=green]#S #[fg=cyan]#I:#W#[default] "

# Painel direito: métricas do sistema
set -g status-right-length 150
set -g status-right "#[fg=yellow]CPU: #(grep 'cpu ' /proc/stat | awk '{u=($2+$4)*100/($2+$4+$5)} END {printf \"%02.0f%%\", u}') \
#[fg=cyan]MEM: #(free -h | awk '/Mem:/ {print $3 \"/\" $2}') \
#[fg=red]TEMP: #(sensors 2>/dev/null | awk '/°C/ {print $2; exit}') \
#[fg=white]%H:%M %d-%m-%Y"

# Janela ativa destaque
set -g window-status-current-format "#[fg=black,bg=magenta] #I:#W #[default]"
EOF
}

start_tmux() {
    echo "[*] Iniciando sessão tmux com tema e janelas..."

    # Criar sessão com Gentoo (host)
    tmux new-session -d -s "$SESSION_NAME" -n gentoo-1 "bash"

    # Arch (chroot)
    tmux new-window -t "$SESSION_NAME":2 -n arch-2 \
        "sudo chroot $ARCH_ROOT /bin/bash -c 'export DISPLAY=$DISPLAY_NUMBER; export XAUTHORITY=/root/.Xauthority; exec bash'"

    # Void (chroot)
    tmux new-window -t "$SESSION_NAME":3 -n void-3 \
        "sudo chroot $VOID_ROOT /bin/bash -c 'export DISPLAY=$DISPLAY_NUMBER; export XAUTHORITY=/root/.Xauthority; exec bash'"

    # Ir para Gentoo na inicialização
    tmux select-window -t "$SESSION_NAME":1
    tmux attach -t "$SESSION_NAME"
}

# ============================
# EXECUÇÃO
# ============================
bind_mounts "$VOID_ROOT"
setup_xauth "$VOID_ROOT"

bind_mounts "$ARCH_ROOT"
setup_xauth "$ARCH_ROOT"

setup_tmux_conf
start_tmux
