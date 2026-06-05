import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/access_api_service.dart';
import '../services/connectivity_service.dart';
import '../services/prediction_api_service.dart';
import '../theme/app_theme.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key, this.accessKeyValidator});

  final AccessKeyValidator? accessKeyValidator;

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage>
    with TickerProviderStateMixin {
  static const String _accessUnlockedPrefKey = 'prediction_access_unlocked';
  static const int _accessKeyLength = 6;

  late final AnimationController _orbitController;
  late final AnimationController _shakeController;
  final AccessApiService _accessApiService = AccessApiService();
  final PredictionApiService _predictionApiService = PredictionApiService();
  final List<TextEditingController> _accessKeyControllers = List.generate(
    _accessKeyLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _accessKeyFocusNodes = List.generate(
    _accessKeyLength,
    (_) => FocusNode(),
  );

  late double _oddsValue;
  late String _signalTime;
  bool _hasAccess = false;
  bool _isLoadingAccess = true;
  bool _showAccessError = false;
  bool _isValidatingAccess = false;
  String? _accessErrorText;

  // Generation and connectivity state
  bool _isGenerating = false;
  bool _isOnline = false;
  Timer? _connectivityTimer;
  String _generationErrorText = '';

  bool get _showAccessOverlay => _isLoadingAccess || !_hasAccess;

  double get _shakeOffset {
    final progress = _shakeController.value;
    return math.sin(progress * math.pi * 5) * 18 * (1 - progress);
  }

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _oddsValue = _buildRandomOdds();
    _signalTime = _buildRandomTime();
    _startConnectivityPolling();
    _restoreAccessState();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _shakeController.dispose();
    _connectivityTimer?.cancel();
    _accessApiService.close();
    _predictionApiService.close();
    for (final controller in _accessKeyControllers) {
      controller.dispose();
    }
    for (final focusNode in _accessKeyFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact =
                constraints.maxHeight < 700 || constraints.maxWidth < 380;
            final rawSize = math.min(
              constraints.maxWidth - 48,
              constraints.maxHeight * 0.58,
            );
            final circleSize = rawSize.clamp(180.0, 340.0).toDouble();

            return Stack(
              children: [
                AbsorbPointer(
                  absorbing: _showAccessOverlay,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      children: [
                        _buildConnectionStatusBar(isCompact: isCompact),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: _buildSignalCircle(
                              size: circleSize,
                              isCompact: isCompact,
                            ),
                          ),
                        ),
                        _buildTimeSection(isCompact: isCompact),
                        const SizedBox(height: 18),
                        _buildGenerateButton(height: isCompact ? 54 : 58),
                      ],
                    ),
                  ),
                ),
                if (_showAccessOverlay)
                  _buildAccessOverlay(isCompact: isCompact),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccessOverlay({required bool isCompact}) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ColoredBox(
            color: const Color(0xD9070B16),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeOffset, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 20 : 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _showAccessError
                              ? AppColors.accent
                              : AppColors.border,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: _isLoadingAccess
                          ? _buildAccessLoadingState()
                          : _buildAccessCardContent(isCompact: isCompact),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text(
              'Checking access...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessCardContent({required bool isCompact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: isCompact ? 62 : 70,
            height: isCompact ? 62 : 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.panel,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.accent,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Enter Access Key',
          style: TextStyle(
            fontSize: isCompact ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-character OTP access key generated from the API.',
          style: TextStyle(
            color: AppColors.textSoft,
            fontSize: isCompact ? 13 : 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _buildPaymentInfoCard(isCompact: isCompact),
        const SizedBox(height: 18),
        _buildOtpInput(isCompact: isCompact),
        if (_accessErrorText != null) ...[
          const SizedBox(height: 10),
          Text(
            _accessErrorText!,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentStrong],
              ),
            ),
            child: ElevatedButton(
              onPressed: _isValidatingAccess ? null : _submitAccessKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isValidatingAccess
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput({required bool isCompact}) {
    return Row(
      children: List.generate(_accessKeyLength, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == _accessKeyLength - 1 ? 0 : (isCompact ? 6 : 8),
            ),
            child: _buildOtpField(index: index, isCompact: isCompact),
          ),
        );
      }),
    );
  }

  Widget _buildOtpField({required int index, required bool isCompact}) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.backspace ||
            _accessKeyControllers[index].text.isNotEmpty ||
            index == 0) {
          return KeyEventResult.ignored;
        }

        _accessKeyFocusNodes[index - 1].requestFocus();
        _accessKeyControllers[index - 1].clear();
        return KeyEventResult.handled;
      },
      child: TextField(
        controller: _accessKeyControllers[index],
        focusNode: _accessKeyFocusNodes[index],
        enabled: !_isValidatingAccess,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        textInputAction: index == _accessKeyLength - 1
            ? TextInputAction.done
            : TextInputAction.next,
        keyboardType: TextInputType.visiblePassword,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        ],
        onChanged: (value) => _handleAccessKeyChanged(index, value),
        onSubmitted: (_) => _submitAccessKey(),
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 19 : 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.panel,
          contentPadding: EdgeInsets.symmetric(vertical: isCompact ? 15 : 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _showAccessError ? AppColors.accent : AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _showAccessError ? AppColors.accent : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard({required bool isCompact}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lipia kwenye lipa namba hii',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Provider label
          Text(
            'Voda lipa',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // Phone number - tappable to copy
          InkWell(
            onTap: () async {
              const phone = '354269723';
              await Clipboard.setData(const ClipboardData(text: phone));
              if (mounted) {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lipa number copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } catch (_) {}
              }
            },
            child: Text(
              '35 426 9723',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: isCompact ? 23 : 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Account / payer name with WhatsApp action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MECK CANDIDUS',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openWhatsApp,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: FaIcon(
                    FontAwesomeIcons.whatsapp,
                    size: 18,
                    color: Color(0xFF25D366),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'After payment, contact this number on WhatsApp to receive your access key.',
            style: TextStyle(
              color: AppColors.textSoft,
              fontSize: isCompact ? 12 : 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          _buildPaymentLine('10000Tsh week'),
          const SizedBox(height: 8),
          _buildPaymentLine('30000Tsh month'),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/255750060172');

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open WhatsApp'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open WhatsApp'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildPaymentLine(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSignalCircle({required double size, required bool isCompact}) {
    final borderWidth = isCompact ? 6.0 : 8.0;
    final labelSize = isCompact ? 15.0 : 18.0;
    final oddsSize = size * (isCompact ? 0.19 : 0.2);

    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        final progress = _orbitController.value;
        final pulse = 1 + (0.025 * math.sin(progress * math.pi * 2));
        final glowBlur =
            24 + (12 * (0.5 + 0.5 * math.sin(progress * math.pi * 2)));
        final orbitAngle = progress * math.pi * 2;
        final orbitRadius = (size / 2) - 12;
        final dotSize = isCompact ? 10.0 : 12.0;
        final dotLeft =
            (size / 2) + math.cos(orbitAngle) * orbitRadius - (dotSize / 2);
        final dotTop =
            (size / 2) + math.sin(orbitAngle) * orbitRadius - (dotSize / 2);

        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: orbitAngle / 1.8,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: const _OrbitRingPainter(),
                  ),
                ),
                Positioned(
                  left: dotLeft,
                  top: dotTop,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x99FF355D),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: size - 16,
                  height: size - 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent,
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x55FF355D),
                        blurRadius: glowBlur,
                        spreadRadius: 4,
                      ),
                    ],
                    gradient: const RadialGradient(
                      colors: [Color(0xFF10192C), Color(0xFF090E18)],
                    ),
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.10),
          child: _buildNormalContent(size, isCompact, labelSize, oddsSize),
        ),
      ),
    );
  }

  Widget _buildNormalContent(
    double size,
    bool isCompact,
    double labelSize,
    double oddsSize,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ODDS',
          style: TextStyle(
            color: AppColors.textSoft,
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: size * 0.06),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            );
          },
          child: Text(
            '${_oddsValue.toStringAsFixed(2)}x',
            key: ValueKey(_oddsValue.toStringAsFixed(2)),
            style: TextStyle(
              fontSize: oddsSize,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
              letterSpacing: 1.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusBar({required bool isCompact}) {
    final isDisabled = !_isOnline;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 16,
        vertical: isCompact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDisabled ? Colors.orange : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          Icon(
            isDisabled ? Icons.wifi_off_rounded : Icons.wifi_rounded,
            color: isDisabled ? Colors.orange : Colors.greenAccent,
            size: isCompact ? 20 : 22,
          ),
          if (_generationErrorText.isNotEmpty) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _generationErrorText,
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (_isGenerating) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: isCompact ? 14 : 16,
              height: isCompact ? 14 : 16,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTimeSection({required bool isCompact}) {
    return Column(
      children: [
        Text(
          'TIME TO PLAY',
          style: TextStyle(
            color: AppColors.textSoft,
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            );
          },
          child: Text(
            _signalTime,
            key: ValueKey(_signalTime),
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 28 : 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton({required double height}) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: _isGenerating
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : const [AppColors.accent, AppColors.accentStrong],
          ),
          boxShadow: [
            BoxShadow(
              color: _isGenerating
                  ? const Color(0x22FFFFFF)
                  : const Color(0x44FF355D),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isGenerating || !_isOnline
              ? null
              : _generateSignalWithConnectivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          icon: _isGenerating
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey.shade300,
                    ),
                  ),
                )
              : Icon(
                  _isOnline
                      ? Icons.auto_awesome_outlined
                      : Icons.cloud_off_outlined,
                  color: Colors.white,
                ),
          label: Text(
            _isGenerating
                ? 'Generating...'
                : (_isOnline ? 'Generate' : 'Offline'),
            style: TextStyle(
              color: _isGenerating ? Colors.grey.shade300 : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreAccessState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccess = prefs.getBool(_accessUnlockedPrefKey) ?? false;
    final savedKey = prefs.getString('prediction_access_key') ?? '';
    final savedExpires = prefs.getString('prediction_access_expires_at') ?? '';

    if (!mounted) {
      return;
    }

    // If there is a saved key, attempt to re-validate with the server.
    if (hasAccess && savedKey.isNotEmpty) {
      try {
        final validator =
            widget.accessKeyValidator ?? _accessApiService.validateAccessKey;
        final result = await validator(savedKey);
        if (!mounted) return;

        if (result.isValid) {
          // Persist latest expiry if available
          if (result.expiresAt != null) {
            await prefs.setString(
              'prediction_access_expires_at',
              result.expiresAt!.toIso8601String(),
            );
          }
          setState(() {
            _hasAccess = true;
            _isLoadingAccess = false;
          });
          return;
        }

        // Invalid according to server: clear local state
        await prefs.remove(_accessUnlockedPrefKey);
        await prefs.remove('prediction_access_key');
        await prefs.remove('prediction_access_expires_at');
        setState(() {
          _hasAccess = false;
          _isLoadingAccess = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _accessKeyFocusNodes.first.requestFocus();
          }
        });
        return;
      } catch (_) {
        // Network error: fall back to local expiry check below
      }
    }

    // Fallback: if we have an expires timestamp stored locally, check expiry
    if (hasAccess && savedExpires.isNotEmpty) {
      final parsed = DateTime.tryParse(savedExpires);
      if (parsed != null && parsed.isAfter(DateTime.now())) {
        setState(() {
          _hasAccess = true;
          _isLoadingAccess = false;
        });
        return;
      }
      // expired locally
      await prefs.remove(_accessUnlockedPrefKey);
      await prefs.remove('prediction_access_key');
      await prefs.remove('prediction_access_expires_at');
      setState(() {
        _hasAccess = false;
        _isLoadingAccess = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _accessKeyFocusNodes.first.requestFocus();
        }
      });
      return;
    }

    // Default: no saved access
    setState(() {
      _hasAccess = false;
      _isLoadingAccess = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _accessKeyFocusNodes.first.requestFocus();
      }
    });
  }

  Future<void> _submitAccessKey() async {
    if (_isValidatingAccess) return;

    final enteredKey = _enteredAccessKey;
    // ignore: avoid_print
    print('PredictionPage: entered access key -> $enteredKey');

    if (enteredKey.length != _accessKeyLength) {
      _triggerAccessError('Enter the full 6-character access key.');
      return;
    }

    setState(() {
      _isValidatingAccess = true;
      _showAccessError = false;
      _accessErrorText = null;
    });

    try {
      final validator =
          widget.accessKeyValidator ?? _accessApiService.validateAccessKey;
      final result = await validator(enteredKey);

      if (!mounted) {
        return;
      }

      if (!result.isValid) {
        setState(() => _isValidatingAccess = false);
        _triggerAccessError(result.message ?? 'Incorrect access key.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_accessUnlockedPrefKey, true);
      await prefs.setString('prediction_access_key', enteredKey);
      if (result.expiresAt != null) {
        await prefs.setString(
          'prediction_access_expires_at',
          result.expiresAt!.toIso8601String(),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _hasAccess = true;
        _showAccessError = false;
        _isValidatingAccess = false;
        _accessErrorText = null;
      });

      _clearAccessKeyInputs();
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isValidatingAccess = false);
      _triggerAccessError('Unable to validate key. Check your connection.');
    }
  }

  void _handleAccessKeyChanged(int index, String value) {
    final normalized = value
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    if (_showAccessError || _accessErrorText != null) {
      setState(() {
        _showAccessError = false;
        _accessErrorText = null;
      });
    }

    if (normalized.length > 1) {
      _fillAccessKeyFromPaste(index, normalized);
      return;
    }

    final controller = _accessKeyControllers[index];
    if (controller.text != normalized) {
      controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    if (normalized.isNotEmpty && index < _accessKeyLength - 1) {
      _accessKeyFocusNodes[index + 1].requestFocus();
    }
  }

  void _fillAccessKeyFromPaste(int startIndex, String value) {
    final characters = value.split('');
    var lastFilledIndex = startIndex;

    for (var offset = 0; offset < characters.length; offset++) {
      final targetIndex = startIndex + offset;

      if (targetIndex >= _accessKeyLength) {
        break;
      }

      _accessKeyControllers[targetIndex].value = TextEditingValue(
        text: characters[offset],
        selection: const TextSelection.collapsed(offset: 1),
      );
      lastFilledIndex = targetIndex;
    }

    final nextIndex = math.min(lastFilledIndex + 1, _accessKeyLength - 1);
    _accessKeyFocusNodes[nextIndex].requestFocus();
  }

  String get _enteredAccessKey {
    return _accessKeyControllers.map((controller) => controller.text).join();
  }

  void _clearAccessKeyInputs() {
    for (final controller in _accessKeyControllers) {
      controller.clear();
    }
  }

  void _triggerAccessError([String message = 'Incorrect access key.']) {
    setState(() {
      _showAccessError = true;
      _accessErrorText = message;
    });
    _shakeController.forward(from: 0);
    _playErrorVibrationPattern();
  }

  Future<void> _playErrorVibrationPattern() async {
    // Double vibration pattern for strong error feedback
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  Future<void> _generateSignalWithConnectivity() async {
    if (_isGenerating) return;
    if (!_isOnline) {
      _showOfflineError('No internet connection.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationErrorText = '';
    });

    try {
      final prediction = await _predictionApiService.fetchPrediction();
      if (!mounted) return;

      setState(() {
        _oddsValue = prediction.odds;
        _signalTime = prediction.playTime;
        _isGenerating = false;
        _generationErrorText = '';
      });

      // Show success feedback with vibration only
      if (mounted) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (!mounted) return;

      String message;
      // ignore: avoid_print
      print(
        'PredictionPage: fetchPrediction exception -> ${e.runtimeType}: $e',
      );

      if (e is HttpException) {
        message = e.message;
      } else if (e is FormatException) {
        // FormatException.message contains the error description
        message = e.message.toString();
        if (message.isEmpty) {
          message = 'API returned invalid data.';
        }
      } else {
        message = 'Unable to load prediction.';
      }

      // ignore: avoid_print
      print('PredictionPage: extracted message -> $message');

      _showOfflineError(message);
    }
  }

  void _showOfflineError(String message) {
    setState(() {
      _isGenerating = false;
      _generationErrorText = message;
    });

    // Debug: log the message and show a SnackBar so it's visible immediately
    // ignore: avoid_print
    print('PredictionPage: showing generation error -> $message');
    if (mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (_) {}
    }

    HapticFeedback.heavyImpact();
  }

  void _startConnectivityPolling() {
    _refreshConnectivityStatus();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshConnectivityStatus();
    });
  }

  Future<void> _refreshConnectivityStatus() async {
    final connectivity = ConnectivityService();
    final hasConnection = await connectivity.hasInternetConnection();
    if (!mounted) return;

    if (hasConnection == _isOnline) {
      return;
    }

    setState(() {
      _isOnline = hasConnection;
      if (_isOnline && _generationErrorText == 'No internet connection.') {
        _generationErrorText = '';
      }
    });
  }

  double _buildRandomOdds() {
    return 0;
  }

  String _buildRandomTime() {
    return '00:00:00';
  }
}

class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width / 2) - 4,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    paint.color = AppColors.accent.withAlpha(140);
    canvas.drawArc(rect, -math.pi / 2, math.pi / 3, false, paint);

    paint.color = AppColors.accent.withAlpha(80);
    canvas.drawArc(rect, math.pi / 4, math.pi / 5, false, paint);

    paint.color = Colors.white.withAlpha(38);
    canvas.drawArc(rect, math.pi, math.pi / 4, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
