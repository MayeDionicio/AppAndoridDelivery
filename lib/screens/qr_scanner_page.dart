import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../services/api_service.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final GlobalKey _cameraKey = GlobalKey();
  late ConfettiController _confettiController;

  bool _scanningEnabled = false;
  bool _scanned = false;
  bool _wasAttempted = false;
  bool _isLoading = false;
  IconData? _overlayIcon;
  Color? _overlayColor;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_scanningEnabled || _scanned || _isLoading) return;

    final code = capture.barcodes.first.rawValue;
    if (code != null) {
      _scanned = true;
      _wasAttempted = true;
      _isLoading = true;
      setState(() {});

      try {
        final mensaje = await ApiService.entregarPedidoConQR(code);

        _scanningEnabled = false;
        _isLoading = false;

        await _audioPlayer.play(AssetSource('sounds/beep.wav'));
        HapticFeedback.vibrate();
        _confettiController.play();

        _showOverlayIcon(Icons.check_circle, Colors.green);
        _showSnackBar("✅ $mensaje", success: true);
      } catch (e) {
        _isLoading = false;
        _scanned = false;
        HapticFeedback.vibrate();

        _showOverlayIcon(Icons.cancel, Colors.red);
        _showSnackBar("❌ ${e.toString()}", success: false);
      }

      setState(() {});
    }
  }

  void _showOverlayIcon(IconData icon, Color color) {
    setState(() {
      _overlayIcon = icon;
      _overlayColor = color;
    });
    _animationController.forward(from: 0);
  }

  void _showSnackBar(String mensaje, {required bool success}) {
    final color = success ? Colors.green : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _overlayIcon == Icons.check_circle;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Escanear QR')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: MobileScanner(
                      key: _cameraKey,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Positioned.fill(
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [Colors.green, Colors.blue, Colors.orange, Colors.purple],
                  ),
                ),
                if (_overlayIcon != null && !_isLoading)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      _overlayIcon,
                      color: _overlayColor,
                      size: 80,
                    ),
                  ),
                if (_isLoading)
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: Icon(
              isSuccess ? Icons.check : Icons.qr_code_scanner,
            ),
            label: Text(
              isSuccess ? "Entregado" : _wasAttempted ? "Reintentar" : "Escanear",
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: isSuccess ? Colors.green : Colors.blueAccent,
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: _isLoading
                ? null
                : () {
              HapticFeedback.lightImpact(); // ✅ vibración al presionar
              setState(() {
                _scanningEnabled = true;
                _scanned = false;
                _overlayIcon = null;
                _isLoading = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
