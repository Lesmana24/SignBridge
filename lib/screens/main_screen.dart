import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════
// DESIGN TOKENS — from DESIGN.md
// ═══════════════════════════════════════════════════════════════════

class _C {
  _C._();
  static const Color background = Color(0xFF0A192F); // Deep Navy
  static const Color surfaceLevel1 = Color(0xFF112240); // Navy Blue (cards)
  static const Color surfaceLevel2 = Color(0xFF1C2F4D); // Overlay
  static const Color primary = Color(0xFFFFD700); // Bright Yellow
  static const Color onPrimary = Color(0xFF0A192F); // Text on primary
  static const Color onSurface = Color(0xFFFFFFFF); // Snow White
  static const Color onSurfaceDim = Color(0x99FFFFFF); // 60% white
  static const Color outline10 = Color(0x1AFFFFFF); // 10% white border
}

class _T {
  _T._();
  static TextStyle _base([double size = 16, FontWeight w = FontWeight.w400]) =>
      GoogleFonts.atkinsonHyperlegibleNext(fontSize: size, fontWeight: w);

  static TextStyle headlineMd = _base(24, FontWeight.w700);
  static TextStyle bodyMd = _base(18, FontWeight.w400);
  static TextStyle labelLg = _base(
    16,
    FontWeight.w700,
  ).copyWith(letterSpacing: 0.32);
  static TextStyle translationDisplay = _base(40, FontWeight.w800);
}

// ═══════════════════════════════════════════════════════════════════
// IMAGE UTILS (Efficient YUV to Float32)
// ═══════════════════════════════════════════════════════════════════

class ImageUtils {
  static Float32List convertYUV420ToFloat32(
    int width,
    int height,
    Uint8List plane0,
    Uint8List plane1,
    Uint8List plane2,
    int rowStride0,
    int rowStride1,
    int pixelStride1,
    int rowStride2,
    int pixelStride2,
    int sensorOrientation,
    bool isFrontCamera,
  ) {
    const int targetSize = 224;
    final Float32List buffer = Float32List(1 * targetSize * targetSize * 3);
    int bufferIndex = 0;

    // Center Crop calculation
    final int cropSize = width < height ? width : height;
    final int cropX = (width - cropSize) ~/ 2;
    final int cropY = (height - cropSize) ~/ 2;

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        // 1. Un-mirror horizontally if front camera (AI tensor is mirrored like a webcam)
        int unmirroredX = isFrontCamera ? (targetSize - 1 - x) : x;
        int unmirroredY = y;

        // 2. Un-rotate to map back to the sensor's raw orientation
        int sx = unmirroredX;
        int sy = unmirroredY;

        if (sensorOrientation == 90) {
          // Sensor was rotated 90 CW. We rotate 90 CCW to map back.
          sx = unmirroredY;
          sy = targetSize - 1 - unmirroredX;
        } else if (sensorOrientation == 270) {
          // Sensor was rotated 270 CW (90 CCW). We rotate 90 CW to map back.
          sx = targetSize - 1 - unmirroredY;
          sy = unmirroredX;
        } else if (sensorOrientation == 180) {
          sx = targetSize - 1 - unmirroredX;
          sy = targetSize - 1 - unmirroredY;
        }

        // 3. Map to center-cropped bounds
        final int origX = (cropX + (sx * cropSize) / targetSize).floor().clamp(
          0,
          width - 1,
        );
        final int origY = (cropY + (sy * cropSize) / targetSize).floor().clamp(
          0,
          height - 1,
        );

        // 4. Retrieve YUV values using explicit strides for both U and V planes
        final int yIndex = origY * rowStride0 + origX;
        final int uIndex =
            (origY ~/ 2) * rowStride1 + (origX ~/ 2) * pixelStride1;
        final int vIndex =
            (origY ~/ 2) * rowStride2 + (origX ~/ 2) * pixelStride2;

        final int yp = plane0[yIndex];
        final int up = plane1[uIndex];
        final int vp = plane2[vIndex];

        // 5. Standard NV21 / YUV420 to RGB conversion
        final int u = up - 128;
        final int v = vp - 128;

        final int r = (yp + 1.402 * v).round().clamp(0, 255);
        final int g = (yp - 0.344136 * u - 0.714136 * v).round().clamp(0, 255);
        final int b = (yp + 1.772 * u).round().clamp(0, 255);

        // 6. Normalize [-1.0, 1.0] for Teachable Machine Float32
        buffer[bufferIndex++] = (r - 127.5) / 127.5;
        buffer[bufferIndex++] = (g - 127.5) / 127.5;
        buffer[bufferIndex++] = (b - 127.5) / 127.5;
      }
    }
    return buffer;
  }

  static Float32List convertBGRA8888ToFloat32(
    int width,
    int height,
    Uint8List plane0,
    int rowStride0,
    int sensorOrientation,
    bool isFrontCamera,
  ) {
    const int targetSize = 224;
    final Float32List buffer = Float32List(1 * targetSize * targetSize * 3);
    int bufferIndex = 0;

    final int cropSize = width < height ? width : height;
    final int cropX = (width - cropSize) ~/ 2;
    final int cropY = (height - cropSize) ~/ 2;

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final int outX = isFrontCamera ? (targetSize - 1 - x) : x;
        int sx = outX;
        int sy = y;

        if (sensorOrientation == 90) {
          sx = y;
          sy = targetSize - 1 - outX;
        } else if (sensorOrientation == 270) {
          sx = targetSize - 1 - y;
          sy = outX;
        } else if (sensorOrientation == 180) {
          sx = targetSize - 1 - outX;
          sy = targetSize - 1 - y;
        }

        final int origX = (cropX + (sx * cropSize) / targetSize).floor().clamp(
          0,
          width - 1,
        );
        final int origY = (cropY + (sy * cropSize) / targetSize).floor().clamp(
          0,
          height - 1,
        );

        final int index = origY * rowStride0 + origX * 4;
        final int bPx = plane0[index];
        final int gPx = plane0[index + 1];
        final int rPx = plane0[index + 2];

        buffer[bufferIndex++] = (rPx - 127.5) / 127.5;
        buffer[bufferIndex++] = (gPx - 127.5) / 127.5;
        buffer[bufferIndex++] = (bPx - 127.5) / 127.5;
      }
    }
    return buffer;
  }
}

