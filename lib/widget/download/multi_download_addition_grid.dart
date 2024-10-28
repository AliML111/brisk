import 'package:brisk/model/file_metadata.dart';
import 'package:brisk/provider/pluto_grid_check_row_provider.dart';
import 'package:brisk/provider/pluto_grid_util.dart';
import 'package:brisk/provider/theme_provider.dart';
import 'package:brisk/util/readability_util.dart';
import 'package:brisk/util/responsive_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';

class MultiDownloadAdditionGrid extends StatefulWidget {
  Function onDeleteKeyPressed;

  List<FileInfo> files;

  MultiDownloadAdditionGrid({
    super.key,
    required this.files,
    required this.onDeleteKeyPressed,
  });

  @override
  State<MultiDownloadAdditionGrid> createState() => _DownloadGridState();
}

class _DownloadGridState extends State<MultiDownloadAdditionGrid> {
  late List<PlutoColumn> columns;
  late List<PlutoRow> rows;
  PlutoGridCheckRowProvider? plutoProvider;

  @override
  void didChangeDependencies() {
    initColumns(context);
    super.didChangeDependencies();
  }

  void initRows() {
    rows = widget.files
        .map((e) => PlutoRow(
              cells: {
                "file_name": PlutoCell(value: e.fileName),
                "size": PlutoCell(
                  value: convertByteToReadableStr(e.contentLength),
                ),
              },
            ))
        .toList();
  }

  void initColumns(BuildContext context) {
    columns = [
      PlutoColumn(
        enableRowDrag: true,
        enableRowChecked: true,
        width: 490,
        title: 'File Name',
        field: 'file_name',
        type: PlutoColumnType.text(),
        renderer: (rendererContext) =>
            PlutoGridUtil.fileNameColumnRenderer(rendererContext),
      ),
      PlutoColumn(
        readOnly: true,
        width: 105,
        title: 'Size',
        field: 'size',
        type: PlutoColumnType.text(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    initRows();
    final downloadGridTheme =
        Provider.of<ThemeProvider>(context).activeTheme.downloadGridTheme;
    plutoProvider = Provider.of<PlutoGridCheckRowProvider>(
      context,
      listen: false,
    );
    final size = MediaQuery.of(context).size;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: size.height - 70,
        width: resolveWindowWidth(size),
        decoration: const BoxDecoration(color: Colors.black26),
        child: PlutoGrid(
          key: UniqueKey(),
          mode: PlutoGridMode.selectWithOneTap,
          configuration: PlutoGridConfiguration(
            style: PlutoGridStyleConfig.dark(
              activatedBorderColor: Colors.transparent,
              borderColor: downloadGridTheme.borderColor,
              gridBorderColor: downloadGridTheme.borderColor,
              activatedColor: downloadGridTheme.activeRowColor,
              gridBackgroundColor: downloadGridTheme.backgroundColor,
              rowColor: downloadGridTheme.rowColor,
              checkedColor: downloadGridTheme.checkedRowColor,
            ),
          ),
          columns: columns,
          rows: rows,
          onSelected: onSelected,
          onRowChecked: (row) => plutoProvider?.notifyListeners(),
          onLoaded: onLoaded,
        ),
      ),
    );
  }

  void onSelected(event) {
    final stateManger = PlutoGridUtil.plutoStateManager;
    stateManger!.checkedRows.forEach((row) {
      if (row.checkedViaSelect != null && row.checkedViaSelect!) {
        stateManger.setRowChecked(row, false, checkedViaSelect: false);
      }
    });
    if (stateManger.checkedRows.contains(event.row!)) {
      stateManger.setRowChecked(
        event.row!,
        false,
        checkedViaSelect: true,
      );
    } else {
      stateManger.setRowChecked(
        event.row!,
        true,
        checkedViaSelect: true,
      );
    }
    stateManger.notifyListeners();
    plutoProvider?.notifyListeners();
  }

  void onLoaded(event) async {
    PlutoGridUtil.setMultiAdditionStateManager(event.stateManager);
    PlutoGridUtil.multiDownloadAdditionStateManager
        ?.setSelectingMode(PlutoGridSelectingMode.row);
    PlutoGridUtil.multiDownloadAdditionStateManager!.keyManager!.subject.stream
        .listen((event) {
      if (event.isKeyDownEvent &&
          event.event.logicalKey == LogicalKeyboardKey.delete) {
        widget.onDeleteKeyPressed();
      }
    });
  }
}
