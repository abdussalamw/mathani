import os
import glob
from PIL import Image

def optimize_images():
    source_dir = r"C:\Projects\sorse\الشمرلي ـ صور\quran_images_shamrly\quran_images_shamrly"
    target_dir = r"C:\Projects\sorse\الشمرلي ـ صور\quran_images_shamrly_compressed"
    
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)
        
    png_files = glob.glob(os.path.join(source_dir, "*.png"))
    
    total_original_size = 0
    total_compressed_size = 0
    
    print(f"Found {len(png_files)} PNG files. Starting compression...")
    
    for i, file in enumerate(png_files):
        filename = os.path.basename(file)
        # Change extension to webp
        webp_filename = os.path.splitext(filename)[0] + ".webp"
        target_path = os.path.join(target_dir, webp_filename)
        
        orig_size = os.path.getsize(file)
        total_original_size += orig_size
        
        try:
            with Image.open(file) as img:
                # WebP lossless is often very good for text/line art
                # If we use lossy, quality=85 is a safe bet for high-quality text
                img.save(target_path, "WEBP", quality=85, method=6, lossless=False)
            
            comp_size = os.path.getsize(target_path)
            total_compressed_size += comp_size
            
            if i % 50 == 0:
                print(f"Processed {i}/{len(png_files)} files...")
                
        except Exception as e:
            print(f"Error processing {filename}: {e}")
            
    print(f"Done! Original size: {total_original_size / 1024 / 1024:.2f} MB")
    print(f"Compressed size: {total_compressed_size / 1024 / 1024:.2f} MB")
    print(f"Saved to: {target_dir}")

if __name__ == "__main__":
    optimize_images()