// ═══════════════════════════════════════════════════════════════════
// BACKGROUND ISOLATE INFERENCE
// ═══════════════════════════════════════════════════════════════════

class InferenceWorker {
  SendPort? _sendPort;
  Isolate? _isolate;
  final ReceivePort _receivePort = ReceivePort();
  Completer<Map<String, dynamic>>? _completer;
  Completer<void>? _initCompleter;

  Future<void> init(Uint8List modelBytes, List<String> labels) async {
    _initCompleter = Completer<void>();

    // Zero-copy transfer to prevent 10MB GC allocation on Main Thread
    final transferableModel = TransferableTypedData.fromList([modelBytes]);

    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _sendPort!.send({
          'type': 'init',
          'modelBytes': transferableModel,
          'labels': labels,
        });
      } else if (message is Map) {
        if (message['type'] == 'ready') {
          _initCompleter?.complete();
          _initCompleter = null;
        } else if (message['type'] == 'result') {
          _completer?.complete(message as Map<String, dynamic>);
          _completer = null;
        }
      }
    });

    _isolate = await Isolate.spawn(_isolateEntry, _receivePort.sendPort);
    return _initCompleter!.future;
  }

  Future<Map<String, dynamic>> infer(Map<String, dynamic> params) {
    _completer = Completer<Map<String, dynamic>>();
    params['type'] = 'infer';
    _sendPort?.send(params);
    return _completer!.future;
  }

  void dispose() {
    _isolate?.kill();
    _receivePort.close();
  }
}

