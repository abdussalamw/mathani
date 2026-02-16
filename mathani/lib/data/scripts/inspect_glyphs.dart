import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File('C:/Projects/New app/mathani/assets/data/qpc_v1_glyphs.json');
  final jsonString = await file.readAsString();
  final Map<String, dynamic> data = jsonDecode(jsonString);
  
  print('Total entries: ${data.length}');
  
  int count = 0;
  data.forEach((key, value) {
    if (count < 5) {
      print('Key: $key, Value: $value');
      count++;
    }
  });
}
