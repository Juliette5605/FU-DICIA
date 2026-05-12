// lib/screens/collectrice/scan_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import '../../services/gps_service.dart';

class ScanFlowScreen extends StatefulWidget {
  final Collectrice collectrice;
  final VoidCallback? onCollecteComplete;

  const ScanFlowScreen({
    super.key,
    required this.collectrice,
    this.onCollecteComplete,
  });

  @override
  State<ScanFlowScreen> createState() => _ScanFlowScreenState();
}

class _ScanFlowScreenState extends State<ScanFlowScreen>
    with TickerProviderStateMixin {
  int _step = 0; // 0=scan, 1=confirm, 2=photo, 3=montant, 4=signature, 5=success

  String? _scannedQr;
  String? _clientNom;
  String? _photoPath;
  double? _montant;
  Position? _position;

  late AnimationController _successAnim;
  final _montantController = TextEditingController();
  final _clientNomController = TextEditingController();
  final _sigCtrl = SignatureController(
    penStrokeWidth: 2.5,
    penColor: const Color(0xFF1BD6FF),
    exportBackgroundColor: Colors.transparent,
  );

  int _scanCount = 0;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadScanCount();
    _getPosition();
  }

  Future<void> _loadScanCount() async {
    final count =
        await DatabaseService.countCollectesToday(widget.collectrice.id);
    setState(() => _scanCount = count);
  }

  Future<void> _getPosition() async {
    _position = await GpsService.getCurrentPosition();
  }

  @override
  void dispose() {
    _successAnim.dispose();
    _montantController.dispose();
    _clientNomController.dispose();
    _sigCtrl.dispose();
    super.dispose();
  }

  // ── ÉTAPES ──────────────────────────────────────────────
  Future<void> _onQrScanned(String code) async {
    // Anti-double scan
    final alreadyScanned = await DatabaseService.isAlreadyScannedToday(code);
    if (alreadyScanned && mounted) {
      _showError('⚠️ Ce client a déjà été scanné aujourd\'hui !');
      return;
    }

    setState(() {
      _scannedQr = code;
      _clientNom = 'Client ${code.substring(0, 8)}';
      _clientNomController.text = _clientNom!;
      _step = 1;
    });
  }

  bool get _needsPhoto {
    // Photo obligatoire 3 premiers scans, aléatoire après
    if (_scanCount < 3) return true;
    return DateTime.now().second % 5 == 0;
  }

  Future<void> _onConfirmed() async {
    _clientNom = _clientNomController.text;
    setState(() => _step = _needsPhoto ? 2 : 3);
  }

  Future<void> _onPhotoTaken() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 960,
    );
    if (image != null) {
      setState(() {
        _photoPath = image.path;
        _step = 3;
      });
    }
  }

  Future<void> _onMontantConfirmed() async {
    final montant = double.tryParse(_montantController.text);
    if (montant == null || montant <= 0) {
      _showError('Entrez un montant valide');
      return;
    }
    setState(() {
      _montant = montant;
      _step = 4;
    });
  }

  Future<void> _onSignatureConfirmed() async {
    if (_sigCtrl.isEmpty) {
      _showError('La signature est requise');
      return;
    }
    await _saveCollecte();
  }

  Future<void> _saveCollecte() async {
    final collecte = Collecte(
      collectriceId: widget.collectrice.id,
      clientNom: _clientNom ?? 'Inconnu',
      clientQrCode: _scannedQr,
      montantReel: _montant ?? 0,
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      photoPath: _photoPath,
      collectedAt: DateTime.now(),
    );

    // Sauvegarde locale
    await DatabaseService.insertCollecte(collecte);

    // Marquer QR comme scanné aujourd'hui
    if (_scannedQr != null) {
      await DatabaseService.markScannedToday(_scannedQr!, _clientNom ?? '');

      // Apprentissage geofencing (3 premiers scans)
      if (_scanCount < 3 && _position != null) {
        await GpsService.learnClientZone(
          _scannedQr!,
          _position!.latitude,
          _position!.longitude,
        );
      }
    }

    // Sync Supabase en arrière-plan
    SupabaseService.syncCollecte(collecte);

    // Anomalie si montant faible
    if ((_montant ?? 0) < 3000) {
      SupabaseService.createAnomalie(
        collectriceId: widget.collectrice.id,
        type: 'montant_faible',
        severite: (_montant ?? 0) < 1000 ? 'critique' : 'moyen',
        score: (_montant ?? 0) < 1000 ? 85 : 50,
        description:
            'Montant ${_montant?.toStringAsFixed(0)} FCFA sous le seuil (3000 F)',
      );
    }

    setState(() => _step = 5);
    _successAnim.forward();
    widget.onCollecteComplete?.call();

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) _resetFlow();
  }

  void _resetFlow() {
    _successAnim.reset();
    _montantController.clear();
    _clientNomController.clear();
    _sigCtrl.clear();
    setState(() {
      _step = 0;
      _scannedQr = null;
      _clientNom = null;
      _photoPath = null;
      _montant = null;
    });
    _loadScanCount();
    _getPosition();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF3B3B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _QrScanStep(
          key: const ValueKey('qr'),
          onScanned: _onQrScanned,
          scanCount: _scanCount,
        );
      case 1:
        return _ConfirmClientStep(
          key: const ValueKey('confirm'),
          qrCode: _scannedQr!,
          controller: _clientNomController,
          onConfirmed: _onConfirmed,
          onBack: () => setState(() => _step = 0),
        );
      case 2:
        return _PhotoStep(
          key: const ValueKey('photo'),
          onPhotoTaken: _onPhotoTaken,
          onSkip: () => setState(() => _step = 3),
          isMandatory: _scanCount < 3,
        );
      case 3:
        return _MontantStep(
          key: const ValueKey('montant'),
          controller: _montantController,
          clientNom: _clientNom ?? '',
          onConfirmed: _onMontantConfirmed,
          onBack: () => setState(() => _step = _needsPhoto ? 2 : 1),
        );
      case 4:
        return _SignatureStep(
          key: const ValueKey('signature'),
          sigController: _sigCtrl,
          clientNom: _clientNom ?? '',
          montant: _montant ?? 0,
          onConfirmed: _onSignatureConfirmed,
          onBack: () => setState(() => _step = 3),
        );
      case 5:
        return _SuccessStep(
          key: const ValueKey('success'),
          clientNom: _clientNom ?? '',
          montant: _montant ?? 0,
          animation: _successAnim,
          onNext: _resetFlow,
        );
      default:
        return const SizedBox();
    }
  }
}