void _isolateEntry(SendPort mainSendPort) {
  final isolateReceivePort = ReceivePort();
  mainSendPort.send(isolateReceivePort.sendPort);

  Interpreter? interpreter;
  List<String>? labels;

  isolateReceivePort.listen((message) {
    if (message is Map) {
      if (message['type'] == 'init') {
        TransferableTypedData transferableModel = message['modelBytes'];
        Uint8List modelBytes = transferableModel.materialize().asUint8List();

        labels = message['labels'];
        interpreter = Interpreter.fromBuffer(modelBytes);
        mainSendPort.send({'type': 'ready'});
      } else if (message['type'] == 'infer' && interpreter != null) {
        int width = message['width'];
        int height = message['height'];
        bool isYUV = message['isYUV'];
        Uint8List plane0 = message['plane0'];
        Uint8List plane1 = message['plane1'];
        Uint8List plane2 = message['plane2'];
        int rowStride0 = message['rowStride0'];
        int rowStride1 = message['rowStride1'];
        int pixelStride1 = message['pixelStride1'];
        int rowStride2 = message['rowStride2'];
        int pixelStride2 = message['pixelStride2'];
        int sensorOrientation = message['sensorOrientation'];
        bool isFrontCamera = message['isFrontCamera'];

        // 1. Efficient Image Conversion
        Float32List inputBytes;
        if (isYUV) {
          inputBytes = ImageUtils.convertYUV420ToFloat32(
            width,
            height,
            plane0,
            plane1,
            plane2,
            rowStride0,
            rowStride1,
            pixelStride1,
            rowStride2,
            pixelStride2,
            sensorOrientation,
            isFrontCamera,
          );
        } else {
          inputBytes = ImageUtils.convertBGRA8888ToFloat32(
            width,
            height,
            plane0,
            rowStride0,
            sensorOrientation,
            isFrontCamera,
          );
        }

        var inputTensor = inputBytes.buffer.asFloat32List().reshape([
          1,
          224,
          224,
          3,
        ]);
        var outputTensor = List.filled(
          1 * labels!.length,
          0.0,
        ).reshape([1, labels!.length]);

        // 3. Run Inference
        interpreter!.run(inputTensor, outputTensor);

        // 4. Extract highest confidence dynamically over all classes
        List<double> probabilities = (outputTensor[0] as List).cast<double>();

        int highestIdx = 0;
        double highestProb = probabilities[0];
        for (int i = 0; i < probabilities.length; i++) {
          if (probabilities[i] > highestProb) {
            highestProb = probabilities[i];
            highestIdx = i;
          }
        }

        mainSendPort.send({
          'type': 'result',
          'label': labels![highestIdx],
          'confidence': highestProb,
        });
      }
    }
  });
}

