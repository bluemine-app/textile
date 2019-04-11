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

import 'dart:collection';

import 'package:textile/src/base.dart';
import 'package:textile/src/block_parser.dart';
import 'package:textile/src/document.dart';
import 'package:textile/src/inline_parser.dart';

String textileToHtml(String textile,
    {Iterable<BlockSyntax> blockSyntaxes,
    Iterable<InlineSyntax> inlineSyntaxes,
    Resolver linkResolver,
    Resolver imageLinkResolver,
    bool inlineOnly = false}) {
  var document = Document(
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
      linkResolver: linkResolver,
      imageLinkResolver: imageLinkResolver);

  if (inlineOnly) return renderToHtml(document.parseInline(textile));

  // Replace windows line endings with unix line endings, and split.
  var lines = textile.replaceAll('\r\n', '\n').split('\n');

  return renderToHtml(document.parseLines(lines)) + '\n';
}

/// Renders [nodes] to HTML.
String renderToHtml(List<Node> nodes) => HtmlRenderer().render(nodes);

class HtmlRenderer implements NodeVisitor {
  static final _blockTags = RegExp('blockquote|h[1-6r]|p(?:re)?');

  StringBuffer buffer;
  Set<String> uniqueIds;

  HtmlRenderer();

  String render(List<Node> nodes) {
    buffer = StringBuffer();
    uniqueIds = LinkedHashSet<String>();

    for (final node in nodes) node.accept(this);

    return buffer.toString();
  }

  @override
  void visitElementAfter(Element element) {
    // TODO: implement visitElementAfter
    buffer.write('</${element.tag}>');
  }

  @override
  bool visitElementBefore(Element element) {
    // TODO: implement visitElementBefore
    // Hackish. Separate block-level elements with newlines.
    if (buffer.isNotEmpty && _blockTags.firstMatch(element.tag) != null) {
      buffer.write('\n');
    }

    buffer.write('<${element.tag}');

    for (var entry in element.attributes.entries) {
      buffer.write(' ${entry.key}="${entry.value}"');
    }

    // attach header anchor ids generated from text
    if (element.generatedId != null) {
      buffer.write(' id="${uniquifyId(element.generatedId)}"');
    }

    if (element.isEmpty) {
      // Empty element like <hr/>.
      buffer.write(' />');

      if (element.tag == 'br') {
        buffer.write('\n');
      }

      return false;
    } else {
      buffer.write('>');
      return true;
    }
  }

  @override
  void visitText(Text text) {
    buffer.write(text.textContent);
  }

  /// Uniquifies an id generated from text.
  String uniquifyId(String id) {
    if (!uniqueIds.contains(id)) {
      uniqueIds.add(id);
      return id;
    }

    var suffix = 2;
    var suffixedId = '$id-$suffix';
    while (uniqueIds.contains(suffixedId)) {
      suffixedId = '$id-${suffix++}';
    }
    uniqueIds.add(suffixedId);
    return suffixedId;
  }
}
