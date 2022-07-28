#!/usr/bin/env bash
rm ./gamemode/gamemode_client.h
wget --output-document ./gamemode/gamemode_client.h "https://github.com/FeralInteractive/gamemode/raw/master/lib/gamemode_client.h"

# The output from translate-c isn't perfect, so we need this fix
zig translate-c ./gamemode/gamemode_client.h -lc | sed "s#functor\(.*\)@alignCast\(.*\),\(.*\))#functor\1\3#" > ./gamemode_client.zig
