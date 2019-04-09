/*     
  Copyright (C) 2019 Omkar Todkar

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>. 
*/
import 'base.dart';
import 'document.dart';

//region Common Expressions
/// The line contains only whitespace or is empty.
/// check for regex at https://regex101.com/r/iF9lHI/1
final _emptyPattern = RegExp(r'^(?:[ \t]*)$');

/// One or more whitespace, for compressing.
final _oneOrMoreWhitespacePattern = RegExp('[ \n\r\t]+');

/// The line starts with [h] following 1-6 and then alignment >, = or <
/// check for regex at https://regex101.com/r/wKyEhP/2
final _headerPattern = RegExp(r'^(h[1-6])([ ><=]?)\.(.*)');

/// The line are starts with 'p. ' or by any character
/// but not starting with whitespace.
/// check for regex at https://regex101.com/r/Pv37oS/1
final _paragraphPattern =
    RegExp(r'^([^\s][p\.]\s)(.*)|^[^\s].*$', multiLine: true);
//endregion

/// Alignment abbreviations values.
final alignmentAbbreviations = {"=": "center", "<": "left", ">": "right"};

/// BlockParser.
class BlockParser {
  final List<String> lines;

  /// The Markdown document this parser is parsing.
  final Document document;

  /// The enabled block syntaxes.
  ///
  /// To turn a series of lines into blocks, each of these will be tried in
  /// turn. Order matters here.
  final List<BlockSyntax> blockSyntaxes = [];

  /// Index of the current line.
  int _pos = 0;

  /// Whether the parser has encountered a blank line between two block-level
  /// elements.
  bool encounteredBlankLine = false;

  /// All standard [BlockSyntax] to be parsed
  final List<BlockSyntax> standardBlockSyntaxes = [];

  BlockParser(this.lines, this.document) {
    blockSyntaxes.addAll(document.blockSyntaxes);
    blockSyntaxes.addAll(standardBlockSyntaxes);
  }

  /// Gets the current line.
  String get current => lines[_pos];

  /// Gets the line after the current one or `null` if there is none.
  String get next {
    // Don't read past the end.
    if (_pos >= lines.length - 1) return null;
    return lines[_pos + 1];
  }

  /// Gets the line that is [linesAhead] lines ahead of the current one, or
  /// `null` if there is none.
  ///
  /// `peek(0)` is equivalent to [current].
  ///
  /// `peek(1)` is equivalent to [next].
  String peek(int linesAhead) {
    if (linesAhead < 0) {
      throw ArgumentError('Invalid linesAhead: $linesAhead; must be >= 0.');
    }
    // Don't read past the end.
    if (_pos >= lines.length - linesAhead) return null;
    return lines[_pos + linesAhead];
  }

  void advance() {
    _pos++;
  }

  bool get isDone => _pos >= lines.length;

  /// Gets whether or not the current line matches the given pattern.
  bool matches(RegExp regex) {
    if (isDone) return false;
    return regex.firstMatch(current) != null;
  }

  /// Gets whether or not the next line matches the given pattern.
  bool matchesNext(RegExp regex) {
    if (next == null) return false;
    return regex.firstMatch(next) != null;
  }

  List<Node> parseLines() {
    var blocks = <Node>[];
    while (!isDone) {
      for (var syntax in blockSyntaxes) {
        if (syntax.canParse(this)) {
          var block = syntax.parse(this);
          if (block != null) blocks.add(block);
          break;
        } else //TODO applied for test purpose only.
          advance();
      }
    }

    return blocks;
  }
}

/// Abstract block syntax for textile extending [BlockSyntax].
abstract class BlockSyntax {
  const BlockSyntax();

  /// Gets the regex used to identify the beginning of this block, if any.
  RegExp get pattern => null;

  bool get canEndBlock => true;

  bool canParse(BlockParser parser) {
    return pattern.firstMatch(parser.current) != null;
  }

  Node parse(BlockParser parser);

  List<String> parseChildLines(BlockParser parser) {
    // Grab all of the lines that form the block element.
    var childLines = <String>[];

    while (!parser.isDone) {
      var match = pattern.firstMatch(parser.current);
      if (match == null) break;
      childLines.add(match[1]);
      parser.advance();
    }

    return childLines;
  }

  /// Gets whether or not [parser]'s current line should end the previous block.
  static bool isAtBlockEnd(BlockParser parser) {
    if (parser.isDone) return true;
    return parser.blockSyntaxes.any((s) => s.canParse(parser) && s.canEndBlock);
  }

  /// Generates a valid HTML anchor from the inner text of [element].
  static String generateAnchorHash(Element element) =>
      element.children.first.textContent
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
          .replaceAll(RegExp(r'\s'), '-');
}

class EmptyBlockSyntax extends BlockSyntax {
  const EmptyBlockSyntax();

  @override
  RegExp get pattern => _emptyPattern;

  @override
  Node parse(BlockParser parser) {
    parser.encounteredBlankLine = true;
    parser.advance();
    return null;
  }
}

class HeaderSyntax extends BlockSyntax {
  const HeaderSyntax();

  @override
  RegExp get pattern => _headerPattern;

