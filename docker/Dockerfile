FROM archlinux:latest AS base

# ---- build args (passed from compose) ----
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000
ARG DOTFILES=https://github.com/JamesCMorey/dotfiles.git

# ---- base system ----
RUN pacman-key --init && pacman-key --populate archlinux
RUN pacman -Syu --noconfirm \
    base-devel \
    bash-completion \
    git \
    neovim \
    tmux \
    curl \
    wget \
    ripgrep \
    fd \
    sudo \
    stow \
    tree-sitter-cli \
    openssh \
    man-db \
    man-pages \
    # Codex
    npm \
    bubblewrap \
    && pacman -Scc --noconfirm

# ---- create group + user matching host ----
RUN groupadd -g ${GID} ${USERNAME} \
    && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}

# ---- passwordless sudo (optional, dev only) ----
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


# ---- default user ----
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install Claude & Codex
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN sudo npm install -g @openai/codex

FROM base AS dotfiles
# ---- install dotfiles ----
RUN git clone ${DOTFILES} /home/${USERNAME}/dotfiles
RUN mv .bashrc .bashrc_old
RUN cd dotfiles && stow --dotfiles default git

# Install/update lazy-managed plugins, then run again so plugin
# configs fire (treesitter parser install needs the plugin loaded).
RUN nvim --headless "+Lazy! sync" +qa \
    && nvim --headless +qa

# ---- default shell ----
CMD ["/bin/bash"]
