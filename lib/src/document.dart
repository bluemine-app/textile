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
import 'block_parser.dart';
import 'inline_parser.dart';

class Document {
  final Map<String, LinkReference> linkReferences = <String, LinkReference>{};
  final Resolver linkResolver;
  final Resolver imageLinkResolver;
  final bool encodeHtml;
  final _blockSyntaxes = Set<BlockSyntax>();
  final _inlineSyntaxes = Set<InlineSyntax>();

  Iterable<BlockSyntax> get blockSyntaxes => _blockSyntaxes;
  Iterable<InlineSyntax> get inlineSyntaxes => _inlineSyntaxes;

  Document(
      {Iterable<BlockSyntax> blockSyntaxes,
      Iterable<InlineSyntax> inlineSyntaxes,
      this.linkResolver,
      this.imageLinkResolver,
      this.encodeHtml = true}) {
    this._blockSyntaxes.addAll(blockSyntaxes ?? []);
    this._inlineSyntaxes.addAll(inlineSyntaxes ?? []);
  }

  List<Node> parseLines(List<String> lines) {
    var nodes = BlockParser(lines, this).parseLines();
    _parseInlineContent(nodes);
    return nodes;
  }

  List<Node> parseInline(String text) {
    return null;
  }

  void _parseInlineContent(List<Node> nodes) {
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node is UnparsedContent) {
        var inlineNodes = parseInline(node.textContent);
        if (inlineNodes != null) {
          nodes.removeAt(i);
          nodes.insertAll(i, inlineNodes);
          i += inlineNodes.length - 1;
        }
      } else if (node is Element && node.children != null) {
        _parseInlineContent(node.children);
      }
    }
  }
}

/// A [link reference
/// definition](http://spec.commonmark.org/0.28/#link-reference-definitions).
class LinkReference {
  /// The [link label](http://spec.commonmark.org/0.28/#link-label).
  ///
  /// Temporarily, this class is also being used to represent the link data for
  /// an inline link (the destination and title), but this should change before
  /// the package is released.
  final String label;

  /// The [link destination](http://spec.commonmark.org/0.28/#link-destination).
  final String destination;

  /// The [link title](http://spec.commonmark.org/0.28/#link-title).
  final String title;

  /// Construct a new [LinkReference], with all necessary fields.
  ///
  /// If the parsed link reference definition does not include a title, use
  /// `null` for the [title] parameter.
  LinkReference(this.label, this.destination, this.title);
}
