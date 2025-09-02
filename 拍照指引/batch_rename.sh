#!/bin/bash
# 遍历当前目录下的所有文件夹
for dir in */; do
  # 去掉末尾的/
  folder_name="${dir%/}"
  # 跳过隐藏文件夹
  [[ "$folder_name" == .* ]] && continue
  # 只处理文件夹
  [ -d "$folder_name" ] || continue
  # 计数器
  i=1
  # 只重命名图片文件（jpg/jpeg/png/JPG/JPEG/PNG）
  for file in "$folder_name"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
    # 跳过不存在的情况
    [ -e "$file" ] || continue
    ext="${file##*.}"
    mv -i "$file" "$folder_name/$folder_name$i.$ext"
    ((i++))
  done
done
