import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart'; // For FontFeature
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:holy_word_app/features/bible/services/bible_service.dart';
import 'package:holy_word_app/features/bible/domain/models/verse_layout.dart';

class ShareVerseScreen extends ConsumerStatefulWidget {
  final String verseText;
  final String verseReference;
  final int? bookId;
  final int? chapter;
  final List<int>? verseNumbers;
  final String? parallelText;
  final String? parallelReference;

  const ShareVerseScreen({
    super.key,
    required this.verseText,
    required this.verseReference,
    this.bookId,
    this.chapter,
    this.verseNumbers,
    this.parallelText,
    this.parallelReference,
  });

  @override
  ConsumerState<ShareVerseScreen> createState() => _ShareVerseScreenState();
}

class _ShareVerseScreenState extends ConsumerState<ShareVerseScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    // Pre-populate if enabled? No, wait for user.
  }

  Future<void> _fetchParallelVerses() async {
    // If pre-filled parallel data is available, use it directly (e.g. from Daily Verse)
    if (widget.parallelText != null && widget.parallelReference != null) {
      if (mounted) {
        setState(() {
          _secondaryText = widget.parallelText!;
          _secondaryReference = widget.parallelReference!;
        });
      }
      return;
    }

    if (widget.bookId == null ||
        widget.chapter == null ||
        widget.verseNumbers == null) return;

    final bibleService = ref.read(bibleServiceProvider);
    final result = await bibleService.getParallelVerses(
        widget.bookId!, widget.chapter!, widget.verseNumbers!);

    if (mounted) {
      setState(() {
        _secondaryText = result['text'] ?? '';
        _secondaryReference = result['reference'] ?? '';
        // Initialize positions if needed, or rely on Alignment default
      });
    }
  }

  // Mode Selection
  String _editMode = 'Verse'; // 'Verse' or 'Reference'

  // Global Settings
  double _aspectRatio = 1.0;
  bool _isExporting = false; // To hide UI elements during capture
  bool _showWatermark = true;

  // Background State
  File? _backgroundImage;
  List<Color> _backgroundGradient = [Colors.blue, Colors.purple];
  Color _backgroundColor = Colors.white;
  bool _useImage = false;
  bool _useGradient = true;
  bool _enableTint = true;
  double _tintOpacity = 0.3;
  BoxFit _bgFit = BoxFit.cover; // Default Cover
  bool _isPreviewMode = false;

  // Dual Language State
  bool _showDual = false;
  String _secondaryText = '';
  // Offset _secTextPos = Offset.zero; // Unused, replaced by Alignment

  // Secondary Verse Styling
  String _secFont = 'Mandali';
  double _secTextSize = 18.0;
  Color _secColor = Colors.white;
  TextAlign _secTextAlign = TextAlign.center;
  bool _secBold = false;
  bool _secItalic = false;
  bool _secUnderlined = false;
  double _secLineHeight = 1.5;
  double _secOpacity = 1.0;
  String _secEffect = 'None';
  double _secEffectVal = 0.5;
  Color _secEffectColor = Colors.red;
  Alignment _secAlignment = const Alignment(0.0, 0.2);

  // Secondary Reference State
  String _secondaryReference = '';
  // Offset _secRefPos = Offset.zero; // Unused, replaced by Alignment

  // Secondary Reference Styling
  String _secRefFont = 'Mandali';
  double _secRefSize = 14.0;
  Color _secRefColor = Colors.white70;
  TextAlign _secRefAlign = TextAlign.center;
  bool _secRefBold = false;
  bool _secRefItalic = false;
  bool _secRefUnderlined = false;
  double _secRefOpacity = 1.0;
  double _secRefLineHeight = 1.2;
  String _secRefEffect = 'None';
  double _secRefEffectVal = 0.5;
  Color _secRefEffectColor = Colors.red;
  Alignment _secRefAlignment = const Alignment(0.0, 0.4);

  // Watermark Style
  int _watermarkStyle = 0;

  // Advanced Gradient State
  List<Color> _verseGradientColors = [Colors.blue, Colors.purple];
  Alignment _verseGradientBegin = Alignment.topLeft;
  Alignment _verseGradientEnd = Alignment.bottomRight;

  List<Color> _refGradientColors = [Colors.orange, Colors.red];
  Alignment _refGradientBegin = Alignment.topLeft;
  Alignment _refGradientEnd = Alignment.bottomRight;

  List<Color> _secGradientColors = [Colors.teal, Colors.blueGrey];
  Alignment _secGradientBegin = Alignment.topLeft;
  Alignment _secGradientEnd = Alignment.bottomRight;

  List<Color> _secRefGradientColors = [Colors.teal, Colors.blueGrey];
  Alignment _secRefGradientBegin = Alignment.topLeft;
  Alignment _secRefGradientEnd = Alignment.bottomRight;

  // Verse Styling State
  String _verseFont = 'Inter';
  double _verseTextSize = 24.0;
  Color _verseColor = Colors.white;
  TextAlign _verseAlign = TextAlign.center;
  bool _isVerseDynamic = true;
  bool _isBold = true; // Default Bold
  bool _isItalic = false;
  bool _isUnderlined = false;
  bool _hasShadow = true; // Default Shadow
  double _textWidthFactor = 0.85; // Default 85% width
  double _verseLineHeight = 1.2;
  double _verseOpacity = 1.0;
  String _verseEffect = 'None'; // None, Gradient, 3D, Glow, Gold
  double _verseEffectVal = 0.5; // Intensity/Depth
  Color _verseEffectColor = Colors.black; // Shadow/Glow Color

  // Multi-Style State
  LayoutStrategy _layoutStrategy = LayoutStrategy.uniform;
  List<Color> _multiColors = [];
  List<double> _multiSizes = [];

  // Reference Styling State
  String _refFont = 'Inter';
  double _refTextSize = 16.0;
  Color _refColor = Colors.white70;
  TextAlign _refAlign = TextAlign.center;
  bool _refBold = true;
  bool _refItalic = false;
  double _refLineHeight = 1.2;
  double _refOpacity = 1.0;
  String _refEffect = 'None';
  double _refEffectVal = 0.5;
  Color _refEffectColor = Colors.black;

  // New: Stroke / Outline
  Color? _verseStrokeColor;
  double _verseStrokeWidth = 0.0;

  // New: Reference Text Pill
  Color? _refBackgroundColor;
  double _refBorderRadius = 0.0;

  // Font Map (Internal Name -> TextStyle Generator)
  final Map<
      String,
      TextStyle Function(
          {TextStyle? textStyle,
          Color? color,
          Color? backgroundColor,
          double? fontSize,
          FontWeight? fontWeight,
          FontStyle? fontStyle,
          double? letterSpacing,
          double? wordSpacing,
          TextBaseline? textBaseline,
          double? height,
          Locale? locale,
          Paint? foreground,
          Paint? background,
          List<Shadow>? shadows,
          List<FontFeature>? fontFeatures,
          TextDecoration? decoration,
          Color? decorationColor,
          TextDecorationStyle? decorationStyle,
          double? decorationThickness})> _fonts = {
    'Inter': GoogleFonts.inter,
    'Roboto': GoogleFonts.roboto,
    'Lato': GoogleFonts.lato,
    'Merriweather': GoogleFonts.merriweather,
    'Playfair': GoogleFonts.playfairDisplay,
    'Chathura': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Chathura',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Annamayya': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Annamayya',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Dhurjati': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Dhurjati',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Gidugu': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Gidugu',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Gurajada': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Gurajada',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Jims': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Jims',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Kanakadurga': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Kanakadurga',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'LakkiReddy': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'LakkiReddy',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Mallanna': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Mallanna',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Mandali': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Mandali',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Nandakam': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Nandakam',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'NATS': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'NATS',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'NTR': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'NTR',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Peddana': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Peddana',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Potti Sreeramulu': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Potti Sreeramulu',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Purushothamaa': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Purushothamaa',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Ramabhadra': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Ramabhadra',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Ramaneeyawin': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Ramaneeyawin',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'RaviPrakash': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'RaviPrakash',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Seelaveerraju': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Seelaveerraju',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'SPBalasubrahmanyam': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'SPBalasubrahmanyam',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Sree Krushnadevaraya': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Sree Krushnadevaraya',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Suranna': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Suranna',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Suravaram': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Suravaram',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
    'Syamala Ramana': (
            {textStyle,
            color,
            fontSize,
            fontWeight,
            fontStyle,
            letterSpacing,
            wordSpacing,
            textBaseline,
            height,
            locale,
            foreground,
            background,
            shadows,
            fontFeatures,
            decoration,
            decorationColor,
            decorationStyle,
            decorationThickness,
            backgroundColor}) =>
        TextStyle(
            fontFamily: 'Syamala Ramana',
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height),
  };

  // Font Display Name Map
  final Map<String, String> _fontDisplayNames = {
    'Inter': 'Inter',
    'Roboto': 'Roboto',
    'Lato': 'Lato',
    'Merriweather': 'Merriweather',
    'Playfair': 'Playfair',
    'Annamayya': 'అన్నమయ్య',
    'Chathura': 'చతుర',
    'Dhurjati': 'ధూర్జటి',
    'Gidugu': 'గిడుగు',
    'Gurajada': 'గురజాడ',
    'Jims': 'జిమ్స్',
    'Kanakadurga': 'కనకదుర్గ',
    'LakkiReddy': 'లక్కిరెడ్డి',
    'Mallanna': 'మల్లన్న',
    'Mandali': 'మండలి',
    'Nandakam': 'నందకం',
    'NATS': 'నాట్స్',
    'NTR': 'ఎన్టీఆర్',
    'Peddana': 'పెద్దన',
    'Potti Sreeramulu': 'పొట్టి శ్రీరాములు',
    'Purushothamaa': 'పురుషోత్తమ',
    'Ramabhadra': 'రామభద్ర',
    'Ramaneeyawin': 'రామణీయం',
    'RaviPrakash': 'రవిప్రకాష్',
    'Seelaveerraju': 'శీలవీర్రాజు',
    'SPBalasubrahmanyam': 'ఎస్.పి.బాలసుబ్రహ్మణ్యం',
    'Sree Krushnadevaraya': 'శ్రీ కృష్ణదేవరాయ',
    'Suranna': 'సూరన',
    'Suravaram': 'సురవaram',
    'Syamala Ramana': 'శ్యామల రమణ',
  };

  // Dragging State (Alignment based for responsiveness)
  Alignment _verseAlignment = const Alignment(0.0, -0.2); // Center-Top
  Alignment _refAlignment = const Alignment(0.0, 0.5); // Center-Bottom

  // Background Presets
  final List<List<Color>> _gradients = [
    [Colors.blue, Colors.purple],
    [Colors.orange, Colors.red],
    [Colors.teal, Colors.blueGrey],
    [Colors.black, Colors.grey],
    [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
    [const Color(0xFF134E5E), const Color(0xFF71B280)],
    [const Color(0xFFDA4453), const Color(0xFF89216B)],
    [const Color(0xFF654ea3), const Color(0xFFeaafc8)],
  ];

  final List<Color> _solidColors = [
    Colors.black,
    Colors.white,
    Colors.grey,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.brown
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Share Verse", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.close : Icons.visibility),
            onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
            tooltip: _isPreviewMode ? "Close Preview" : "Preview",
          ),
          if (!_isPreviewMode)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareImage,
              tooltip: "Share",
            )
        ],
      ),
      body: _isPreviewMode
          ? Stack(
              children: [
                Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: AspectRatio(
                      aspectRatio: _aspectRatio,
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          gradient: _useGradient && !_useImage
                              ? LinearGradient(
                                  colors: _backgroundGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: LayoutBuilder(builder: (context, constraints) {
                          return Stack(
                            children: [
                              // Background Image Logic
                              if (_useImage && _backgroundImage != null) ...[
                                // Blur Layer for "Fit" mode
                                if (_bgFit == BoxFit.contain)
                                  SizedBox.expand(
                                    child: Image.file(
                                      _backgroundImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                if (_bgFit == BoxFit.contain)
                                  BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                        color: Colors.black.withOpacity(0.3)),
                                  ),
                                // Main Image
                                Image.file(_backgroundImage!,
                                    fit: _bgFit,
                                    width: double.infinity,
                                    height: double.infinity),
                              ],
                              if (_useImage && _enableTint)
                                Container(
                                    color:
                                        Colors.black.withOpacity(_tintOpacity)),

                              // Draggable Verse Text
                              Align(
                                alignment: _verseAlignment,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      final dx = details.delta.dx /
                                          (constraints.maxWidth / 2);
                                      final dy = details.delta.dy /
                                          (constraints.maxHeight / 2);

                                      _verseAlignment += Alignment(dx, dy);
                                    });
                                  },
                                  onTap: () =>
                                      setState(() => _editMode = 'Verse'),
                                  child: Container(
                                    width:
                                        constraints.maxWidth * _textWidthFactor,
                                    padding: const EdgeInsets.all(12),
                                    // Hide border in preview
                                    decoration: null,
                                    child: _applyTextEffect(
                                      _verseEffect,
                                      _buildStyledVerseText(widget.verseText),
                                      gradientColors: _verseGradientColors,
                                      begin: _verseGradientBegin,
                                      end: _verseGradientEnd,
                                      goldTint: _verseEffectColor,
                                    ),
                                  ),
                                ),
                              ),

                              // Draggable Reference
                              Align(
                                alignment: _refAlignment,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      final dx = details.delta.dx /
                                          (constraints.maxWidth / 2);
                                      final dy = details.delta.dy /
                                          (constraints.maxHeight / 2);
                                      _refAlignment += Alignment(dx, dy);
                                    });
                                  },
                                  onTap: () =>
                                      setState(() => _editMode = 'Reference'),
                                  child: Container(
                                    constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth * 0.8),
                                    padding: const EdgeInsets.all(8),
                                    // Hide border in preview
                                    decoration: null,
                                    child: _applyTextEffect(
                                      _refEffect,
                                      gradientColors: _refGradientColors,
                                      begin: _refGradientBegin,
                                      end: _refGradientEnd,
                                      goldTint: _refEffectColor,
                                      Container(
                                        padding: _refBackgroundColor != null
                                            ? const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8)
                                            : EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          color: _refBackgroundColor,
                                          borderRadius: BorderRadius.circular(
                                              _refBorderRadius),
                                        ),
                                        child: Text(
                                          widget.verseReference,
                                          textAlign: _refAlign,
                                          style: _getFont(
                                            _refFont,
                                            _refTextSize,
                                            _refEffect == 'Gradient' ||
                                                    _refEffect == 'Gold'
                                                ? Colors.white
                                                : _refColor
                                                    .withOpacity(_refOpacity),
                                            _refBold
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ).copyWith(
                                            height: _refLineHeight,
                                            fontStyle: _refItalic
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                            shadows: _getEffectShadows(
                                                _refEffect,
                                                _hasShadow,
                                                _refEffectVal,
                                                _refEffectColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Watermark
                              if (_showWatermark)
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(8),
                                        bottomLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                      border: Border.all(
                                          color: Colors.white24, width: 0.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/logo.png',
                                          width: 16,
                                          height: 16,
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          "Holy Word App",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        // Allow scrolling if screen is small
                        child: Screenshot(
                          controller: _screenshotController,
                          child: AspectRatio(
                            aspectRatio: _aspectRatio,
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: _backgroundColor,
                                gradient: _useGradient && !_useImage
                                    ? LinearGradient(
                                        colors: _backgroundGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                image: _useImage && _backgroundImage != null
                                    ? DecorationImage(
                                        image: FileImage(_backgroundImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              // Use LayoutBuilder to get the EXACT size of the export area
                              child: LayoutBuilder(
                                  builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    if (_useImage)
                                      Image.file(_backgroundImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity),
                                    if (_useImage && _enableTint)
                                      Container(
                                          color: Colors.black
                                              .withOpacity(_tintOpacity)),

                                    // Draggable Verse Text
                                    Align(
                                      alignment: _verseAlignment,
                                      child: GestureDetector(
                                        // Clamp movement to bounds
                                        onPanUpdate: (details) {
                                          setState(() {
                                            // Convert drag pixels to alignment units (-1 to 1)
                                            // Alignment 1 unit = Half Width/Height
                                            final dx = details.delta.dx /
                                                (constraints.maxWidth / 2);
                                            final dy = details.delta.dy /
                                                (constraints.maxHeight / 2);

                                            _verseAlignment +=
                                                Alignment(dx, dy);
                                          });
                                        },
                                        onTap: () =>
                                            setState(() => _editMode = 'Verse'),
                                        child: Container(
                                          // Constrain width to ensure it doesn't touch edges
                                          width: constraints.maxWidth *
                                              _textWidthFactor,
                                          padding: const EdgeInsets.all(12),
                                          decoration: (_editMode == 'Verse' &&
                                                  !_isExporting)
                                              ? BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.orange,
                                                      width: 1.5),
                                                  borderRadius:
                                                      BorderRadius.circular(4))
                                              : null,
                                          child: _applyTextEffect(
                                            _verseEffect,
                                            gradientColors:
                                                _verseGradientColors,
                                            begin: _verseGradientBegin,
                                            end: _verseGradientEnd,
                                            goldTint: _verseEffectColor,
                                            _isVerseDynamic
                                                ? AutoSizeText(
                                                    widget.verseText,
                                                    textAlign: _verseAlign,
                                                    style: _getFont(
                                                      _verseFont,
                                                      _verseTextSize,
                                                      _verseEffect ==
                                                                  'Gradient' ||
                                                              _verseEffect ==
                                                                  'Gold'
                                                          ? Colors.white
                                                          : _verseColor.withOpacity(
                                                              _verseOpacity), // Force white for gradient
                                                      _isBold
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ).copyWith(
                                                      height: _verseLineHeight,
                                                      fontStyle: _isItalic
                                                          ? FontStyle.italic
                                                          : FontStyle.normal,
                                                      decoration: _isUnderlined
                                                          ? TextDecoration
                                                              .underline
                                                          : TextDecoration.none,
                                                      shadows: _getEffectShadows(
                                                          _verseEffect,
                                                          _hasShadow,
                                                          _verseEffectVal,
                                                          _verseEffectColor),
                                                    ),
                                                    minFontSize: 14,
                                                    maxLines:
                                                        15, // Allow plenty of lines
                                                    stepGranularity: 1,
                                                    wrapWords: true,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  )
                                                : Text(
                                                    widget.verseText,
                                                    textAlign: _verseAlign,
                                                    style: _getFont(
                                                      _verseFont,
                                                      _verseTextSize,
                                                      _verseEffect ==
                                                                  'Gradient' ||
                                                              _verseEffect ==
                                                                  'Gold'
                                                          ? Colors.white
                                                          : _verseColor
                                                              .withOpacity(
                                                                  _verseOpacity),
                                                      _isBold
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ).copyWith(
                                                      height: _verseLineHeight,
                                                      fontStyle: _isItalic
                                                          ? FontStyle.italic
                                                          : FontStyle.normal,
                                                      decoration: _isUnderlined
                                                          ? TextDecoration
                                                              .underline
                                                          : TextDecoration.none,
                                                      shadows: _getEffectShadows(
                                                          _verseEffect,
                                                          _hasShadow,
                                                          _verseEffectVal,
                                                          _verseEffectColor),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Draggable Reference
                                    Align(
                                      alignment: _refAlignment,
                                      child: GestureDetector(
                                        onPanUpdate: (details) {
                                          setState(() {
                                            final dx = details.delta.dx /
                                                (constraints.maxWidth / 2);
                                            final dy = details.delta.dy /
                                                (constraints.maxHeight / 2);
                                            _refAlignment += Alignment(dx, dy);
                                          });
                                        },
                                        onTap: () => setState(
                                            () => _editMode = 'Reference'),
                                        child: Container(
                                          // Reference shouldn't be too wide either
                                          constraints: BoxConstraints(
                                              maxWidth:
                                                  constraints.maxWidth * 0.8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: (_editMode ==
                                                      'Reference' &&
                                                  !_isExporting)
                                              ? BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.orange,
                                                      width: 1.5),
                                                  borderRadius:
                                                      BorderRadius.circular(4))
                                              : null,
                                          child: _applyTextEffect(
                                            _refEffect,
                                            gradientColors: _refGradientColors,
                                            begin: _refGradientBegin,
                                            end: _refGradientEnd,
                                            goldTint: _refEffectColor,
                                            Container(
                                              padding: _refBackgroundColor !=
                                                      null
                                                  ? const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8)
                                                  : EdgeInsets.zero,
                                              decoration: BoxDecoration(
                                                color: _refBackgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        _refBorderRadius),
                                              ),
                                              child: Text(
                                                widget.verseReference,
                                                textAlign: _refAlign,
                                                style: _getFont(
                                                  _refFont,
                                                  _refTextSize,
                                                  _refEffect == 'Gradient' ||
                                                          _refEffect == 'Gold'
                                                      ? Colors.white
                                                      : _refColor.withOpacity(
                                                          _refOpacity),
                                                  _refBold
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ).copyWith(
                                                  height: _refLineHeight,
                                                  fontStyle: _refItalic
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                                  shadows: _getEffectShadows(
                                                      _refEffect,
                                                      _hasShadow,
                                                      _refEffectVal,
                                                      _refEffectColor),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Draggable Secondary Text (Dual Language)
                                    if (_showDual && _secondaryText.isNotEmpty)
                                      Align(
                                        alignment: _secAlignment,
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              final dx = details.delta.dx /
                                                  (constraints.maxWidth / 2);
                                              final dy = details.delta.dy /
                                                  (constraints.maxHeight / 2);
                                              _secAlignment +=
                                                  Alignment(dx, dy);
                                            });
                                          },
                                          onTap: () => setState(
                                              () => _editMode = 'Dual Verse'),
                                          child: Container(
                                            width: constraints.maxWidth *
                                                _textWidthFactor,
                                            padding: const EdgeInsets.all(12),
                                            // Hide border in preview
                                            decoration: (_editMode ==
                                                        'Dual Verse' &&
                                                    !_isExporting)
                                                ? BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.orange,
                                                        width: 1.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4))
                                                : null,
                                            child: _applyTextEffect(
                                              _secEffect,
                                              gradientColors:
                                                  _secGradientColors,
                                              begin: _secGradientBegin,
                                              end: _secGradientEnd,
                                              goldTint: _secEffectColor,
                                              AutoSizeText(
                                                _secondaryText,
                                                textAlign: _secTextAlign,
                                                style: _getFont(
                                                  _secFont,
                                                  _secTextSize,
                                                  _secEffect == 'Gradient' ||
                                                          _secEffect == 'Gold'
                                                      ? Colors.white
                                                      : _secColor.withOpacity(
                                                          _secOpacity),
                                                  _secBold
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ).copyWith(
                                                  height: _secLineHeight,
                                                  fontStyle: _secItalic
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                                  decoration: _secUnderlined
                                                      ? TextDecoration.underline
                                                      : TextDecoration.none,
                                                  shadows: _getEffectShadows(
                                                      _secEffect,
                                                      _hasShadow,
                                                      _secEffectVal,
                                                      _secEffectColor),
                                                ),
                                                minFontSize: 12,
                                                maxLines: 15,
                                                stepGranularity: 1,
                                                wrapWords: true,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Secondary Reference
                                    if (_showDual &&
                                        _secondaryReference.isNotEmpty)
                                      Align(
                                        alignment: _secRefAlignment,
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              final dx = details.delta.dx /
                                                  (constraints.maxWidth / 2);
                                              final dy = details.delta.dy /
                                                  (constraints.maxHeight / 2);
                                              _secRefAlignment +=
                                                  Alignment(dx, dy);
                                            });
                                          },
                                          onTap: () => setState(
                                              () => _editMode = 'Dual Ref'),
                                          child: Container(
                                            constraints: BoxConstraints(
                                                maxWidth:
                                                    constraints.maxWidth * 0.8),
                                            padding: const EdgeInsets.all(8),
                                            decoration: (_editMode ==
                                                        'Dual Ref' &&
                                                    !_isExporting)
                                                ? BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.orange,
                                                        width: 1.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4))
                                                : null,
                                            child: _applyTextEffect(
                                              _secRefEffect,
                                              gradientColors:
                                                  _secRefGradientColors,
                                              begin: _secRefGradientBegin,
                                              end: _secRefGradientEnd,
                                              goldTint: _secRefEffectColor,
                                              Text(
                                                _secondaryReference,
                                                textAlign: _secRefAlign,
                                                style: _getFont(
                                                  _secRefFont,
                                                  _secRefSize,
                                                  _secRefEffect == 'Gradient' ||
                                                          _secRefEffect ==
                                                              'Gold'
                                                      ? Colors.white
                                                      : _secRefColor
                                                          .withOpacity(
                                                              _secRefOpacity),
                                                  _secRefBold
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ).copyWith(
                                                  height: _secRefLineHeight,
                                                  fontStyle: _secRefItalic
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                                  shadows: _getEffectShadows(
                                                      _secRefEffect,
                                                      _hasShadow,
                                                      _secRefEffectVal,
                                                      _secRefEffectColor),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Watermark (Styled Badge)
                                    if (_showWatermark)
                                      if (_watermarkStyle ==
                                          3) // Overlay Corner
                                        Positioned(
                                          top: 20,
                                          right: 20,
                                          child: Text(
                                            "Holy Word App",
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  const Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 4)
                                                ]),
                                          ),
                                        )
                                      else
                                        Positioned(
                                          bottom: 12,
                                          right: 12,
                                          child: Container(
                                            padding: _watermarkStyle == 1 ||
                                                    _watermarkStyle == 2
                                                ? EdgeInsets.zero
                                                : const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                            decoration: _watermarkStyle == 1 ||
                                                    _watermarkStyle == 2
                                                ? null
                                                : BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_watermarkStyle == 0 ||
                                                    _watermarkStyle == 2)
                                                  // App Logo
                                                  Image.asset(
                                                    'assets/images/logo.png',
                                                    width: _watermarkStyle == 2
                                                        ? 40
                                                        : 24, // Bigger logic
                                                    height: _watermarkStyle == 2
                                                        ? 40
                                                        : 24,
                                                    fit: BoxFit.contain,
                                                  ),
                                                if (_watermarkStyle == 0)
                                                  const SizedBox(width: 6),
                                                if (_watermarkStyle == 0 ||
                                                    _watermarkStyle == 1)
                                                  // App Name
                                                  const Text(
                                                    "Holy Word App",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  color: Colors.grey[900],
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.black,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSelectorButton("Verse", Icons.format_quote),
                              _buildSelectorButton("Reference", Icons.bookmark),
                              _buildSelectorButton(
                                  "Dual Verse", Icons.translate),
                              _buildSelectorButton(
                                  "Dual Ref", Icons.bookmark_add_outlined),
                              _buildSelectorButton(
                                  "Layouts", Icons.auto_awesome),
                              _buildSelectorButton("BG", Icons.image),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(12),
                        child: _buildActiveControls(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSelectorButton(String mode, IconData icon) {
    bool isActive = _editMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _editMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.black : Colors.grey),
            const SizedBox(width: 6),
            Text(mode,
                style: TextStyle(
                    color: isActive ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildWatermarkStyleBtn(int style, IconData icon) {
    bool isSelected = _watermarkStyle == style;
    return GestureDetector(
      onTap: () => setState(() => _watermarkStyle = style),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16, color: isSelected ? Colors.black : Colors.grey),
      ),
    );
  }

  Widget _buildActiveControls() {
    if (_editMode == 'BG') return _buildBackgroundControls();
    if (_editMode == 'Layouts') return _buildLayoutControls();
    return _buildTextControls();
  }

  Widget _buildBackgroundControls() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRatioButton("1:1", 1.0, Icons.square_outlined),
              _buildRatioButton("4:5", 0.8, Icons.portrait),
              _buildRatioButton("9:16", 0.56, Icons.smartphone),
              _buildRatioButton("16:9", 1.77, Icons.landscape),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Fit Toggle
        if (_useImage)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Image Fit: ", style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 10),
              ToggleButtons(
                isSelected: [_bgFit == BoxFit.cover, _bgFit == BoxFit.contain],
                onPressed: (index) {
                  setState(() {
                    _bgFit = index == 0 ? BoxFit.cover : BoxFit.contain;
                  });
                },
                color: Colors.grey,
                selectedColor: Colors.orange,
                fillColor: Colors.white10,
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("Fill")),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("Fit")),
                ],
              ),
            ],
          ),
        const SizedBox(height: 10),

        // Tint Controls
        Row(
          children: [
            Checkbox(
                value: _enableTint,
                activeColor: Colors.orange,
                onChanged: (v) => setState(() => _enableTint = v ?? false)),
            const Text("Dark Tint", style: TextStyle(color: Colors.white)),
            if (_enableTint)
              Expanded(
                child: Slider(
                  value: _tintOpacity,
                  min: 0.0,
                  max: 0.9,
                  activeColor: Colors.white70,
                  onChanged: (v) => setState(() => _tintOpacity = v),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Checkbox(
                value: _showWatermark,
                activeColor: Colors.orange,
                onChanged: (v) => setState(() => _showWatermark = v ?? true)),
            const Text("Watermark", style: TextStyle(color: Colors.white)),
            if (_showWatermark) ...[
              const SizedBox(width: 16),
              // Watermark Style Selector
              Container(
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWatermarkStyleBtn(0, Icons.verified), // Badge
                    _buildWatermarkStyleBtn(1, Icons.text_fields), // Text
                    _buildWatermarkStyleBtn(2, Icons.image), // Logo
                    _buildWatermarkStyleBtn(3, Icons.call_made), // Overlay
                  ],
                ),
              ),
            ],
          ],
        ),

        const Divider(color: Colors.white24),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildOptionButton(
                  icon: Icons.add_photo_alternate,
                  label: "Gallery",
                  onTap: _pickImage),
              const VerticalDivider(color: Colors.grey),
              ..._gradients.map((g) => GestureDetector(
                    onTap: () => setState(() {
                      _useGradient = true;
                      _useImage = false;
                      _backgroundGradient = g;
                    }),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: g),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )),
              ..._solidColors.map((c) => GestureDetector(
                    onTap: () => setState(() {
                      _useGradient = false;
                      _useImage = false;
                      _backgroundColor = c;
                    }),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                          color: c, borderRadius: BorderRadius.circular(8)),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatioButton(String label, double ratio, IconData icon) {
    bool isSelected = _aspectRatio == ratio;
    return GestureDetector(
      onTap: () => setState(() => _aspectRatio = ratio),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.orange.withOpacity(0.2) : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.orange : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style:
                    TextStyle(color: isSelected ? Colors.orange : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextControls() {
    // Map variables based on mode
    bool isVerse = _editMode == 'Verse';
    bool isDual = _editMode == 'Dual Verse';
    bool isDualRef = _editMode == 'Dual Ref';
    // bool isRef = !isVerse && !isDual && !isDualRef; // 'Reference' (Implicit else)

    // If Dual Mode is selected but not enabled, show toggle only
    if ((isDual || isDualRef) && !_showDual) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Enable Dual Language",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Switch(
                value: _showDual,
                activeColor: Colors.orange,
                onChanged: (val) {
                  setState(() {
                    _showDual = val;
                    if (val && _secondaryText.isEmpty) {
                      _fetchParallelVerses();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    // Determine current values based on mode
    String currentFont;
    Color currentColor;
    double currentSize;
    String currentEffect;
    double currentEffectVal;
    Color currentEffectColor;
    // TextAlign currentAlign;
    bool isBold;
    bool isItalic;
    bool isUnderlined;
    double currentLineHeight;
    double currentOpacity;

    if (isVerse) {
      currentFont = _verseFont;
      currentColor = _verseColor;
      currentSize = _verseTextSize;
      currentEffect = _verseEffect;
      currentEffectVal = _verseEffectVal;
      currentEffectColor = _verseEffectColor;
      // currentAlign = _verseAlign;
      isBold = _isBold;
      isItalic = _isItalic;
      isUnderlined = _isUnderlined;
      currentLineHeight = _verseLineHeight;
      currentOpacity = _verseOpacity;
    } else if (isDual) {
      currentFont = _secFont;
      currentColor = _secColor;
      currentSize = _secTextSize;
      currentEffect = _secEffect;
      currentEffectVal = _secEffectVal;
      currentEffectColor = _secEffectColor;
      // currentAlign = _secTextAlign; // Mapped state var
      isBold = _secBold;
      isItalic = _secItalic;
      isUnderlined = _secUnderlined;
      currentLineHeight = _secLineHeight;
      currentOpacity = _secOpacity;
    } else if (isDualRef) {
      currentFont = _secRefFont;
      currentColor = _secRefColor;
      currentSize = _secRefSize;
      currentEffect = _secRefEffect;
      currentEffectVal = _secRefEffectVal;
      currentEffectColor = _secRefEffectColor;
      // currentAlign = _secRefAlign;
      isBold = _secRefBold;
      isItalic = _secRefItalic;
      isUnderlined = _secRefUnderlined;
      currentLineHeight = _secRefLineHeight;
      currentOpacity = _secRefOpacity;
    } else {
      // Reference
      currentFont = _refFont;
      currentColor = _refColor;
      currentSize = _refTextSize;
      currentEffect = _refEffect;
      currentEffectVal = _refEffectVal;
      currentEffectColor = _refEffectColor;
      // currentAlign = _refAlign;
      isBold = _refBold;
      isItalic = _refItalic;
      isUnderlined = false; // Not supported for ref yet
      currentLineHeight = _refLineHeight;
      currentOpacity = _refOpacity;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // If Dual, show toggle at top to disable
          if (isDual || isDualRef)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Dual Language",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Switch(
                  value: _showDual,
                  activeColor: Colors.orange,
                  onChanged: (val) => setState(() => _showDual = val),
                ),
              ],
            ),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showFontPicker(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fontDisplayNames[currentFont] ?? currentFont,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _showColorPicker,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Effect Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildEffectOption("None", Icons.cancel),
                _buildEffectOption("Gradient", Icons.gradient),
                _buildEffectOption("3D", Icons.layers),
                _buildEffectOption("Glow", Icons.blur_on),
                _buildEffectOption("Gold", Icons.monetization_on),
              ],
            ),
          ),

          // Effect Customization (Intensity & Color)
          if (currentEffect != 'None')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  if (currentEffect == 'Gradient')
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.palette, size: 16),
                        label: const Text("Customize Gradient"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _showGradientCustomizationDialog,
                      ),
                    )
                  else if (currentEffect == 'Gold')
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.colorize, size: 16),
                        label: const Text("Gold Base Color"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _showEffectColorPicker,
                      ),
                    )
                  else ...[
                    InkWell(
                      onTap: () => _showEffectColorPicker(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: currentEffectColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Slider(
                        value: currentEffectVal,
                        min: 0.0,
                        max: 1.0,
                        activeColor: Colors.orangeAccent,
                        onChanged: (v) => setState(() {
                          if (isVerse)
                            _verseEffectVal = v;
                          else if (isDual)
                            _secEffectVal = v;
                          else if (isDualRef)
                            _secRefEffectVal = v;
                          else
                            _refEffectVal = v;
                        }),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Alignment & AutoSize
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildAlignBtn(TextAlign.left, Icons.format_align_left),
                  _buildAlignBtn(TextAlign.center, Icons.format_align_center),
                  _buildAlignBtn(TextAlign.right, Icons.format_align_right),
                ],
              ),
              if (isVerse)
                Row(
                  children: [
                    const Text("Auto Size",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Switch(
                      value: _isVerseDynamic,
                      activeColor: Colors.orange,
                      onChanged: (val) => setState(() => _isVerseDynamic = val),
                    ),
                  ],
                ),
            ],
          ),

          // Text Size Slider
          if (!isVerse || !_isVerseDynamic)
            Row(
              children: [
                const Icon(Icons.text_fields, size: 16, color: Colors.grey),
                Expanded(
                  child: Slider(
                    value: currentSize,
                    min: 8,
                    max: 80,
                    activeColor: Colors.orange,
                    onChanged: (val) {
                      setState(() {
                        if (isVerse)
                          _verseTextSize = val;
                        else if (isDual)
                          _secTextSize = val;
                        else if (isDualRef)
                          _secRefSize = val;
                        else
                          _refTextSize = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),

          // Style Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStyleToggle(
                  Icons.format_bold,
                  isBold,
                  (v) => setState(() {
                        if (isVerse)
                          _isBold = v;
                        else if (isDual)
                          _secBold = v;
                        else if (isDualRef)
                          _secRefBold = v;
                        else
                          _refBold = v;
                      })),
              _buildStyleToggle(
                  Icons.format_italic,
                  isItalic,
                  (v) => setState(() {
                        if (isVerse)
                          _isItalic = v;
                        else if (isDual)
                          _secItalic = v;
                        else if (isDualRef)
                          _secRefItalic = v;
                        else
                          _refItalic = v;
                      })),
              if (isVerse || isDual || isDualRef)
                _buildStyleToggle(
                    Icons.format_underlined,
                    isUnderlined,
                    (v) => setState(() {
                          if (isVerse)
                            _isUnderlined = v;
                          else if (isDual)
                            _secUnderlined = v;
                          else if (isDualRef) _secRefUnderlined = v;
                        })),
              _buildStyleToggle(
                  Icons.text_format, // Shadow
                  _hasShadow,
                  (v) => setState(() => _hasShadow = v),
                  tooltip: "Shadow"),
            ],
          ),
          const SizedBox(height: 8),

          // Width Slider (Verse & Dual)
          if (isVerse || isDual || isDualRef)
            Row(
              children: [
                const Icon(Icons.compare_arrows, size: 16, color: Colors.grey),
                Expanded(
                  child: Slider(
                    value: _textWidthFactor,
                    min: 0.5,
                    max: 1.0,
                    activeColor: Colors.orange,
                    label: "Width",
                    onChanged: (val) => setState(() => _textWidthFactor = val),
                  ),
                ),
                const Text("Width",
                    style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          const SizedBox(height: 8),

          // Deep Control Sliders (Height, Opacity)
          _buildSliderControl(
              icon: Icons.format_line_spacing,
              label: "Line Height",
              value: currentLineHeight,
              min: 0.8,
              max: 2.5,
              onChanged: (v) => setState(() {
                    if (isVerse)
                      _verseLineHeight = v;
                    else if (isDual)
                      _secLineHeight = v;
                    else if (isDualRef)
                      _secRefLineHeight = v;
                    else
                      _refLineHeight = v;
                  })),
          _buildSliderControl(
              icon: Icons.opacity,
              label: "Opacity",
              value: currentOpacity,
              min: 0.1,
              max: 1.0,
              onChanged: (v) => setState(() {
                    if (isVerse)
                      _verseOpacity = v;
                    else if (isDual)
                      _secOpacity = v;
                    else if (isDualRef)
                      _secRefOpacity = v;
                    else
                      _refOpacity = v;
                  })),
        ],
      ),
    );
  }

  Widget _buildAlignBtn(TextAlign align, IconData icon) {
    TextAlign current;
    if (_editMode == 'Verse') {
      current = _verseAlign;
    } else if (_editMode == 'Dual') {
      current = _secTextAlign;
    } else {
      current = _refAlign;
    }

    bool isSelected = current == align;

    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.orange : Colors.grey),
      onPressed: () {
        setState(() {
          if (_editMode == 'Verse') {
            _verseAlign = align;
          } else if (_editMode == 'Dual') {
            _secTextAlign = align;
          } else {
            _refAlign = align;
          }
        });
      },
    );
  }

  void _showFontPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (_) => Container(
        height: 300,
        child: ListView.builder(
          itemCount: _fonts.keys.length,
          itemBuilder: (ctx, i) {
            String fontKey = _fonts.keys.elementAt(i);
            String displayName = _fontDisplayNames[fontKey] ?? fontKey;

            // Use the font itself to display its name
            TextStyle func =
                _fonts[fontKey]!(fontSize: 18, color: Colors.white);

            return ListTile(
              title: Text(displayName, style: func),
              onTap: () {
                setState(() {
                  if (_editMode == 'Verse') {
                    _verseFont = fontKey;
                  } else if (_editMode == 'Dual') {
                    _secFont = fontKey;
                  } else {
                    _refFont = fontKey;
                  }
                });
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _editMode == 'Verse'
                ? _verseColor
                : (_editMode == 'Dual' ? _secColor : _refColor),
            onColorChanged: (c) => setState(() {
              if (_editMode == 'Verse') {
                _verseColor = c;
              } else if (_editMode == 'Dual') {
                _secColor = c;
              } else {
                _refColor = c;
              }
            }),
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Text('Done'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showEffectColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Effect Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _editMode == 'Verse'
                ? _verseEffectColor
                : (_editMode == 'Dual' ? _secEffectColor : _refEffectColor),
            onColorChanged: (c) => setState(() {
              if (_editMode == 'Verse') {
                _verseEffectColor = c;
              } else if (_editMode == 'Dual Verse') {
                _secEffectColor = c;
              } else if (_editMode == 'Dual Ref') {
                _secRefEffectColor = c;
              } else {
                _refEffectColor = c;
              }
            }),
          ),
        ),
        actions: [
          ElevatedButton(
            child: const Text('Done'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  TextStyle _getFont(
      String fontName, double size, Color color, FontWeight weight) {
    final func = _fonts[fontName] ?? GoogleFonts.inter;
    return func(fontSize: size, color: color, fontWeight: weight);
  }

  Widget _buildOptionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
            color: Colors.white10, borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleToggle(
      IconData icon, bool isActive, Function(bool) onChanged,
      {String? tooltip}) {
    return GestureDetector(
      onTap: () => onChanged(!isActive),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isActive ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _buildSliderControl(
      {required IconData icon,
      required String label,
      required double value,
      required double min,
      required double max,
      required Function(double) onChanged}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.orange,
            label: label,
            onChanged: onChanged,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildEffectOption(String effect, IconData icon) {
    String current;
    if (_editMode == 'Verse') {
      current = _verseEffect;
    } else if (_editMode == 'Dual') {
      current = _secEffect;
    } else if (_editMode == 'Dual Ref') {
      current = _secRefEffect;
    } else {
      current = _refEffect;
    }
    bool isSelected = current == effect;

    return GestureDetector(
      onTap: () => setState(() {
        if (_editMode == 'Verse') {
          _verseEffect = effect;
        } else if (_editMode == 'Dual Verse') {
          _secEffect = effect;
        } else if (_editMode == 'Dual Ref') {
          _secRefEffect = effect;
        } else {
          _refEffect = effect;
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.white, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14, color: isSelected ? Colors.black : Colors.grey),
            const SizedBox(width: 4),
            Text(effect,
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _applyTextEffect(String effect, Widget child,
      {List<Color>? gradientColors,
      Alignment? begin,
      Alignment? end,
      Color? goldTint}) {
    if (effect == 'Gradient') {
      return ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: gradientColors ??
              [
                Colors.blue,
                Colors.purple,
                Colors.pink,
                Colors.orange,
                Colors.yellow
              ],
          tileMode: TileMode.mirror,
          begin: begin ?? Alignment.topLeft,
          end: end ?? Alignment.bottomRight,
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: child,
      );
    }
    if (effect == 'Gold') {
      return ShaderMask(
        shaderCallback: (bounds) {
          // Standard Gold Palette
          final standardGold = [
            const Color(0xFFBF953F),
            const Color(0xFFFCF6BA),
            const Color(0xFFB38728),
            const Color(0xFFFBF5B7),
            const Color(0xFFAA771C),
          ];

          List<Color> gradientColors = standardGold;
          if (goldTint != null) {
            // Apply Tint
            gradientColors = standardGold
                .map((c) => Color.alphaBlend(goldTint.withOpacity(0.4), c))
                .toList();
          }

          return LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcIn,
        child: child,
      );
    }
    return child;
  }

  List<Shadow> _getEffectShadows(
      String effect, bool existingShadow, double value, Color color) {
    List<Shadow> shadows = [];

    // Basic Shadow - Force black/grey for basic, ignore effect color
    if (existingShadow && (effect == 'None' || effect == 'Gradient')) {
      shadows.add(const Shadow(
          offset: Offset(2, 2), blurRadius: 4.0, color: Colors.black54));
    }

    if (effect == '3D') {
      // Value 0.0 -> small depth, 1.0 -> deep depth
      double depth = 2.0 + (value * 8.0); // 2 to 10
      shadows = [
        Shadow(offset: Offset(depth * 0.2, depth * 0.2), color: color),
        Shadow(offset: Offset(depth * 0.4, depth * 0.4), color: color),
        Shadow(offset: Offset(depth * 0.6, depth * 0.6), color: color),
        Shadow(offset: Offset(depth * 0.8, depth * 0.8), color: color),
        Shadow(offset: Offset(depth, depth), color: color.withOpacity(0.5)),
      ];
    } else if (effect == 'Glow') {
      // Value determines blur radius
      double blur = 5.0 + (value * 25.0); // 5 to 30
      shadows = [
        Shadow(blurRadius: blur, color: color),
        Shadow(blurRadius: blur * 2, color: color.withOpacity(0.6)),
      ];
    } else if (effect == 'Gold') {
      shadows.add(const Shadow(
          offset: Offset(2, 2), blurRadius: 2.0, color: Colors.black87));
    }
    return shadows;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _backgroundImage = File(pickedFile.path);
        _useImage = true;
        _useGradient = false;
        _verseColor = Colors.white;
        _refColor = Colors.white;
      });
    }
  }

  void _showGradientCustomizationDialog() {
    List<Color> currentColors;
    Alignment currentBegin;
    Alignment currentEnd;

    if (_editMode == 'Verse') {
      currentColors = List.from(_verseGradientColors);
      currentBegin = _verseGradientBegin;
      currentEnd = _verseGradientEnd;
    } else if (_editMode == 'Dual Verse') {
      currentColors = List.from(_secGradientColors);
      currentBegin = _secGradientBegin;
      currentEnd = _secGradientEnd;
    } else if (_editMode == 'Dual Ref') {
      currentColors = List.from(_secRefGradientColors);
      currentBegin = _secRefGradientBegin;
      currentEnd = _secRefGradientEnd;
    } else {
      currentColors = List.from(_refGradientColors);
      currentBegin = _refGradientBegin;
      currentEnd = _refGradientEnd;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Customize Gradient',
                style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Colors",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...currentColors.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Color color = entry.value;
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Pick Color'),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: color,
                                    onColorChanged: (newColor) {
                                      setDialogState(() {
                                        currentColors[idx] = newColor;
                                      });
                                      _updateGradientState(currentColors,
                                          currentBegin, currentEnd);
                                    },
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    child: const Text('Done'),
                                    onPressed: () => Navigator.pop(c),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                        );
                      }).toList(),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          if (currentColors.length < 5) {
                            setDialogState(() {
                              currentColors.add(Colors.white);
                            });
                            _updateGradientState(
                                currentColors, currentBegin, currentEnd);
                          }
                        },
                      ),
                      if (currentColors.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () {
                            setDialogState(() {
                              currentColors.removeLast();
                            });
                            _updateGradientState(
                                currentColors, currentBegin, currentEnd);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Direction",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      _buildDirectionBtn(
                          Alignment.topLeft,
                          Alignment.bottomRight,
                          Icons.north_west,
                          currentBegin,
                          setDialogState,
                          currentColors),
                      _buildDirectionBtn(
                          Alignment.topCenter,
                          Alignment.bottomCenter,
                          Icons.arrow_downward,
                          currentBegin,
                          setDialogState,
                          currentColors),
                      _buildDirectionBtn(
                          Alignment.centerLeft,
                          Alignment.centerRight,
                          Icons.arrow_forward,
                          currentBegin,
                          setDialogState,
                          currentColors),
                      _buildDirectionBtn(
                          Alignment.bottomLeft,
                          Alignment.topRight,
                          Icons.north_east,
                          currentBegin,
                          setDialogState,
                          currentColors),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Done'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDirectionBtn(Alignment begin, Alignment end, IconData icon,
      Alignment currentBegin, StateSetter setDialogState, List<Color> colors) {
    bool isSelected = currentBegin == begin;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.orange : Colors.grey),
      onPressed: () {
        setDialogState(() {});
        _updateGradientState(colors, begin, end);
      },
    );
  }

  void _updateGradientState(
      List<Color> colors, Alignment begin, Alignment end) {
    setState(() {
      if (_editMode == 'Verse') {
        _verseGradientColors = List.from(colors);
        _verseGradientBegin = begin;
        _verseGradientEnd = end;
      } else if (_editMode == 'Dual Verse') {
        _secGradientColors = List.from(colors);
        _secGradientBegin = begin;
        _secGradientEnd = end;
      } else if (_editMode == 'Dual Ref') {
        _secRefGradientColors = List.from(colors);
        _secRefGradientBegin = begin;
        _secRefGradientEnd = end;
      } else {
        _refGradientColors = List.from(colors);
        _refGradientBegin = begin;
        _refGradientEnd = end;
      }
    });
  }

  Future<void> _shareImage() async {
    // 1. Hide Borders
    setState(() => _isExporting = true);

    // Wait for rebuild
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // 2. Capture with High Quality (pixelRatio: 3.0)
      final image = await _screenshotController.capture(pixelRatio: 3.0);

      setState(() => _isExporting = false); // Show borders again

      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath =
          await File('${directory.path}/share_verse.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath.path)],
          text: 'Shared via Holy Word App');
    } catch (e) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
    }
  }

  Widget _buildLayoutControls() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Select a preset styling",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: GridView.builder(
            itemCount: LayoutPresets.layouts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final layout = LayoutPresets.layouts[index];
              return GestureDetector(
                onTap: () => _applyLayout(layout),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style, color: layout.verseColor),
                      const SizedBox(height: 4),
                      Text(
                        layout.name,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyledVerseText(String text) {
    if (_layoutStrategy == LayoutStrategy.uniform) {
      // Base Style
      final style = _getFont(
        _verseFont,
        _verseTextSize,
        _verseEffect == 'Gradient' || _verseEffect == 'Gold'
            ? Colors.white
            : _verseColor.withOpacity(_verseOpacity),
        _isBold ? FontWeight.bold : FontWeight.normal,
      ).copyWith(
        height: _verseLineHeight,
        fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
        decoration:
            _isUnderlined ? TextDecoration.underline : TextDecoration.none,
        shadows: _getEffectShadows(
            _verseEffect, _hasShadow, _verseEffectVal, _verseEffectColor),
      );

      Widget textWidget = _isVerseDynamic
          ? AutoSizeText(
              text,
              textAlign: _verseAlign,
              style: style,
              minFontSize: 14,
              maxLines: 15,
              stepGranularity: 1,
              wrapWords: true, // Wrap at words if possible
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              text,
              textAlign: _verseAlign,
              style: style,
            );

      // Apply Stroke if needed
      if (_verseStrokeWidth > 0 && _verseStrokeColor != null) {
        return Stack(
          children: [
            // Stroke Layer
            Text(
              text,
              textAlign: _verseAlign,
              style: style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = _verseStrokeWidth
                  ..color = _verseStrokeColor!,
                shadows: [], // No shadow on stroke usually
              ),
            ),
            // Fill Layer
            textWidget,
          ],
        );
      }
      return textWidget;
    }

    // Strategies that rely on splitting lines
    final lines = text.split('\n');
    List<Widget> textWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      Color lineColor = _verseColor; // Default
      double lineSize = _verseTextSize; // Default

      if (_layoutStrategy == LayoutStrategy.multiLineColors) {
        if (_multiColors.isNotEmpty) {
          lineColor = _multiColors[i % _multiColors.length];
        }
      } else if (_layoutStrategy == LayoutStrategy.alternatingSize) {
        if (_multiSizes.isNotEmpty) {
          lineSize = _multiSizes[i % _multiSizes.length];
        }
        if (_multiColors.isNotEmpty) {
          lineColor = _multiColors[i % _multiColors.length];
        }
      } else if (_layoutStrategy == LayoutStrategy.emphasisCenter) {
        // Emphasis on the middle line (approx)
        bool isCenter = i == (lines.length / 2).floor();
        if (isCenter) {
          if (_multiSizes.isNotEmpty) lineSize = _multiSizes[0];
          if (_multiColors.isNotEmpty) lineColor = _multiColors[0];
        }
      }

      final style = _getFont(
        _verseFont,
        lineSize,
        _verseEffect == 'Gradient' || _verseEffect == 'Gold'
            ? Colors.white
            : lineColor.withOpacity(_verseOpacity),
        _isBold ? FontWeight.bold : FontWeight.normal,
      ).copyWith(
        height: _verseLineHeight,
        fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
        decoration:
            _isUnderlined ? TextDecoration.underline : TextDecoration.none,
        shadows: _getEffectShadows(
            _verseEffect, _hasShadow, _verseEffectVal, _verseEffectColor),
      );

      Widget lineWidget = Text(
        lines[i],
        textAlign: _verseAlign,
        style: style,
      );

      // Apply Stroke Per Line if needed
      if (_verseStrokeWidth > 0 && _verseStrokeColor != null) {
        lineWidget = Stack(
          children: [
            Text(
              lines[i],
              textAlign: _verseAlign,
              style: style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = _verseStrokeWidth
                  ..color = _verseStrokeColor!,
                shadows: [],
              ),
            ),
            lineWidget,
          ],
        );
      }

      textWidgets.add(lineWidget);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _getCrossAlign(_verseAlign),
      children: textWidgets,
    );
  }

  CrossAxisAlignment _getCrossAlign(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return CrossAxisAlignment.start;
      case TextAlign.right:
        return CrossAxisAlignment.end;
      case TextAlign.center:
      case TextAlign.justify:
      default:
        return CrossAxisAlignment.center;
    }
  }

  void _applyLayout(VerseLayout layout) {
    setState(() {
      // 1. Background
      _backgroundColor = layout.backgroundColor;
      _backgroundGradient = layout.backgroundGradient;
      _useGradient = layout.useGradient;
      _useImage = layout.useImage;

      // 2. Verse Style
      _verseFont = layout.verseFont;
      _verseTextSize = layout.verseTextSize;
      _verseColor = layout.verseColor;
      _verseAlign = layout.verseAlign;
      _isBold = layout.isBold;
      _isItalic = layout.isItalic;
      _isUnderlined = layout.isUnderlined;
      _hasShadow = layout.hasShadow;
      _verseEffect = layout.verseEffect;
      _verseEffectVal = layout.verseEffectVal;
      _verseEffectColor = layout.verseEffectColor;
      _verseGradientColors = layout.verseGradientColors;
      _verseGradientBegin = layout.verseGradientBegin;
      _verseGradientEnd = layout.verseGradientEnd;

      // 2b. Multi-Style & Stroke
      _layoutStrategy = layout.strategy;
      _multiColors = List.from(layout.multiColors);
      _multiSizes = List.from(layout.multiSizes);
      _verseStrokeColor = layout.verseStrokeColor;
      _verseStrokeWidth = layout.verseStrokeWidth;

      // 3. Reference Style
      _refFont = layout.refFont;
      _refTextSize = layout.refTextSize;
      _refColor = layout.refColor;
      _refAlign = layout.refAlign;
      _refBold = layout.refBold;
      _refItalic = layout.refItalic;
      _refEffect = layout.refEffect;
      _refEffectVal = layout.refEffectVal;
      _refEffectColor = layout.refEffectColor;
      _refGradientColors = layout.refGradientColors;
      _refGradientBegin = layout.refGradientBegin;
      _refGradientEnd = layout.refGradientEnd;
      // Ref Pill
      _refBackgroundColor = layout.refBackgroundColor;
      _refBorderRadius = layout.refBorderRadius;

      // 4. Secondary Style (Optional: default to match verse or separate?)
      // For now, mirroring primary verse style to keep it simple unless specified
      // or we can just leave it as is.
      // Let's mirror basic font/color to keep it consistent
      _secFont = layout.verseFont;
      _secColor = layout.verseColor;
      _secRefFont = layout.refFont;
      _secRefColor = layout.refColor;

      // 5. Watermark
      _watermarkStyle = layout.watermarkStyle;
      _textWidthFactor = layout.textWidthFactor;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Applied '${layout.name}' layout"),
        duration: const Duration(milliseconds: 600),
      ),
    );
  }
}
