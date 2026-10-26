#!/usr/bin/env bash
# Sensible macOS defaults, checked against macOS 26/27. Safe to re-run.
# Settings Apple removed (Dashboard, Launchpad, the App Store debug menus,
# Spotlight result ordering, font smoothing…) were dropped from this file.
#
# Find new keys: `defaults read > before`, change it in System Settings,
# `defaults read > after`, then `diff before after`.

set -uo pipefail
source "$(dirname "$0")/../lib/utils.sh"

# Stop System Settings from overwriting what we're about to change
osascript -e 'tell application "System Settings" to quit' 2>/dev/null

###############################################################################
# General UI/UX                                                               #
###############################################################################

title "General"

computer_name=$(prompt "Computer name" "$(scutil --get ComputerName)")
if [[ -n $computer_name && $computer_name != "$(scutil --get ComputerName)" ]]; then
  host_name=$(echo "$computer_name" | tr ' ' '-' | tr -cd '[:alnum:]-')
  sudo scutil --set ComputerName "$computer_name"
  sudo scutil --set LocalHostName "$host_name"
  sudo scutil --set HostName "$host_name"
  ok "Computer name set to $computer_name"
fi

# Mute the startup chime
sudo nvram StartupMute=%01

# Sidebar icon size: 1 small, 2 medium, 3 large
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1

# Automatic show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "Automatic"

# Expand save and print panels by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Don't reopen windows when apps relaunch
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Disable text "smartness" that breaks code: capitalization, smart dashes,
# double-space period, smart quotes and auto-correct
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool false

# Clicking the wallpaper shouldn't hide every window (Sonoma+ default)
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# No gaps around tiled windows
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

###############################################################################
# Keyboard, trackpad and input                                                #
###############################################################################

title "Keyboard & trackpad"

# Trackpad: tap to click, for this user and the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map bottom right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Blazingly fast key repeat (faster than System Settings allows; needs a re-login)
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Full keyboard access: Tab moves focus between all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# Languages and units
defaults write NSGlobalDomain AppleLanguages -array "en" "es"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true
defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"

# Free up ⌘Space for Raycast by disabling the Spotlight shortcut (64)
if [[ -d /Applications/Raycast.app ]]; then
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
    "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>"
  info "Spotlight's ⌘Space shortcut disabled; set it as Raycast's hotkey in its settings"
fi

###############################################################################
# Energy                                                                      #
###############################################################################

title "Energy"

# Wake when the lid opens
sudo pmset -a lidwake 1

# Restart automatically on power loss
sudo pmset -a autorestart 1

###############################################################################
# Screenshots                                                                 #
###############################################################################

title "Screenshots"

defaults write com.apple.screencapture location -string "$HOME/Desktop"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

title "Finder"

# Disable window and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# New Finder windows open the Desktop
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Desktop/"

# Show drives, servers and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Status bar, path bar, and full POSIX path in the window title
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name, in windows and on the desktop
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true

# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# No warning when changing a file extension or emptying the Trash
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Remove items from the Trash after 30 days
defaults write com.apple.finder FXRemoveOldTrashItems -bool true

# Spring-loaded folders, without the delay
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Open a new window when a volume is mounted
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# List view everywhere by default (other views: icnv, clmv, glyv)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show item info and snap to grid in icon views. On a fresh install these
# keys may not exist yet, so failures are ignored.
finder_plist="$HOME/Library/Preferences/com.apple.finder.plist"
for view in DesktopViewSettings FK_StandardViewSettings StandardViewSettings; do
  /usr/libexec/PlistBuddy -c "Set :$view:IconViewSettings:showItemInfo true" "$finder_plist" 2>/dev/null
  /usr/libexec/PlistBuddy -c "Set :$view:IconViewSettings:arrangeBy grid" "$finder_plist" 2>/dev/null
done
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:labelOnBottom false" "$finder_plist" 2>/dev/null

# Show ~/Library and /Volumes
chflags nohidden "$HOME/Library"
sudo chflags nohidden /Volumes

# Expand the General, Open with, and Sharing & Permissions info panes
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true

###############################################################################
# Dock, Mission Control and hot corners                                       #
###############################################################################

title "Dock"

defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Auto-hide the Dock, and show it instantly
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Remove all default app icons. Only offered once, since it wipes your Dock.
if ask "Clear all apps pinned to the Dock?" n; then
  defaults write com.apple.dock persistent-apps -array
fi

# Mission Control: fast animation, don't group by app, keep Spaces in order
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock expose-group-by-app -bool false
defaults write com.apple.dock mru-spaces -bool false

# Hot corners — 0: none, 2: Mission Control, 3: App windows, 4: Desktop,
# 5: Screen saver, 10: Display sleep, 12: Notification Center, 13: Lock screen,
# 14: Quick Note
# Bottom right → Desktop
defaults write com.apple.dock wvous-br-corner -int 4
defaults write com.apple.dock wvous-br-modifier -int 0

###############################################################################
# Apps                                                                        #
###############################################################################

title "Apps"

# Terminal: Secure Keyboard Entry, no line marks
defaults write com.apple.Terminal SecureKeyboardEntry -bool true
defaults write com.apple.Terminal ShowLineMarks -int 0

# Time Machine: don't offer new disks as backup volumes
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Activity Monitor: open main window, CPU in Dock icon, all processes, sort by CPU
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# TextEdit: plain text, UTF-8
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Disk Utility: show all devices
defaults write com.apple.DiskUtility SidebarShowAllDevices -bool true

# QuickTime: play videos on open
defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

# Photos: don't open when a device is plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

###############################################################################
# Software updates                                                            #
###############################################################################

title "Software updates"

# Check daily, download in the background, install security updates
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true

# Keep App Store apps up to date
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallAppUpdates -bool true

###############################################################################
# Apply                                                                       #
###############################################################################

# Apply keyboard shortcut changes without logging out
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null

for app in "Activity Monitor" "cfprefsd" "Dock" "Finder" "SystemUIServer"; do
  killall "$app" &>/dev/null
done
ok "macOS defaults applied. Some changes need a logout or restart."