// ── QR SCAN ──────────────────────────────────────────────────
class _QrScanStep extends StatefulWidget {
  final Function(String) onScanned;
  final int scanCount;

  const _QrScanStep(
      {super.key, required this.onScanned, required this.scanCount});

  @override
  State<_QrScanStep> createState() => _QrScanStepState();
}

class _QrScanStepState extends State<_QrScanStep> {
  bool _scanned = false;
  final _ctrl = MobileScannerController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Caméra
        MobileScanner(
          controller: _ctrl,
          onDetect: (capture) {
            if (_scanned) return;
            final code = capture.barcodes.first.rawValue;
            if (code != null) {
              _scanned = true;
              widget.onScanned(code);
            }
          },
        ),

        // Overlay sombre
        Container(color: Colors.black45),

        // Viseur
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SCAN #${widget.scanCount + 1}',
                style: const TextStyle(
                  color: Color(0xFF1BD6FF),
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildViseur(),
              const SizedBox(height: 20),
              Text(
                'Pointez le QR code du carnet client',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Bouton mode test
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: TextButton.icon(
              onPressed: () {
                final fakeIds = [
                  'CLIENT-TG-001',
                  'CLIENT-TG-002',
                  'CLIENT-TG-003',
                ];
                final id =
                    fakeIds[DateTime.now().millisecond % fakeIds.length];
                widget.onScanned(id);
              },
              icon: const Icon(Icons.bug_report, color: Colors.white38, size: 16),
              label: const Text(
                'Mode Test — Simuler un scan',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
        ),

        // Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: const Text(
              'SCANNER LE CARNET',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViseur() {
    const size = 220.0;
    const corner = 24.0;
    const thick = 3.0;
    const len = 30.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Coins animés
          for (final alignment in [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight
          ])
            Align(
              alignment: alignment,
              child: SizedBox(
                width: len + corner,
                height: len + corner,
                child: CustomPaint(
                  painter: _CornerPainter(alignment),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Alignment alignment;
  _CornerPainter(this.alignment);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1BD6FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    const len = 30.0;

    if (alignment == Alignment.topLeft) {
      canvas.drawLine(Offset.zero, Offset(len, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, len), paint);
    } else if (alignment == Alignment.topRight) {
      canvas.drawLine(Offset(w, 0), Offset(w - len, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    } else if (alignment == Alignment.bottomLeft) {
      canvas.drawLine(Offset(0, h), Offset(len, h), paint);
      canvas.drawLine(Offset(0, h), Offset(0, h - len), paint);
    } else {
      canvas.drawLine(Offset(w, h), Offset(w - len, h), paint);
      canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── CONFIRM CLIENT ───────────────────────────────────────────
class _ConfirmClientStep extends StatelessWidget {
  final String qrCode;
  final TextEditingController controller;
  final VoidCallback onConfirmed;
  final VoidCallback onBack;

  const _ConfirmClientStep({
    super.key,
    required this.qrCode,
    required this.controller,
    required this.onConfirmed,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      step: 1,
      total: 5,
      title: 'CONFIRMATION CLIENT',
      onBack: onBack,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1BD6FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1BD6FF).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded,
                    color: Color(0xFF1BD6FF), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    qrCode,
                    style: const TextStyle(
                        color: Color(0xFF1BD6FF),
                        fontFamily: 'monospace',
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.check_circle,
                    color: Color(0xFF00E676), size: 18),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nom du client',
              prefixIcon: Icon(Icons.person, color: Color(0xFF1BD6FF)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onConfirmed,
              child: const Text('CONFIRMER ET CONTINUER'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PHOTO STEP ───────────────────────────────────────────────
class _PhotoStep extends StatelessWidget {
  final VoidCallback onPhotoTaken;
  final VoidCallback onSkip;
  final bool isMandatory;

  const _PhotoStep({
    super.key,
    required this.onPhotoTaken,
    required this.onSkip,
    required this.isMandatory,
  });

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      step: 2,
      total: 5,
      title: 'PREUVE PHOTO',
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF9100).withOpacity(0.1),
              border: Border.all(color: const Color(0xFFFF9100).withOpacity(0.4)),
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Color(0xFFFF9100), size: 52),
          ),
          const SizedBox(height: 24),
          Text(
            isMandatory ? 'Photo OBLIGATOIRE' : 'Photo requise',
            style: const TextStyle(
              color: Color(0xFFFF9100),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMandatory
                ? 'Les 3 premiers scans nécessitent une photo de preuve'
                : 'Une vérification photo est demandée pour ce scan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onPhotoTaken,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('PRENDRE LA PHOTO'),
            ),
          ),
          if (!isMandatory) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onSkip,
              child: const Text('Passer', style: TextStyle(color: Colors.white38)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── MONTANT STEP ─────────────────────────────────────────────
class _MontantStep extends StatelessWidget {
  final TextEditingController controller;
  final String clientNom;
  final VoidCallback onConfirmed;
  final VoidCallback onBack;

  const _MontantStep({
    super.key,
    required this.controller,
    required this.clientNom,
    required this.onConfirmed,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      step: 3,
      total: 5,
      title: 'MONTANT COLLECTÉ',
      onBack: onBack,
      child: Column(
        children: [
          Text(
            clientNom,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Montant (FCFA)',
              prefixIcon: Icon(Icons.payments_rounded, color: Color(0xFF00E676)),
            ),
          ),
          const SizedBox(height: 20),
          // Montants rapides
          Wrap(
            spacing: 10,
            children: [2000, 5000, 10000, 15000, 20000]
                .map(
                  (v) => ActionChip(
                    label: Text('${v ~/ 1000}K'),
                    backgroundColor: const Color(0xFF00E676).withOpacity(0.1),
                    side:
                        const BorderSide(color: Color(0xFF00E676), width: 0.5),
                    labelStyle: const TextStyle(color: Color(0xFF00E676)),
                    onPressed: () => controller.text = v.toString(),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onConfirmed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              child: const Text('VALIDER LE MONTANT'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SIGNATURE STEP ───────────────────────────────────────────
class _SignatureStep extends StatelessWidget {
  final SignatureController sigController;
  final String clientNom;
  final double montant;
  final VoidCallback onConfirmed;
  final VoidCallback onBack;

  const _SignatureStep({
    super.key,
    required this.sigController,
    required this.clientNom,
    required this.montant,
    required this.onConfirmed,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    return _StepShell(
      step: 4,
      total: 5,
      title: 'SIGNATURE CLIENT',
      onBack: onBack,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(clientNom,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  '${formatter.format(montant)} FCFA',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Le client signe pour confirmer la collecte',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1BD6FF).withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Signature(
                controller: sigController,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: sigController.clear,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white38),
                label: const Text('Effacer',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onConfirmed,
              child: const Text('FINALISER LA COLLECTE'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SUCCESS STEP ─────────────────────────────────────────────
class _SuccessStep extends StatelessWidget {
  final String clientNom;
  final double montant;
  final AnimationController animation;
  final VoidCallback onNext;

  const _SuccessStep({
    super.key,
    required this.clientNom,
    required this.montant,
    required this.animation,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'fr_FR');

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AnimatedBuilder(
            animation: animation,
            builder: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (_, v, child) => Transform.scale(
                    scale: v,
                    child: child,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E676).withOpacity(0.15),
                      border: Border.all(color: const Color(0xFF00E676), width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Color(0xFF00E676), size: 52),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'COLLECTE VALIDÉE !',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  clientNom,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatter.format(montant)} FCFA',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('HH:mm:ss').format(DateTime.now()),
                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onNext,
                    child: const Text('SCAN SUIVANT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── SHELL COMMUN ─────────────────────────────────────────────
class _StepShell extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final Widget child;
  final VoidCallback? onBack;

  const _StepShell({
    required this.step,
    required this.total,
    required this.title,
    required this.child,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: onBack,
              )
            : null,
        title: Column(
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, letterSpacing: 2)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                total,
                (i) => Container(
                  width: 20,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i < step
                        ? const Color(0xFF1BD6FF)
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}
