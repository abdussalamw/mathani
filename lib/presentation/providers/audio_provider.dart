import 'package:flutter/material.dart';

class AudioProvider extends ChangeNotifier {
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // Placeholder logic
  void play() {
    _isPlaying = true;
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }
}
