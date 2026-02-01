# Script to generate pubspec.yaml font entries for QCF4 fonts

print("Generating pubspec.yaml font entries...")

# Generate font entries for all 604 pages
font_entries = []

# Add Basmala font first
font_entries.append("""  - family: QCF4_BSML
    fonts:
      - asset: assets/fonts/qcf4/QCF4_BSML.woff""")

# Add all page fonts (001-604)
for i in range(1, 605):
    page_num = str(i).zfill(3)
    font_entry = f"""  - family: QCF4_{page_num}
    fonts:
      - asset: assets/fonts/qcf4/QCF4_{page_num}.woff"""
    font_entries.append(font_entry)

# Write to file
output = "\n".join(font_entries)

with open('qcf4_fonts_pubspec.txt', 'w', encoding='utf-8') as f:
    f.write(output)

print(f"Generated {len(font_entries)} font entries")
print("Saved to: qcf4_fonts_pubspec.txt")
print("\nFirst 5 entries:")
print("\n".join(font_entries[:5]))
