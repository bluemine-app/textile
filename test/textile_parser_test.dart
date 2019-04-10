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

import 'parse_results.dart';

List<String> read(String path) => File(path).readAsLinesSync();

void main() {
  group('BlockSyntax', () {
    test('Test HeaderSyntax', () {
      var document = Document(blockSyntaxes: [HeaderSyntax()]);
      final lines = read("test/units/block_paragraph.unit");
      var nodes = document.parseLines(lines);
      var contents =
          nodes.map((node) => node.textContent).toList(growable: false);
      expect(contents, equals(headers));
    });

    test('Test PreFormattedSyntax', () {
      var document = Document(blockSyntaxes: [PreFormattedSyntax()]);
      final lines = read("test/units/code_paragraph.unit");
      var nodes = document.parseLines(lines);
      var contents =
          nodes.map((node) => node.textContent).toList(growable: false);
      expect(contents, equals(codeBlocks));
    });
  });
}
