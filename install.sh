#!/bin/bash

cp -TRv .config/ ~/.config/
cp -TRv .local/ ~/.local/

tee -a ~/.bashrc >/dev/null <<'EOF'
####################
# Added by sway-wsl2
####################

# Set environment variables when running sway
if [[ $XDG_SESSION_DESKTOP == "sway" ]]; then
  # Default browser is "wslview"
  export BROWSER=firefox

  # Allows xdg-open to open programs within the VM, instead of windows
  export DE=generic

  # Allow VSCode to open within the VM instead of telling you to install it on windows
  export DONT_PROMPT_WSL_INSTALL=1

  # Uncomment to get kitty working. GTK_USE_PORTAL may break some other things so I left it disabled for now
  # Kitty is low resolution in WSL2 though for some reason? Would stick to xfce4-terminal or another terminal emulator
  # export GTK_USE_PORTAL=1
  # export LIBGL_ALWAYS_INDIRECT=0
  # export GALLIUM_DRIVER=llvmpipe
fi

EOF

if [[ $PATH != *"$HOME/.local/bin"* ]]; then
  echo "Adding \$HOME/.local/bin to PATH via ~/.bashrc. Restart your shell or run source ~/.bashrc to refresh"

  tee -a ~/.bashrc >/dev/null <<-'EOF'
	if [[ -d $HOME/.local/bin ]]; then
	  export PATH=$HOME/.local/bin:$PATH
	fi

EOF
fi
