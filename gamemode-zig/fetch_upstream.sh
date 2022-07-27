#!/usr/bin/env bash

rm ./c/*
cd ./c
wget "https://github.com/FeralInteractive/gamemode/raw/master/lib/gamemode_client.h"
wget "https://github.com/FeralInteractive/gamemode/raw/master/lib/client_impl.c"
wget "https://github.com/FeralInteractive/gamemode/raw/master/lib/client_loader.c"

cd ./common
wget "https://github.com/FeralInteractive/gamemode/raw/b11d2912e280acb87d9ad114d6c7cd8846c4ef02/common/common-helpers.c"
wget "https://github.com/FeralInteractive/gamemode/raw/b11d2912e280acb87d9ad114d6c7cd8846c4ef02/common/common-pidfds.c"
wget "https://github.com/FeralInteractive/gamemode/raw/b11d2912e280acb87d9ad114d6c7cd8846c4ef02/common/common-helpers.h"
wget "https://github.com/FeralInteractive/gamemode/raw/b11d2912e280acb87d9ad114d6c7cd8846c4ef02/common/common-pidfds.h"

cd ../..

# The output from translate-c isn't perfect, so we need this fix
zig translate-c ./c/gamemode_client.h -lc | sed "s#functor\(.*\)@alignCast\(.*\),\(.*\))#functor\1\3#" > ./src/gamemode_client.zig

rm -r ./zig-cache
