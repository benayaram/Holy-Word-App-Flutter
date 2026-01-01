
import os

file_path = r'c:\Projects\Benayaram Projects\Holy Word App from Git\holy_word_app\lib\features\bible\presentation\share_verse_screen.dart'

new_method_code = r'''  Widget _buildStyledVerseText(String text) {
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

    // Calculate split for EmphasisEnd
    int emphasisStartIndex = lines.length;
    if (_layoutStrategy == LayoutStrategy.emphasisEnd) {
      if (lines.length == 1) {
         emphasisStartIndex = 1; 
      } else if (lines.length == 2) {
         emphasisStartIndex = 1; // 1 Intro, 1 Emphasis
      } else {
         emphasisStartIndex = lines.length - 2;
         if (emphasisStartIndex < 1) emphasisStartIndex = 1;
      }
    }

    for (int i = 0; i < lines.length; i++) {
      Color lineColor = _verseColor; // Default
      double lineSize = _verseTextSize; // Default
      String lineFont = _verseFont;
      bool lineBold = _isBold;

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
      } else if (_layoutStrategy == LayoutStrategy.emphasisEnd) {
        bool isEmphasis = i >= emphasisStartIndex;
        if (isEmphasis) {
           if (_emphasisFont != null) lineFont = _emphasisFont!;
           if (_emphasisTextSize != null) lineSize = _emphasisTextSize!;
           if (_emphasisColor != null) lineColor = _emphasisColor!;
           lineBold = _emphasisBold;
        }
      }

      final style = _getFont(
        lineFont,
        lineSize,
        _verseEffect == 'Gradient' || _verseEffect == 'Gold'
            ? Colors.white
            : lineColor.withOpacity(_verseOpacity),
        lineBold ? FontWeight.bold : FontWeight.normal,
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
  }'''

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Indices are 0-based. Line 2962 is index 2961.
# Line 3227 is index 3226.
# We want to replace [2961, 3226] inclusive.
# So keep lines[:2961] and lines[3227:].

start_idx = 2961
end_idx = 3227 # exclusive for slicing of second part? 3226 is the last line we want to remove. So start next from 3227.

new_lines = lines[:start_idx] + [new_method_code + '\n'] + lines[end_idx:]

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Successfully patched file.")
