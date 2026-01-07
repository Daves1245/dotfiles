#!/usr/bin/bash
sleep 5;
notify-send Starting Glances...
konsole --profile Glances --hide-menubar -e zsh -c 'source ~/.zshrc; tmuxinator glances'
notify-send Status: $?