// ═══════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ── Core Services ────────────────────────────────────────────────
  CameraController? _camera;
  final FlutterTts _tts = FlutterTts();
  final InferenceWorker _worker = InferenceWorker();

  // ── State Variables ──────────────────────────────────────────────
  bool _isInit = false;
  bool _isProcessing = false;
  bool _isMuted = false;
  List<CameraDescription> _cameras = [];
  int _camIndex = 0;

  String _translatedText = '—';
  String _rawLabel = 'Kosong';
  double _accuracy = 0.0;

  String _lastSpokenWord = '';

  // Smoothing / Debouncing Variables
  String _candidateLabel = '';
  int _consecutiveFrames = 0;

  // Throttling control (300ms)
  DateTime _lastRunTime = DateTime.now();
  final int _intervalMs = 300;

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    try {
      // 1. Setup TTS
      await _tts.setLanguage("id-ID");
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      // 2. Preload Model Bytes and Labels into memory
      final byteData = await rootBundle.load('assets/model_unquant.tflite');
      final modelBytes = byteData.buffer.asUint8List();

      String labelsData = await rootBundle.loadString('assets/labels.txt');
      final labels = labelsData
          .split('\n')
          .map((e) {
            int spaceIdx = e.indexOf(' ');
            return spaceIdx != -1 ? e.substring(spaceIdx + 1).trim() : e.trim();
          })
          .where((e) => e.isNotEmpty)
          .toList();

      await _worker.init(modelBytes, labels);

      // 3. Setup Camera
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _camIndex = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        if (_camIndex == -1) _camIndex = 0;
        await _initCamera(_cameras[_camIndex]);
      }

      setState(() => _isInit = true);
    } catch (e) {
      debugPrint("Initialization Error: $e");
    }
  }

  Future<void> _initCamera(CameraDescription desc) async {
    _camera = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _camera!.initialize();

    // Preview on main thread, inference throttled
    _camera!.startImageStream((CameraImage image) {
      _processCameraFrame(image);
    });
  }

  void _processCameraFrame(CameraImage image) async {
    // 1. Throttling: only perform inference every 300ms
    final now = DateTime.now();
    if (_isProcessing ||
        now.difference(_lastRunTime).inMilliseconds < _intervalMs) {
      return;
    }
    _isProcessing = true;
    _lastRunTime = now;

    try {
      final isYUV = image.format.group == ImageFormatGroup.yuv420;

      // Fast memory copy (memcpy) instead of slow Dart iteration (Uint8List.fromList)
      Uint8List cloneBytes(Uint8List bytes) {
        return Uint8List(bytes.length)..setAll(0, bytes);
      }

      final plane0 = cloneBytes(image.planes[0].bytes);
      final plane1 = image.planes.length > 1
          ? cloneBytes(image.planes[1].bytes)
          : Uint8List(0);
      final plane2 = image.planes.length > 2
          ? cloneBytes(image.planes[2].bytes)
          : Uint8List(0);

      final Map<String, dynamic> params = {
        'width': image.width,
        'height': image.height,
        'isYUV': isYUV,
        'plane0': plane0,
        'plane1': plane1,
        'plane2': plane2,
        'rowStride0': image.planes[0].bytesPerRow,
        'rowStride1': image.planes.length > 1 ? image.planes[1].bytesPerRow : 0,
        'pixelStride1': image.planes.length > 1
            ? (image.planes[1].bytesPerPixel ?? 1)
            : 1,
        'rowStride2': image.planes.length > 2 ? image.planes[2].bytesPerRow : 0,
        'pixelStride2': image.planes.length > 2
            ? (image.planes[2].bytesPerPixel ?? 1)
            : 1,
        'sensorOrientation': _cameras[_camIndex].sensorOrientation,
        'isFrontCamera':
            _cameras[_camIndex].lensDirection == CameraLensDirection.front,
      };

      // 2. Trigger persistent Isolate safely
      final result = await _worker.infer(params);

      if (!mounted) return;

      String detectedLabel = result['label'];
      double confidence = result['confidence'];

      // 3. Prediction Smoothing (Confidence > 75% & Debouncer)
      setState(() {
        if (confidence > 0.75) {
          if (detectedLabel == _candidateLabel) {
            _consecutiveFrames++;
            if (_consecutiveFrames >= 3) {
              // Word confirmed for 3 frames! Lock it into UI.
              _rawLabel = detectedLabel;
              _accuracy = confidence;

              if (detectedLabel.toLowerCase() == 'kosong') {
                _translatedText = 'Menunggu isyarat...';
              } else {
                _translatedText = detectedLabel;

                // Smart TTS Debouncer
                if (_translatedText != _lastSpokenWord) {
                  _lastSpokenWord = _translatedText;
                  if (!_isMuted) {
                    _tts.speak(_translatedText);
                  }
                }
              }
            }
          } else {
            // Label changed, reset the debouncer counter
            _candidateLabel = detectedLabel;
            _consecutiveFrames = 1;
          }
        } else {
          // Reset if confidence drops below threshold
          _candidateLabel = '';
          _consecutiveFrames = 0;
        }
      });
    } catch (e) {
      debugPrint("Inference Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  // ── Callbacks ────────────────────────────────────────────────────
  Future<void> _onFlipCamera() async {
    if (_cameras.length < 2 || _camera == null) return;
    await _camera!.stopImageStream();
    await _camera!.dispose();

    _camIndex = (_camIndex + 1) % _cameras.length;
    setState(() => _isInit = false);
    await _initCamera(_cameras[_camIndex]);
    setState(() => _isInit = true);
  }

  void _onClearText() {
    setState(() {
      _translatedText = 'Menunggu isyarat...';
      _lastSpokenWord = ''; // Reset so it can be spoken again
    });
  }

  void _onToggleVoice() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _tts.stop();
    }
  }

  @override
  void dispose() {
    _camera?.stopImageStream();
    _camera?.dispose();
    _tts.stop();
    _worker.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return Scaffold(
        backgroundColor: _C.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/app_icon.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: _C.primary),
              const SizedBox(height: 24),
              const Text(
                'SignBridge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Loading Application...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(flex: 70, child: _buildCameraArea()),
            Expanded(flex: 30, child: _buildTranslationArea()),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: _C.surfaceLevel1,
            child: _camera != null && _camera!.value.isInitialized
                ? Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: ClipRect(
                        child: Transform.scale(
                          scale: _camera!.value.aspectRatio > 1.0
                              ? _camera!.value.aspectRatio
                              : 1.0 / _camera!.value.aspectRatio,
                          child: Center(child: CameraPreview(_camera!)),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
        ),
        Center(child: _buildScanFrame()),
        Align(
          alignment: const Alignment(0.0, 0.45),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _C.surfaceLevel2.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.outline10, width: 1),
            ),
            child: Text(
              'Posisikan tangan di sini',
              style: _T.labelLg.copyWith(color: _C.onSurface),
            ),
          ),
        ),
        Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _C.background.withValues(alpha: 0.80),
            _C.background.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_rounded),
            color: _C.onSurface,
            iconSize: 24,
            tooltip: 'Menu',
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          Text(
            'SignBridge',
            style: _T.headlineMd.copyWith(
              color: _C.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _onFlipCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
            color: _C.primary,
            iconSize: 26,
            tooltip: 'Balik Kamera',
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    const double size = 260;
    const double arm = 50;
    const double thick = 3.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerBracketPainter(
          color: _C.primary,
          armLength: arm,
          strokeWidth: thick,
          radius: 12,
        ),
      ),
    );
  }

  Widget _buildTranslationArea() {
    bool isKosong = _rawLabel.toLowerCase() == 'kosong' || _accuracy < 0.5;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _C.background,
        border: Border(top: BorderSide(color: _C.outline10, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isKosong ? _C.onSurfaceDim : _C.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isKosong ? 'Menunggu isyarat...' : 'Mendeteksi gerakan...',
                style: _T.bodyMd.copyWith(color: _C.onSurfaceDim, fontSize: 14),
              ),
              const Spacer(),
              Text(
                'Akurasi: ${(_accuracy * 100).toInt()}%',
                style: _T.labelLg.copyWith(color: _C.primary, fontSize: 14),
              ),
            ],
          ),

          const Spacer(),

          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                _translatedText,
                key: ValueKey<String>(_translatedText),
                style: _T.translationDisplay.copyWith(
                  color: isKosong ? _C.onSurfaceDim : _C.primary,
                  fontStyle: isKosong ? FontStyle.italic : FontStyle.normal,
                  fontSize: isKosong ? 28 : 40,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const Spacer(),

          Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: OutlinedButton(
                  onPressed: _onClearText,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: _C.onSurfaceDim, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: _C.onSurface,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _onToggleVoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMuted ? _C.surfaceLevel2 : _C.primary,
                      foregroundColor: _isMuted ? _C.onSurface : _C.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      size: 22,
                    ),
                    label: Text(
                      _isMuted ? 'Suara Mati' : 'Suara Aktif',
                      style: _T.labelLg.copyWith(
                        color: _isMuted ? _C.onSurface : _C.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double armLength;
  final double strokeWidth;
  final double radius;

  _CornerBracketPainter({
    required this.color,
    required this.armLength,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final a = armLength;
    final r = radius;

    canvas.drawPath(
      Path()
        ..moveTo(0, a)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(a, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - a, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, a),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h - a)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(a, h),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - a, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, h - r)
        ..lineTo(w, h - a),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter old) =>
      old.color != color ||
      old.armLength != armLength ||
      old.strokeWidth != strokeWidth;
}
