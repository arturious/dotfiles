#!/usr/bin/env bash
# macOS settings. Run: bash ~/dotfiles/macos/defaults.sh

defaults write -g NSConvolutionOverride1 -float 12
defaults write -g NSSplitViewItemSidebarDefaultsToFloatingAppearance -bool false
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain "NSTableViewDefaultSizeMode" -int "2"
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerDrag" -bool "true"
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.dock scroll-to-open -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write -g NSWindowShouldDragOnGesture -bool true
defaults write com.apple.finder WarnOnEmptyTrash -bool false

killall Finder Dock