  /// [Match] contains header type, optionally any one of
  /// [alignmentAbbreviations], ending dot and text content.
  ///
  /// match[1] anyOneOf(h1...h6)
  /// match[2] anyOneOf(><=) or null
  /// match[3] textContent
  @override
  Node parse(BlockParser parser) {
    var match = pattern.firstMatch(parser.current);
    parser.advance();
    var contents = UnparsedContent(match[3].trim());
    var alignment = _parseHeaderAlignment(match[2]);
    return Element(match[1], [contents], alignment);
  }

  Map<String, String> _parseHeaderAlignment(String value) => value == null
      ? {}
      : {"style": "text-align:${alignmentAbbreviations[value]};"};
}

/// Parses Paragraph blocks
class ParagraphSyntax extends BlockSyntax {
  static final _reflinkDefinitionStart = RegExp(r'[ ]{0,3}\[');

  static final _whitespacePattern = RegExp(r'^\s*$');

  @override
  RegExp get pattern => _paragraphPattern;

  @override
  Node parse(BlockParser parser) {
    var childLines = <String>[];

    // Eat until we hit something that ends a paragraph.
    while (!BlockSyntax.isAtBlockEnd(parser)) {
      childLines.add(parser.current);
      parser.advance();
    }

    var paragraphLines = _extractReflinkDefinitions(parser, childLines);
    if (paragraphLines == null) {
      // Paragraph consisted solely of reference link definitions.
      return Text('');
    } else {
      var contents = UnparsedContent(paragraphLines.join('\n'));
      return Element.create('p', [contents]);
    }
  }

  /// Extract reference link definitions from the front of the paragraph, and
  /// return the remaining paragraph lines.
  List<String> _extractReflinkDefinitions(
      BlockParser parser, List<String> lines) {
    bool lineStartsReflinkDefinition(int i) =>
        lines[i].startsWith(_reflinkDefinitionStart);

    var i = 0;
    loopOverDefinitions:
    while (true) {
      // Check for reflink definitions.
      if (!lineStartsReflinkDefinition(i)) {
        // It's paragraph content from here on out.
        break;
      }
      var contents = lines[i];
      var j = i + 1;
      while (j < lines.length) {
        // Check to see if the _next_ line might start a new reflink definition.
        // Even if it turns out not to be, but it started with a '[', then it
        // is not a part of _this_ possible reflink definition.
        if (lineStartsReflinkDefinition(j)) {
          // Try to parse [contents] as a reflink definition.
          if (_parseReflinkDefinition(parser, contents)) {
            // Loop again, starting at the next possible reflink definition.
            i = j;
            continue loopOverDefinitions;
          } else {
            // Could not parse [contents] as a reflink definition.
            break;
          }
        } else {
          contents = contents + '\n' + lines[j];
          j++;
        }
      }
      // End of the block.
      if (_parseReflinkDefinition(parser, contents)) {
        i = j;
        break;
      }

      // It may be that there is a reflink definition starting at [i], but it
      // does not extend all the way to [j], such as:
      //
      //     [link]: url     // line i
      //     "title"
      //     garbage
      //     [link2]: url   // line j
      //
      // In this case, [i, i+1] is a reflink definition, and the rest is
      // paragraph content.
      while (j >= i) {
        // This isn't the most efficient loop, what with this big ole'
        // Iterable allocation (`getRange`) followed by a big 'ole String
        // allocation, but we
        // must walk backwards, checking each range.
        contents = lines.getRange(i, j).join('\n');
        if (_parseReflinkDefinition(parser, contents)) {
          // That is the last reflink definition. The rest is paragraph
          // content.
          i = j;
          break;
        }
        j--;
      }
      // The ending was not a reflink definition at all. Just paragraph
      // content.

      break;
    }

    if (i == lines.length) {
      // No paragraph content.
      return null;
    } else {
      // Ends with paragraph content.
      return lines.sublist(i);
    }
  }

  // Parse [contents] as a reference link definition.
  //
  // Also adds the reference link definition to the document.
  //
  // Returns whether [contents] could be parsed as a reference link definition.
  bool _parseReflinkDefinition(BlockParser parser, String contents) {
    var pattern = RegExp(
        // Leading indentation.
        r'''^[ ]{0,3}'''
        // Reference id in brackets, and URL.
        r'''\[((?:\\\]|[^\]])+)\]:\s*(?:<(\S+)>|(\S+))\s*'''
        // Title in double or single quotes, or parens.
        r'''("[^"]+"|'[^']+'|\([^)]+\)|)\s*$''',
        multiLine: true);
    var match = pattern.firstMatch(contents);
    if (match == null) {
      // Not a reference link definition.
      return false;
    }
    if (match[0].length < contents.length) {
      // Trailing text. No good.
      return false;
    }

    var label = match[1];
    var destination = match[2] ?? match[3];
    var title = match[4];

    // The label must contain at least one non-whitespace character.
    if (_whitespacePattern.hasMatch(label)) {
      return false;
    }

    if (title == '') {
      // No title.
      title = null;
    } else {
      // Remove "", '', or ().
      title = title.substring(1, title.length - 1);
    }

    // References are case-insensitive, and internal whitespace is compressed.
    label =
        label.toLowerCase().trim().replaceAll(_oneOrMoreWhitespacePattern, ' ');

    parser.document.linkReferences
        .putIfAbsent(label, () => LinkReference(label, destination, title));
    return true;
  }
}
