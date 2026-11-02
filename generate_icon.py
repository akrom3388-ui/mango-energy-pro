from PIL import Image, ImageDraw, ImageFont

def create_mango_icon():
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Dark Luxury Background (Rounded)
    draw.rounded_rectangle([16, 16, 496, 496], radius=110, fill=(15, 23, 42, 255), outline=(255, 140, 0, 255), width=12)
    
    # Mango / Flame Gradient Circle
    draw.ellipse([116, 116, 396, 396], fill=(255, 120, 0, 255))
    draw.ellipse([146, 146, 366, 366], fill=(255, 180, 0, 255))
    
    # Green Leaf at top right
    draw.polygon([(260, 110), (350, 70), (320, 150)], fill=(34, 197, 94, 255))
    
    # Center "M" Letter
    draw.line([(190, 310), (190, 200), (256, 265), (322, 200), (322, 310)], fill=(15, 23, 42, 255), width=28, joint="curve")
    
    img.save("mango_icon.png")
    print("✅ Mango ikonkasi yaratildi (mango_icon.png)")

if __name__ == "__main__":
    create_mango_icon()
