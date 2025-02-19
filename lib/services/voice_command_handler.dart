import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceCommandHandler {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> startListening(void Function(String command) handleCommand) async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      _isListening = true;
      _speech.listen(
        onResult: (result) {
          final command = result.recognizedWords.toLowerCase();
          print('Command detected: $command');
          _handleCommand(command);
        },
        partialResults: false, // Set to true for continuous updates
      );
    } else {
      print('Speech recognition unavailable.');
    }
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  void _handleCommand(String command) {
    if (command.contains("help") || command.contains("sos")) {
      _triggerSOS();
    } else if (command.contains("alert")) {
      _triggerAlert();
    }
  }

  void _triggerSOS() {
    print("SOS triggered!");
    // Logic for sending SOS (e.g., API call, notification)
  }

  void _triggerAlert() {
    print("Alert triggered!");
    // Logic for other alerts
  }
}
