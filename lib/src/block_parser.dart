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

import 'dart:core';

import 'base.dart';
import 'document.dart';
import 'util.dart';

//region Common Expressions
/// The line contains only whitespace or is empty.
/// check for regex at https://regex101.com/r/iF9lHI/1
final _emptyPattern = RegExp(r'^(?:[ \t]*)$');

/// One or more whitespace, for compressing.
// final _oneOrMoreWhitespacePattern = RegExp('[ \n\r\t]+');

/// Find if line is starts a new block.
/// check for regex at https://regex101.com/r/BwoJnd/3
final _newBlockPattern =
    RegExp(r'(^p(?:re)?|^h[1-6]|^b[qc]|^fn\d+|^notextile)\.{1,2} ');

/// The line are starts with 'p. ' or by any character
/// but not starting with whitespace.
/// check for regex at https://regex101.com/r/Pv37oS/1
/*final _paragraphPattern =
    RegExp(r'^([^\s][p\.]\s)(.*)|^[^\s].*$', multiLine: true);*/
//endregion

/// Textile abbreviations mapped with their values.
final abbreviations = {
  /* CSS styles */
  '=': 'center',
  '<': 'left',
  '>': 'right',

  /* HTML Tags */
  'pre': 'pre',
  'bc': 'code',
  'bq': 'blockquote'
};

/// BlockParser to parse series of lines into blocks of Textile suitable
/// for further inline parsing.
class BlockParser {
  /// Raw lines of document.
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
  final List<BlockSyntax> standardBlockSyntaxes = [
    const EmptyBlockSyntax(),
    const HeaderSyntax(),
    const PreFormattedSyntax(),
    const ParagraphSyntax()
  ];

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
      var shouldAdvance = true;
      for (var syntax in blockSyntaxes) {
        if (syntax.canParse(this)) {
          var block = syntax.parse(this);
          if (block != null) blocks.add(block);
          shouldAdvance = false;
          break;
        }
      }
      //FIXME: remove this hack once all standard syntax are complete.
      if (shouldAdvance) advance();
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

  /// Generates valid style attribute with text-alignment in it.
  static Map<String, String> _parseTextAlignment(String value) =>
      value?.isNotEmpty ?? false
          ? {'style': 'text-align:${abbreviations[value]};'}
          : {};
}

/// Parse empty lines in document.
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

/// Parse headers in document.
class HeaderSyntax extends BlockSyntax {
  const HeaderSyntax();

  /// The line starts with 'h' following 1-6 and then alignment >, = or <
  /// check for regex at https://regex101.com/r/EKmyTB/1
  @override
  RegExp get pattern => RegExp(r'^(h[1-6])([ ><=]?)\.(.*)');

  /// [Match] contains header type, optionally any one of
  /// [abbreviations], ending dot and text content.
  ///
  /// match[1] anyOneOf(h1...h6)
  /// match[2] anyOneOf(><=) or null
  /// match[3] textContent
  @override
  Node parse(BlockParser parser) {
    var match = pattern.firstMatch(parser.current);
    parser.advance();
    var tag = match[1];
    var alignment = BlockSyntax._parseTextAlignment(match[2]);
    var contents = RawContent(match[3].trim());
    return Element(tag, [contents], alignment);
  }
}

/// Parse Code Blocks and Pre-formatted content in document.
class PreFormattedSyntax extends BlockSyntax {
  const PreFormattedSyntax();

  /// The block starting for pre-formatted or code section.
  @override
  RegExp get pattern => RegExp(r'^(pre|bc)(\.{0,2}) (.*)');

  /// It will be depending on parsing.
  @override
  bool get canEndBlock => false;

  /// [Match] consist of three groups pre-formatted or code tag,
  /// number of dots and one or more whitespace.
  ///
  /// match[1] anyOneOf(pre, bc)
  /// match[2] . or ..
  /// match[3] textContent or empty
  ///
  /// In case 3rd group is empty consider next line for parsing.
  /// If 2nd group has double dots, consider next all consecutive lines
  /// until new tag is found for parsing.
  @override
  Node parse(BlockParser parser) {
    var match = pattern.firstMatch(parser.current);
    var tag = abbreviations[match[1]];
    var dots = match[2].length;
    var inlineContent = match[3];

    //TODO: optimize below code.
    String escaped;
    if (dots > 1) {
      var content = <String>[];
      if (inlineContent?.isNotEmpty ?? false) {
        content.add(inlineContent);
      }
      parser.advance();
      content.addAll(parseChildLines(parser));
      escaped = escapeHtml(content.join('\n'));
    } else {
      // find a non empty line for parsing
      if (inlineContent?.isEmpty ?? true) {
        while (!parser.isDone) {
          parser.advance();
          inlineContent = parser.current;
          // break if content found in line
          if (inlineContent?.isNotEmpty ?? false) break;
        }
      } else {
        parser.advance();
      }

      escaped = escapeHtml(inlineContent);
    }
    return tag == 'code'
        ? Element.create('pre', [Element.text(tag, escaped)])
        : Element.text(tag, escaped);
  }

  /// Parse children from current block until new block is found.
  @override
  List<String> parseChildLines(BlockParser parser) {
    var childLines = <String>[];
    while (!parser.isDone && !parser.matches(_newBlockPattern)) {
      childLines.add(parser.current);
      parser.advance();
    }
    return childLines;
  }
}

/// Parse paragraph content from document.
class ParagraphSyntax extends BlockSyntax {
  const ParagraphSyntax();

  @override
  bool get canEndBlock => false;

  @override
  bool canParse(BlockParser parser) => true;

  @override
  Node parse(BlockParser parser) {
    var childLines = <String>[];

    while (!BlockSyntax.isAtBlockEnd(parser)) {
      childLines.add(parser.current);
      parser.advance();
    }

    //TODO: parse link references while doing task #36

    var contents = RawContent(childLines.join('\n'));
    return Element.create('p', [contents]);
  }
}
