#!/bin/bash

# Check if both arguments are provided
if [[ "$#" -lt 1 ]]; then
    echo "Usage: $0 <WindowTitleFilter> <MonitorIndex>"
    echo "Example: $0 WL-1 1"
    exit 1
fi

TARGET_TITLE=$1
MONITOR_INDEX=${2:-0}

# We pass the title via an Environment Variable to PowerShell.
# This completely avoids breaking nested single/double quotes in Bash.
# https://stackoverflow.com/a/70010344
/mnt/c/windows/System32/WindowsPowerShell/v1.0/powershell.exe -noprofile -command '
Add-Type -AssemblyName System.Windows.Forms

# --- CONFIGURATIONS ---
$WindowTitleFilter = "'$TARGET_TITLE'"   # Supports wildcards
$MonitorIndex = "'$MONITOR_INDEX'"       # 0 is Primary, 1 is Secondary, etc.

Write-Host "WindowTitleFilter $WindowTitleFilter"
Write-Host "MonitorIndex $MonitorIndex"
# ----------------------

# 1. Get the target monitor bounds
$Monitors = [System.Windows.Forms.Screen]::AllScreens
if ($MonitorIndex -ge $Monitors.Count) {
    Write-Error "Monitor index out of bounds. You only have $($Monitors.Count) monitor(s) active."
    exit
}

$TargetScreen = $Monitors[$MonitorIndex]
$NewX = $TargetScreen.Bounds.X
$NewY = $TargetScreen.Bounds.Y

# 2. Get Window Handle
$TargetProcess = Get-Process | Where-Object { $_.MainWindowTitle -like "*$WindowTitleFilter*" } | Select-Object -First 1
if ($TargetProcess) {
    $hWnd = $TargetProcess.MainWindowHandle
} else {
    Write-Warning "Process with window matching $WindowTitleFilter not found."
    exit
}

if ($hWnd -ne [IntPtr]::Zero) {
    Write-Host "Target window found." -ForegroundColor Cyan
} else {
    Write-Warning "Process with window matching $WindowTitleFilter is running, but no main window handle was found. (Is it minimized to the system tray?)"
    exit
}

# 3. Define SetWindowPos from user32.dll
# SWP_NOSIZE (0x0001) tells Windows to ignore the width (cx) and height (cy) arguments.
# SWP_NOZORDER (0x0004) retains the windows current place in the stack (doesnt force it to the front).
$Signature = @"
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
"@

$User32 = Add-Type -MemberDefinition $Signature -Name "User32Position" -Namespace "Win32" -PassThru

$WindowAPI = @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class WindowManager {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    // Virtual Key Codes
    private const byte VK_LWIN = 0x5B;   // Left Windows Key
    private const byte VK_RIGHT = 0x27;  // Right Arrow
    private const byte VK_UP = 0x26;     // Up Arrow
    private const uint KEYEVENTF_KEYUP = 0x0002;
    private const int SW_MAXIMIZE = 3;

    public static void SnapRight(IntPtr hWnd) {
        // 1. Bring the borderless window to the foreground
        SetForegroundWindow(hWnd);
        Thread.Sleep(400); // Give Windows time to switch focus

        // 2. Simulate Win + Right Arrow (Snap Right)
        keybd_event(VK_LWIN, 0, 0, 0);
        keybd_event(VK_RIGHT, 0, 0, 0);
        Thread.Sleep(100);
        keybd_event(VK_RIGHT, 0, KEYEVENTF_KEYUP, 0);
        keybd_event(VK_LWIN, 0, KEYEVENTF_KEYUP, 0);

        Thread.Sleep(400); // Give Windows time to switch focus
    }

    public static void Maximize(IntPtr hWnd) {
        SetForegroundWindow(hWnd);
        Thread.Sleep(400); // Give Windows time to switch focus
        ShowWindow(hWnd, SW_MAXIMIZE);
    }
}
"@

# Load the Win32 API functions into the session
Add-Type -TypeDefinition $WindowAPI

# Flags: SWP_NOSIZE (0x0001) | SWP_NOZORDER (0x0004) = 0x0005
$Flags = 0x0001 -bor 0x0004

Write-Host "Moving the window to the desired monitor..." -ForegroundColor Cyan
# 4. Execute the move (Passing 0 for width and height since SWP_NOSIZE is active)
$Success = [Win32.User32Position]::SetWindowPos($hWnd, [IntPtr]::Zero, $NewX, $NewY, 0, 0, $Flags)

if (-not $Success) {
    Write-Error "Failed to move the window."
}

Write-Host "Executing Win+Right to snap window to the right side of the screen..." -ForegroundColor Cyan
# Ensure not overflowing into another monitor prior to maximize
[WindowManager]::SnapRight($hWnd)
[WindowManager]::Maximize($hWnd)'

