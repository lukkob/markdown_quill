import 'package:charcode/charcode.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Node;
import 'package:markdown/markdown.dart' as md;

/// Parses markdown table and saves the table markdown content into the element attributes.
class EmbeddableTableSyntax extends md.BlockSyntax {
  static const _base = md.TableSyntax();

  @override
  bool canEndBlock(md.BlockParser parser) => false;

  @override
  RegExp get pattern => _base.pattern;

  /// @nodoc
  const EmbeddableTableSyntax();

  @override
  bool canParse(md.BlockParser parser) => _base.canParse(parser);

  /// Parses a table into its three parts:
  ///
  /// * a head row of head cells (`<th>` cells)
  /// * a divider of hyphens and pipes (not rendered)
  /// * many body rows of body cells (`<td>` cells)
  @override
  md.Node? parse(md.BlockParser parser) {
    final columnCount = _columnCount(parser.next!);
    final headCells = _columnCount(parser.current);
    final valBuf = StringBuffer('${parser.current}\n${parser.next!}');
    parser.advance();
    if (columnCount != headCells) {
      return null;
    }

    // advance header and divider of hyphens.
    parser.advance();

    while (!parser.isDone && !md.BlockSyntax.isAtBlockEnd(parser)) {
      valBuf.write('\n${parser.current}');
      parser.advance();
    }

    return md.Element.empty(EmbeddableTable.tableType)
      ..attributes['data'] = valBuf.toString();
  }

  int _columnCount(md.Line line) {
    final startIndex = _walkPastOpeningPipe(line.content);

    var endIndex = line.content.length - 1;
    while (endIndex > 0) {
      final ch = line.content.codeUnitAt(endIndex);
      if (ch == $pipe) {
        endIndex--;
        break;
      }
      if (ch != $space && ch != $tab) {
        break;
      }
      endIndex--;
    }

    return line.content.substring(startIndex, endIndex + 1).split('|').length;
  }

  int _walkPastWhitespace(String line, int index) {
    while (index < line.length) {
      final ch = line.codeUnitAt(index);
      if (ch != $space && ch != $tab) {
        break;
      }
      //ignore: parameter_assignments
      index++;
    }
    return index;
  }

  int _walkPastOpeningPipe(String line) {
    var index = 0;
    while (index < line.length) {
      final ch = line.codeUnitAt(index);
      if (ch == $pipe) {
        index++;
        index = _walkPastWhitespace(line, index);
      }
      if (ch != $space && ch != $tab) {
        // No leading pipe.
        break;
      }
      index++;
    }
    return index;
  }
}

/// An [Embeddable] table that can used to render a table in quill_editor
class EmbeddableTable extends BlockEmbed {
  /// [Embeddable] type
  static const tableType = 'x-embed-table';

  /// @nodoc
  EmbeddableTable(String data) : super(tableType, data);

  /// Create from markdown.
  //ignore: prefer_constructors_over_static_methods
  static EmbeddableTable fromMdSyntax(Map<String, String> attributes) =>
      EmbeddableTable(attributes['data']!);

  /// Outputs table markdown to output.
  static void toMdSyntax(Embed embed, StringSink out) {
    out
      ..writeln(embed.value.data)
      ..writeln();
  }
}
