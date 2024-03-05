ls zig-out/spirv/ | while read -r file
do
  spirv-val zig-out/spirv/$file
done