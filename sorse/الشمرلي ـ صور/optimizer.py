import os
from PIL import Image
import concurrent.futures
from tqdm import tqdm
import time

class MushafOptimizer:
    def __init__(self):
        self.settings = {
            'quality': 85,          # جودة WebP (0-100)
            'max_width': 1200,      # مناسب للشاشات
            'format': 'webp',       # webp أو jpg
            'preserve_transparency': True,
            'method': 6,            # طريقة ضغط WebP (0-6)
            'threads': 4            # عدد العمليات المتوازية
        }
        
        # إحصائيات
        self.stats = {
            'total_images': 0,
            'successful': 0,
            'failed': 0,
            'original_size': 0,
            'optimized_size': 0,
            'time_taken': 0
        }
    
    def format_size(self, size_bytes):
        """تنسيق حجم الملف"""
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.1f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.1f} TB"
    
    def get_image_info(self, img_path):
        """الحصول على معلومات الصورة"""
        try:
            with Image.open(img_path) as img:
                return {
                    'width': img.width,
                    'height': img.height,
                    'mode': img.mode,
                    'format': img.format,
                    'size': os.path.getsize(img_path)
                }
        except:
            return None
    
    def optimize_single_image(self, file_info):
        """تحسين صورة واحدة"""
        input_path, output_path, page_num = file_info
        
        try:
            # فتح الصورة الأصلية
            with Image.open(input_path) as img:
                # حفظ المعلومات الأصلية
                orig_size = os.path.getsize(input_path)
                
                # تحويل RGBA إذا كانت شفافة
                if img.mode in ('RGBA', 'LA') and self.settings['preserve_transparency']:
                    img = img.convert('RGBA')
                elif img.mode == 'P':
                    img = img.convert('RGB')
                elif img.mode != 'RGB':
                    img = img.convert('RGB')
                
                # تغيير الحجم إذا كان أكبر من المطلوب
                if img.width > self.settings['max_width']:
                    ratio = self.settings['max_width'] / img.width
                    new_height = int(img.height * ratio)
                    
                    # استخدام أفضل خوارزمية إعادة الحجم
                    if self.settings['format'] == 'webp':
                        img = img.resize((self.settings['max_width'], new_height), 
                                       Image.Resampling.LANCZOS)
                    else:
                        img = img.resize((self.settings['max_width'], new_height), 
                                       Image.Resampling.BICUBIC)
                
                # إعدادات الحفظ
                save_kwargs = {
                    'quality': self.settings['quality'],
                    'optimize': True
                }
                
                # إعدادات إضافية لـ WebP
                if self.settings['format'].lower() == 'webp':
                    save_kwargs.update({
                        'method': self.settings['method'],
                        'lossless': False
                    })
                
                # حفظ الصورة
                img.save(output_path, self.settings['format'].upper(), **save_kwargs)
                
                # حساب التوفير
                new_size = os.path.getsize(output_path)
                savings = ((orig_size - new_size) / orig_size) * 100
                
                return {
                    'success': True,
                    'page': page_num,
                    'original': self.format_size(orig_size),
                    'optimized': self.format_size(new_size),
                    'savings': f"{savings:.1f}%",
                    'original_size': orig_size,
                    'optimized_size': new_size
                }
                
        except Exception as e:
            return {
                'success': False,
                'page': page_num,
                'error': str(e)
            }
    
    def prepare_file_list(self, source_dir, output_dir):
        """تحضير قائمة الملفات"""
        os.makedirs(output_dir, exist_ok=True)
        
        # البحث عن جميع الصور المدعومة
        extensions = ('.png', '.jpg', '.jpeg', '.webp', '.bmp', '.tiff')
        files = [f for f in os.listdir(source_dir) 
                if f.lower().endswith(extensions)]
        
        # ترتيب الملفات حسب الرقم
        def extract_number(filename):
            try:
                return int(''.join(filter(str.isdigit, filename)))
            except:
                return float('inf')  # وضع الملفات بدون أرقام في النهاية
        
        files.sort(key=extract_number)
        
        # إعداد قائمة المهام
        file_list = []
        for filename in files:
            try:
                # استخراج رقم الصفحة
                numbers = ''.join(filter(str.isdigit, filename))
                page_num = int(numbers) if numbers else 0
                
                # إنشاء أسماء الملفات
                input_path = os.path.join(source_dir, filename)
                output_filename = f"{page_num:03d}.{self.settings['format']}"
                output_path = os.path.join(output_dir, output_filename)
                
                file_list.append((input_path, output_path, page_num))
                
            except Exception as e:
                print(f"⚠️ خطأ في معالجة {filename}: {e}")
        
        return file_list
    
    def optimize_batch(self, source_dir="raw_images", output_dir="optimized_mushaf"):
        """تحسين مجموعة الصور"""
        start_time = time.time()
        
        print("🔄 جاري تحضير الملفات...")
        file_list = self.prepare_file_list(source_dir, output_dir)
        self.stats['total_images'] = len(file_list)
        
        if not file_list:
            print("❌ لم يتم العثور على صور في المجلد المحدد")
            return False
        
        print(f"📊 العدد الإجمالي للصور: {self.stats['total_images']}")
        
        # استخدام المعالجة المتوازية
        results = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.settings['threads']) as executor:
            future_to_file = {executor.submit(self.optimize_single_image, f): f for f in file_list}
            
            # متابعة التقدم
            with tqdm(total=len(file_list), desc="🎨 جاري تحسين الصور") as pbar:
                for future in concurrent.futures.as_completed(future_to_file):
                    result = future.result()
                    results.append(result)
                    pbar.update(1)
        
        # معالجة النتائج
        print("\n" + "="*50)
        print("📈 نتائج التحسين:")
        print("="*50)
        
        for result in results:
            if result['success']:
                self.stats['successful'] += 1
                self.stats['original_size'] += result['original_size']
                self.stats['optimized_size'] += result['optimized_size']
                
                print(f"✅ صفحة {result['page']:03d}: {result['original']} → {result['optimized']} "
                      f"(توفير: {result['savings']})")
            else:
                self.stats['failed'] += 1
                print(f"❌ صفحة {result['page']:03d}: فشل - {result['error']}")
        
        # عرض الإحصائيات
        self.stats['time_taken'] = time.time() - start_time
        
        print("\n" + "="*50)
        print("📊 ملخص الإحصائيات:")
        print("="*50)
        print(f"الصور المعالجة بنجاح: {self.stats['successful']}/{self.stats['total_images']}")
        print(f"الصور الفاشلة: {self.stats['failed']}")
        print(f"الحجم الأصلي الإجمالي: {self.format_size(self.stats['original_size'])}")
        print(f"الحجم بعد التحسين: {self.format_size(self.stats['optimized_size'])}")
        
        if self.stats['original_size'] > 0:
            total_savings = ((self.stats['original_size'] - self.stats['optimized_size']) / 
                           self.stats['original_size']) * 100
            print(f"نسبة التوفير الإجمالية: {total_savings:.1f}%")
        
        print(f"الوقت المستغرق: {self.stats['time_taken']:.2f} ثانية")
        print(f"المجلد الناتج: {os.path.abspath(output_dir)}")
        print("="*50)
        
        # حفظ الإحصائيات في ملف
        stats_file = os.path.join(output_dir, "optimization_stats.txt")
        with open(stats_file, 'w', encoding='utf-8') as f:
            f.write("إحصائيات تحسين صور المصحف\n")
            f.write(f"تاريخ المعالجة: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"الصور الناجحة: {self.stats['successful']}\n")
            f.write(f"الصور الفاشلة: {self.stats['failed']}\n")
            f.write(f"الحجم الأصلي: {self.format_size(self.stats['original_size'])}\n")
            f.write(f"الحجم الجديد: {self.format_size(self.stats['optimized_size'])}\n")
        
        return True

# الدالة الرئيسية
def main():
    print("🕌 محسن صور المصحف")
    print("="*50)
    
    optimizer = MushafOptimizer()
    
    # يمكنك تعديل الإعدادات هنا
    optimizer.settings.update({
        'quality': 85,
        'max_width': 1200,
        'format': 'webp',
        'threads': 4
    })
    
    # طلب تأكيد الإعدادات
    print("⚙️ الإعدادات الحالية:")
    for key, value in optimizer.settings.items():
        print(f"  {key}: {value}")
    
    print("\n" + "="*50)
    
    # تشغيل التحسين
    try:
        optimizer.optimize_batch(
            source_dir="raw_images",
            output_dir="optimized_mushaf"
        )
        
        print("\n🎉 تم التحسين بنجاح!")
        print("📁 الصور المحسنة جاهزة في مجلد 'optimized_mushaf'")
        
    except Exception as e:
        print(f"❌ حدث خطأ: {e}")

if __name__ == "__main__":
    main()