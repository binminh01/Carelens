import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/prescription.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/isar_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_utils.dart';

// --- Scan Screen ---------------------------------------------------------

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _ScanState { preview, analyzing, done, error }

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBoundingBoxMixin, TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  _ScanState _state = _ScanState.preview;
  String _errorMessage = '';

  final ImagePicker _imagePicker = ImagePicker();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut));
    _initCamera();
  }

  Future<void> _initCamera([int cameraIndex = 0]) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setError('Không tìm thấy camera trên thiết bị. Bạn vẫn có thể chọn ảnh từ thư viện.');
        return;
      }
      _selectedCameraIndex = cameraIndex.clamp(0, _cameras.length - 1);
      final camera = _cameras[_selectedCameraIndex];
      _cameraController?.dispose();
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      _setError('Không thể khởi động camera: $e\nBạn có thể thử lại hoặc chọn ảnh từ thư viện.');
    }
  }

  Future<void> _toggleCameraLens() async {
    if (_cameras.length <= 1) return;
    HapticFeedback.selectionClick();
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCamera(nextIndex);
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _state = _ScanState.error;
        _errorMessage = message;
      });
    }
  }

  // ─── 1. Chụp ảnh từ Camera & Phân tích ──────────────────────────────────
  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _state == _ScanState.analyzing) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _state = _ScanState.analyzing);

    try {
      final xFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await xFile.readAsBytes();
      await _processImageBytes(imageBytes);
    } catch (e) {
      _setError('Lỗi chụp ảnh: $e\nVui lòng thử lại hoặc chọn ảnh từ thư viện.');
    }
  }

  // ─── 2. Chọn ảnh từ Thư viện (Gallery) & Phân tích ────────────────────
  Future<void> _pickFromGalleryAndAnalyze() async {
    if (_state == _ScanState.analyzing) return;

    HapticFeedback.mediumImpact();

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConstants.imageQuality,
      );

      if (pickedFile == null) return;

      setState(() => _state = _ScanState.analyzing);

      final Uint8List imageBytes = await pickedFile.readAsBytes();
      await _processImageBytes(imageBytes);
    } catch (e) {
      _setError('Lỗi khi tải ảnh từ thư viện: $e\nVui lòng thử lại.');
    }
  }

  // ─── Xử lý chung phân tích mảng byte ảnh qua Gemini ───────────────────
  Future<void> _processImageBytes(Uint8List imageBytes) async {
    try {
      if (!GeminiService.instance.isInitialized) {
        GeminiService.instance.initialize();
      }

      // Gọi Gemini OCR phân tích — trả về List<ParsedPrescription>
      final parsedList =
          await GeminiService.instance.analyzePrescriptionImage(imageBytes);

      if (!mounted) return;

      if (parsedList.isEmpty) {
        _setError('Không đọc được thông tin đơn thuốc từ ảnh.\nVui lòng chụp hoặc chọn lại ảnh rõ nét hơn.');
        return;
      }

      setState(() => _state = _ScanState.done);

      // Hiển thị dialog xem xét các đơn thuốc tìm được
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MultiPrescriptionReviewDialog(parsedList: parsedList),
      );

      if (saved == true && mounted) {
        final n = parsedList.length;
        AppUtils.showSnackBar(
          context,
          n > 1 ? 'Đã lưu $n đơn thuốc thành công!' : 'Đã lưu đơn thuốc thành công!',
        );
        Navigator.pop(context);
      } else if (mounted) {
        setState(() => _state = _ScanState.preview);
      }
    } catch (e) {
      _setError('Lỗi phân tích đơn thuốc: $e\nVui lòng thử lại.');
    }
  }

  void _retryCamera() {
    setState(() {
      _state = _ScanState.preview;
      _errorMessage = '';
    });
    _initCamera(_selectedCameraIndex);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildCameraLayer(),
            if (_state == _ScanState.preview || _state == _ScanState.analyzing)
              _ScanOverlay(
                isAnalyzing: _state == _ScanState.analyzing,
                scanLineAnimation: _scanLineAnimation,
                pulseAnimation: _pulseAnimation,
              ),
            _buildTopBar(),
            if (_state == _ScanState.analyzing) _buildAnalyzingOverlay(),
            if (_state == _ScanState.preview) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_state == _ScanState.error) {
      return _ErrorView(
        message: _errorMessage,
        onRetry: _retryCamera,
        onPickGallery: _pickFromGalleryAndAnalyze,
      );
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGreen),
      );
    }
    return Positioned.fill(child: CameraPreview(_cameraController!));
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXL,
          vertical: AppSizes.paddingM,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quét đơn thuốc',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    _state == _ScanState.analyzing
                        ? 'Đang phân tích bằng Gemini AI...'
                        : 'Chụp hoặc tải ảnh đơn thuốc',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Shortcut nút Thư viện ảnh ở thanh tiêu đề trên
            InkWell(
              onTap: _pickFromGalleryAndAnalyze,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.accentGreen,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Thư viện',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGreen
                      .withValues(alpha: 0.15 * _pulseAnimation.value),
                  border: Border.all(
                    color: AppColors.accentGreen
                        .withValues(alpha: _pulseAnimation.value),
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accentGreen,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),
            const Text(
              'Đang phân tích đơn thuốc\nbằng Gemini AI...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            const Text(
              'Vui lòng chờ trong giây lát',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXXL),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.navyMid,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingXL,
          AppSizes.paddingL,
          AppSizes.paddingXL,
          AppSizes.paddingXXL,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.95),
              Colors.black.withValues(alpha: 0.65),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.5),
                ),
              ),
              child: const Text(
                'Chụp ảnh mới hoặc Chọn ảnh có sẵn từ máy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Nút 1: Chọn từ thư viện ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickFromGalleryAndAnalyze,
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.navyLight,
                          border: Border.all(
                            color: AppColors.accentGreen,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: AppColors.accentGreen,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tải ảnh lên',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),

                // ── Nút 2: Chụp ảnh trực tiếp bằng Camera (Chính) ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _captureAndAnalyze,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentGreen,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withValues(alpha: 0.55),
                              blurRadius: 22,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chụp ảnh',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGreenLight,
                      ),
                    ),
                  ],
                ),

                // ── Nút 3: Đổi Camera ──
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _toggleCameraLens,
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.navyLight,
                          border: Border.all(
                            color: AppColors.navyMid,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đổi camera',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Error View ----------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onPickGallery;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.errorRed,
                size: AppSizes.iconXL,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXXL),
            ElevatedButton.icon(
              onPressed: onPickGallery,
              icon: const Icon(Icons.photo_library_rounded, size: 24),
              label: const Text(
                'Chọn ảnh từ thư viện',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: AppColors.white,
                minimumSize: const Size(220, AppSizes.buttonHeightLarge),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: const Text(
                'Thử lại camera',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(220, AppSizes.buttonHeight),
                side: const BorderSide(color: AppColors.navyMid, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Scan Overlay --------------------------------------------------------

class _ScanOverlay extends StatelessWidget {
  final bool isAnalyzing;
  final Animation<double> scanLineAnimation, pulseAnimation;
  const _ScanOverlay({
    required this.isAnalyzing,
    required this.scanLineAnimation,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned.fill(
      child: CustomPaint(
        painter: _ScanFramePainter(
          frameWidth: 300,
          frameHeight: 220,
          screenSize: size,
          isAnalyzing: isAnalyzing,
          scanLineProgress: scanLineAnimation.value,
          pulseValue: pulseAnimation.value,
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  final double frameWidth, frameHeight;
  final Size screenSize;
  final bool isAnalyzing;
  final double scanLineProgress, pulseValue;

  _ScanFramePainter({
    required this.frameWidth,
    required this.frameHeight,
    required this.screenSize,
    required this.isAnalyzing,
    required this.scanLineProgress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final frameRect =
        Rect.fromCenter(center: Offset(cx, cy), width: frameWidth, height: frameHeight);
    final rrect = RRect.fromRectAndRadius(frameRect, const Radius.circular(16));
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.55));

    final borderColor = isAnalyzing
        ? Color.lerp(AppColors.accentGreen, AppColors.accentGreenLight, pulseValue)!
        : AppColors.accentGreen;
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final cornerPaint = Paint()
      ..color = isAnalyzing
          ? Color.lerp(AppColors.accentGreenLight, AppColors.white, pulseValue)!
              .withValues(alpha: 0.9)
          : AppColors.accentGreenLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cLen = 30.0;
    for (int i = 0; i < 4; i++) {
      final dx = (i == 0 || i == 2) ? frameRect.left : frameRect.right;
      final dy = (i == 0 || i == 1) ? frameRect.top : frameRect.bottom;
      final hd = (i == 0 || i == 2) ? 1.0 : -1.0;
      final vd = (i == 0 || i == 1) ? 1.0 : -1.0;
      canvas.drawLine(Offset(dx, dy), Offset(dx + cLen * hd, dy), cornerPaint);
      canvas.drawLine(Offset(dx, dy), Offset(dx, dy + cLen * vd), cornerPaint);
    }

    if (isAnalyzing) {
      final sy = frameRect.top + frameRect.height * scanLineProgress;
      canvas.drawLine(
        Offset(frameRect.left + 16, sy),
        Offset(frameRect.right - 16, sy),
        Paint()
          ..color = AppColors.accentGreen.withValues(alpha: 0.85)
          ..strokeWidth = 2.5
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.accentGreenLight.withValues(alpha: 0.9),
              Colors.transparent
            ],
          ).createShader(Rect.fromLTWH(frameRect.left, sy, frameRect.width, 2)),
      );
      canvas.drawLine(
        Offset(frameRect.left + 16, sy),
        Offset(frameRect.right - 16, sy),
        Paint()
          ..color = AppColors.accentGreen.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) =>
      old.isAnalyzing != isAnalyzing ||
      old.scanLineProgress != scanLineProgress ||
      old.pulseValue != pulseValue;
}

// --- Multi Prescription Review Dialog (Zero Keyboard Overflow) -----------

class MultiPrescriptionReviewDialog extends StatefulWidget {
  final List<ParsedPrescription> parsedList;
  const MultiPrescriptionReviewDialog({super.key, required this.parsedList});

  @override
  State<MultiPrescriptionReviewDialog> createState() =>
      _MultiPrescriptionReviewDialogState();
}

class _MultiPrescriptionReviewDialogState
    extends State<MultiPrescriptionReviewDialog> {
  late final List<_PrescriptionFormData> _forms;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _forms = widget.parsedList.map((p) => _PrescriptionFormData(p)).toList();
  }

  @override
  void dispose() {
    for (final f in _forms) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    for (int i = 0; i < _forms.length; i++) {
      if (_forms[i].medicineNameCtrl.text.trim().isEmpty) {
        AppUtils.showSnackBar(
          context,
          'Đơn thuốc ${i + 1}: Vui lòng nhập tên thuốc.',
          isError: true,
        );
        return;
      }
    }
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      for (final form in _forms) {
        await IsarService.instance.savePrescription(Prescription.create(
          medicineName: form.medicineNameCtrl.text.trim(),
          dosage: form.dosageCtrl.text.trim().isEmpty
              ? 'Theo chỉ dẫn bác sĩ'
              : form.dosageCtrl.text.trim(),
          scheduleTime: form.scheduleTimeCtrl.text.trim().isEmpty
              ? '08:00'
              : form.scheduleTimeCtrl.text.trim(),
          frequency: form.frequencyCtrl.text.trim().isEmpty
              ? 'Hằng ngày'
              : form.frequencyCtrl.text.trim(),
          instructions: form.instructionsCtrl.text.trim().isEmpty
              ? null
              : form.instructionsCtrl.text.trim(),
        ));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppUtils.showSnackBar(context, 'Lỗi lưu đơn thuốc: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _forms.length;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          maxHeight: availableHeight * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.navyLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
          border: Border.all(color: AppColors.accentGreen, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingXL,
                AppSizes.paddingL,
                AppSizes.paddingM,
                AppSizes.paddingS,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.accentGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin đơn thuốc',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Phát hiện $n liều thuốc',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.accentGreenLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, color: AppColors.midGrey),
                    iconSize: 26,
                  ),
                ],
              ),
            ),

            // AI banner
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingXL,
                vertical: 4,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.accentGreen,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gemini AI đã phân tích xong. Vui lòng kiểm tra và chỉnh sửa nếu cần.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.accentGreenLight,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Scrollable prescription forms (Scrolls smoothly above keyboard)
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXL,
                  vertical: AppSizes.paddingS,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_forms.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == _forms.length - 1 ? 0 : AppSizes.paddingL,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (i > 0) ...[
                            const Divider(
                              color: AppColors.navyMid,
                              thickness: 1,
                              height: 24,
                            ),
                          ],
                          _PrescriptionFormItem(
                            index: i,
                            total: n,
                            form: _forms[i],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Buttons fixed at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingXL,
                AppSizes.paddingM,
                AppSizes.paddingXL,
                AppSizes.paddingL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAll,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.save_rounded,
                              size: 24,
                              color: AppColors.white,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Đang lưu...'
                            : (n > 1 ? 'Lưu $n đơn thuốc' : 'Lưu đơn thuốc'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Chụp lại ảnh khác',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Form Data -----------------------------------------------------------

class _PrescriptionFormData {
  final TextEditingController medicineNameCtrl;
  final TextEditingController dosageCtrl;
  final TextEditingController scheduleTimeCtrl;
  final TextEditingController frequencyCtrl;
  final TextEditingController instructionsCtrl;

  _PrescriptionFormData(ParsedPrescription p)
      : medicineNameCtrl = TextEditingController(text: p.medicineName),
        dosageCtrl = TextEditingController(text: p.dosage),
        scheduleTimeCtrl = TextEditingController(text: p.scheduleTime),
        frequencyCtrl = TextEditingController(text: p.frequency),
        instructionsCtrl = TextEditingController(text: p.instructions);

  void dispose() {
    medicineNameCtrl.dispose();
    dosageCtrl.dispose();
    scheduleTimeCtrl.dispose();
    frequencyCtrl.dispose();
    instructionsCtrl.dispose();
  }
}

// --- Form Item -----------------------------------------------------------

class _PrescriptionFormItem extends StatelessWidget {
  final int index, total;
  final _PrescriptionFormData form;

  const _PrescriptionFormItem({
    required this.index,
    required this.total,
    required this.form,
  });

  Future<void> _pickTime(BuildContext context) async {
    final cur = form.scheduleTimeCtrl.text.trim();
    int h = 8, m = 0;
    final parts = cur.split(':');
    if (parts.length == 2) {
      h = int.tryParse(parts[0]) ?? 8;
      m = int.tryParse(parts[1]) ?? 0;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
      helpText: 'Chọn giờ uống thuốc',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGreen,
              onPrimary: AppColors.white,
              surface: AppColors.navyLight,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      form.scheduleTimeCtrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'Liều ${index + 1}/$total',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGreen,
                ),
              ),
            ),
          ),
        _ReviewField(
          label: 'Tên thuốc',
          controller: form.medicineNameCtrl,
          hint: 'Tên thuốc đầy đủ',
          isRequired: true,
        ),
        const SizedBox(height: AppSizes.paddingM),
        _ReviewField(
          label: 'Liều dùng',
          controller: form.dosageCtrl,
          hint: 'Ví dụ: 1 viên, 2 viên, 5ml',
        ),
        const SizedBox(height: AppSizes.paddingM),
        Row(
          children: [
            Expanded(
              child: _ReviewField(
                label: 'Giờ uống',
                controller: form.scheduleTimeCtrl,
                hint: '08:00',
                keyboardType: TextInputType.datetime,
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.accentGreen,
                    size: 20,
                  ),
                  onPressed: () => _pickTime(context),
                  tooltip: 'Chọn giờ',
                ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: _ReviewField(
                label: 'Tần suất',
                controller: form.frequencyCtrl,
                hint: 'Hằng ngày',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingM),
        _ReviewField(
          label: 'Lưu ý uống thuốc',
          controller: form.instructionsCtrl,
          hint: 'Ví dụ: Uống sau khi ăn no cùng nước ấm',
          maxLines: 2,
        ),
      ],
    );
  }
}

// --- Review Field --------------------------------------------------------

class _ReviewField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool isRequired;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _ReviewField({
    required this.label,
    required this.controller,
    required this.hint,
    this.isRequired = false,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.midGrey,
            ),
            filled: true,
            fillColor: AppColors.deepNavy,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingL,
              vertical: AppSizes.paddingM,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              borderSide:
                  const BorderSide(color: AppColors.accentGreen, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Backward-compat alias -----------------------------------------------

class PrescriptionReviewDialog extends StatelessWidget {
  final ParsedPrescription parsed;
  const PrescriptionReviewDialog({super.key, required this.parsed});
  @override
  Widget build(BuildContext context) =>
      MultiPrescriptionReviewDialog(parsedList: [parsed]);
}

// --- Mixin ---------------------------------------------------------------

mixin WidgetsBoundingBoxMixin<T extends StatefulWidget> on State<T> {}
