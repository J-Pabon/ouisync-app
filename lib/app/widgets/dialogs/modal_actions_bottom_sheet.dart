import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';

import '../../../generated/l10n.dart';
import '../../cubits/cubits.dart';
import '../../utils/utils.dart';
import '../widgets.dart';

class DirectoryActions extends StatelessWidget {
  const DirectoryActions({
    required this.context,
    required this.cubit,
  });

  final BuildContext context;
  final RepoCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Fields.bottomSheetHandle(context),
          Fields.bottomSheetTitle(S.current.titleFolderActions),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildAction(
                name: S.current.actionNewFolder,
                icon: Icons.folder_outlined,
                action: () => createFolderDialog(context, cubit)),
            _buildAction(
                name: S.current.actionNewFile,
                icon: Icons.insert_drive_file_outlined,
                action: () async {
                  try {
                    await addFile(context, cubit);
                  } catch (e) {
                    print(
                        ">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.new file action exception $e");
                  }
                })
          ]),
        ]);
  }

  Widget _buildAction({name, icon, action}) => Padding(
        padding: Dimensions.paddingBottomSheetActions,
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: action,
            child: Column(
              children: [
                Icon(
                  icon,
                  size: Dimensions.sizeIconExtraBig,
                ),
                Dimensions.spacingVertical,
                Text(name,
                    style: const TextStyle(fontSize: Dimensions.fontAverage))
              ],
            )),
      );

  void createFolderDialog(context, RepoCubit cubit) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final formKey = GlobalKey<FormState>();

          return ActionsDialog(
            title: S.current.titleCreateFolder,
            body: FolderCreation(
              context: context,
              cubit: cubit,
              formKey: formKey,
            ),
          );
        }).then((newFolder) => {
          if (newFolder.isNotEmpty)
            {
              // If a folder is created, the new folder is returned path; otherwise, empty string.
              Navigator.of(this.context).pop()
            }
        });
  }

  Future<void> addFile(context, RepoCubit repo) async {
    print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 1");
    final dstDir = repo.currentFolder.path;

    print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 1.1 $dstDir");
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withReadStream: true,
      allowMultiple: true,
    );
    print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 2");

    if (result != null) {
      print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 3.1");
      for (final srcFile in result.files) {
        print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 3.2");
        final dstPath = buildDestinationPath(dstDir, srcFile.name);

        if (await repo.exists(dstPath)) {
          print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 3.3");
          final type = await repo.type(dstPath);
          final typeNameForMessage = _getTypeNameForMessage(type);
          print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 3.4");
          showSnackBar(context,
              content:
                  Text(S.current.messageEntryAlreadyExist(typeNameForMessage)));
          continue;
        }

        print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 3.5");
        repo.saveFile(
            filePath: dstPath,
            length: srcFile.size,
            fileByteStream: srcFile.readStream!);
        print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 3.5");
      }
    }
    print(">>>>>>>>>>>>>>>>>>>> modal_action_bottom_sheet.addFile 4");

    Navigator.of(context).pop();
  }

  String _getTypeNameForMessage(EntryType? type) {
    if (type == null) {
      return S.current.messageEntryTypeDefault;
    }

    return type == EntryType.directory
        ? S.current.messageEntryTypeFolder
        : S.current.messageEntryTypeFile;
  }
}
