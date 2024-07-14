# Sway WSL2
Sway Wayland compositor, running in WSL2 via Microsoft's [WSLg](https://github.com/microsoft/wslg). This is dedicated to all the people out there who are stuck using Windows for work

## Working
* Multiple monitors
* Shared clipboard
* Audio

## Not Working
* ?

## To Install Manually

Assuming sway is already installed (I use [this](https://github.com/EndeavourOS-Community-Editions/sway))
``` shell
git clone https://github.com/jordankoehn/sway-wsl2.git
cd sway-wsl2
./install.sh
```

## Post install

* Start sway by running `start-sway`
* See [~/.config/sway/config.d/wsl](./.config/sway/config.d/wsl)
  * Here you can set the number of displays you want to spawn and assign workspaces to specific displays

## Resize/Move WSL2 Sway Windows

* `win + up` will maximize a window
* `win + shift + left/right` to to move a window to another monitors
* Window not filling the screen correctly? First do `win + left/right` to snap it to half the screen, then `win + up` to maximize the window. It should now fill the screen correctly

## Super Key

| Mod | Key |
| --- | --- |
| Mod1 | Alt |
| Mod3 | Num Lock |
| Mod4 | Windows/Super key |

By default, Sway defaults to the windows key as the super key. This is problematic when running within windows. One option would be to change Sway from `mod4` to `mod1` (alt). Some programs which use alt in Linux collide with this. My solution, is to set your super key to Mod3 (num lock). Then, using [powertoys](https://learn.microsoft.com/en-us/windows/powertoys/keyboard-manager
) I remap my Windows key to num lock, and right control to windows key. Very few windows functions, like `win + d` will not recognize the remap. However, for general use this works perfectly. Alternatively, if your keyboard supports hardware remapping you could also go that route

## Additional Tips

* To maximize the Window beyond the windows status bar, you can set Windows to automatically hide the taskbar
  * Alternatively, set your primary Windows display to your least important monitor, and only show the taskbar on your primary monitor. Use that monitor for chat applications and other Window stuff. Use your remaining monitors for Sway via WSL2
* If you're no longer primarily using Windows, consider [allocating more memory to WSL2](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#main-wsl-settings), this defaults to 50% of system ram

## Known Issues

* Kitty terminal looks very low resolution. Uncomment some lines in ~/.bashrc if you'd like to try using kitty. I've had good luck with xfce4-terminal. All other programs render as they should
* Expect the UI to crash if you put your PC to sleep, have network changes, if you change the windows taskbar setting to auto hide while Sway is running, or just at random. YMMV, I generally go most days without any crashes
