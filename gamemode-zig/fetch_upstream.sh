#!/usr/bin/env bash
rm ./gamemode_client.h
wget "https://github.com/FeralInteractive/gamemode/raw/master/lib/gamemode_client.h"

# The output from translate-c isn't perfect, so we need this fix
zig translate-c ./gamemode_client.h -lc | sed "s#functor\(.*\)@alignCast\(.*\),\(.*\))#functor\1\3#" > ./gamemode_client.zig
