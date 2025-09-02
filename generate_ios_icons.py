import os
from PIL import Image

# iOS AppIcon 所有尺寸及命名
icon_specs = [
    (20, 1, 'icon_20pt@1x.png'),
    (20, 2, 'icon_20pt@2x.png'),
    (20, 3, 'icon_20pt@3x.png'),
    (29, 1, 'icon_29pt@1x.png'),
    (29, 2, 'icon_29pt@2x.png'),
    (29, 3, 'icon_29pt@3x.png'),
    (40, 1, 'icon_40pt@1x.png'),
    (40, 2, 'icon_40pt@2x.png'),
    (40, 3, 'icon_40pt@3x.png'),
    (60, 2, 'icon_60pt@2x.png'),
    (60, 3, 'icon_60pt@3x.png'),
    (76, 1, 'icon_76pt@1x.png'),
    (76, 2, 'icon_76pt@2x.png'),
    (83.5, 2, 'icon_83.5pt@2x.png'),
    (1024, 1, 'icon_1024pt@1x.png'),
]

def generate_icons(src_path, out_dir):
    if not os.path.exists(src_path):
        print(f"源图片不存在: {src_path}")
        return
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    img = Image.open(src_path).convert('RGBA')
    for size, scale, filename in icon_specs:
        px = int(round(size * scale))
        icon = img.resize((px, px), Image.LANCZOS)
        out_path = os.path.join(out_dir, filename)
        icon.save(out_path, format='PNG')
        print(f"生成: {out_path} ({px}x{px})")

if __name__ == '__main__':
    src = '3.png'
    out = 'Assets.xcassets/AppIcon.appiconset/'
    generate_icons(src, out) 