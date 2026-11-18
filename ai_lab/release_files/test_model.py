import sherpa_onnx

recognizer = sherpa_onnx.OfflineRecognizer.from_whisper(
    encoder="encoder.int8.onnx",
    decoder="decoder.int8.onnx",
    tokens="tokens.txt",
    language="ar",
)

stream = recognizer.create_stream()
stream.accept_wave_file("test_ayah.wav")
recognizer.decode_stream(stream)

print("Result:", stream.result.text)