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
  final lines = read("test/units/block_paragraph.unit");

  /// used for [HeaderSyntax] test.
  var headers = [
    "Art of Trackers",
    "Types of Trackers",
    "Priority levels",
    "Describing the Issue",
    "Issue Description",
    "Component and Assignee"
  ];

  var codeblocks = [
    '''This document explains how to describe issues in a way that makes it easier for developers to understand and reproduce issues, and how to test code fixes.

Once you are logged in, follow these steps:

* Find out if the issue you encountered has been reported before:
** If the issue has been reported before and the issue is still open, you can add a description of how you encountered the bug (see guidelines under "Describing the issue", below);
** If the issue was reported in the past and closed, you can reopen it and describe how you encountered the issue. (Alternatively, it is possible to create a new bug and link the old one with the new one.)
* If the issue is new, you can report it by using the "New Issue":/projects/open-bluemine/issues/new from drop down menu in top left "+" button.''',
    "The Redmine &lt;b&gt;setup&lt;/b&gt; used by Bluemine distinguishes between several types of issues. The most important ones are:",
    "Use heading level 4 for each of these sections. You can do this in JIRA by putting h4. in front of the heading text."
  ];

  group('BlockSyntax', () {
    test('test header parser to parse exact title content from document', () {
      var document = Document(blockSyntaxes: [HeaderSyntax()]);
      var nodes = document.parseLines(lines);
      var contents =
          nodes.map((node) => node.textContent).toList(growable: false);
      expect(contents, equals(headers));
    });

    test('test pre formatted and code blocks from document', () {
      var document = Document(blockSyntaxes: [PreFormattedSyntax()]);
      var nodes = document.parseLines(lines);
      var contents =
          nodes.map((node) => node.textContent).toList(growable: false);
      expect(contents, equals(codeblocks));
    });
  });
}
