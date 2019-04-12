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

String read(String path) => File(path).readAsStringSync();

void main() {
  group('Html Renderer', () {
    test('Test block_paragraph', () async {
      var html = textileToHtml(read('test/units/block_paragraph.unit'));
      var logFile = File('test/results/block_paragraph.html');
      var sink = logFile.openWrite();
      sink.write(html);
      await sink.flush();
      await sink.close();

      // after finishing job print it.
      print('wrote to file: ${logFile.path}\n\n');
      print('$html\n');
    });

    test('Test code_paragraph', () async {
      var html = textileToHtml(read('test/units/code_paragraph.unit'));
      var logFile = File('test/results/code_paragraph.html');
      var sink = logFile.openWrite();
      sink.write(html);
      await sink.flush();
      await sink.close();

      // after finishing job print it.
      print('wrote to file: ${logFile.path}\n\n');
      print('$html\n');
    });
  });
}
