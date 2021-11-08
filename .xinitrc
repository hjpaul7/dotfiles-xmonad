#!/bin/sh

[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap && xrdb -load ~/.Xresources
exec xmonad
