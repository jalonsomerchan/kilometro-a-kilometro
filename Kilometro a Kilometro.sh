#!/bin/sh
printf '\033c\033]0;%s\a' Kilómetro a Kilómetro
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Kilometro a Kilometro.x86_64" "$@"
