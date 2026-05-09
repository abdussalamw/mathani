import 'dart:convert';
import 'package:flutter/services.dart';
import '../../data/models/reciter.dart';

abstract class ReciterRepository {
  Future<List<Reciter>> getReciters();
}

class ReciterRepositoryImpl implements ReciterRepository {
  List<Reciter>? _cache;

  @override
  Future<List<Reciter>> getReciters() async {
    if (_cache != null) return _cache!;

    try {
      final jsonString = await rootBundle.loadString('assets/data/reciters.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _cache = jsonList.map((json) => Reciter.fromJson(json)).toList();
      return _cache!;
    } catch (e) {
      // Fallback in case of error
      return [
         Reciter(id: 'Minshawy_Murattal_128kbps', name: 'محمد صديق المنشاوي', style: 'Murattal', bitrate: '128kbps'),
      ];
    }
  }
}
