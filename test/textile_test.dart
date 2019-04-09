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
import 'dart:io';

import 'package:test/test.dart';
import 'package:textile/textile.dart';

List<String> read(String path) => File(path).readAsLinesSync();

void main() {
  final lines = read("test/examples/block_paragraph.unit");

  group('BlockSyntax', () {
    test('test Paragraph to detect block', () {
      var paragraph = ParagraphSyntax();
      var parser = BlockParser(lines, Document());
      var node = paragraph.parse(parser);

      print("content: ${node.textContent}");
      expect(node.textContent, hasLength(3022));
    });
  });
}
