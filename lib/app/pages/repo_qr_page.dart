import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ouisync/ouisync.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../generated/l10n.dart';
import '../utils/utils.dart'
    show AppThemeExtension, Dimensions, Fields, ThemeGetter;
import '../widgets/widgets.dart' show DirectionalAppBar;

class RepositoryQRPage extends StatelessWidget {
  const RepositoryQRPage({
    required this.repoName,
    required this.accessMode,
    required this.shareLink,
    super.key,
  });

  final String repoName;
  final AccessMode accessMode;
  final String shareLink;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: DirectionalAppBar(
          leading: Fields.actionIcon(
            const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
        ),
        backgroundColor: Theme.of(context).primaryColorDark,
        body: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRepoID(context),
                _getQRCodeImage(context, shareLink),
                _buildShareMessage(context),
              ],
            ),
          ),
        ),
      );

  Widget _buildRepoID(BuildContext context) {
    return Column(
      children: [
        Text(
          '\'$repoName\'',
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.theme.appTextStyle.titleLarge
              .copyWith(color: Colors.white),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(bottom: 20.0),
          child: Text(
            accessMode.name,
            textAlign: TextAlign.center,
            style: context.theme.appTextStyle.bodyMedium
                .copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _getQRCodeImage(BuildContext context, String tokenLink) {
    double qrCodeSize = 0.0;
    qrCodeSize = (Platform.isAndroid || Platform.isIOS
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.height) *
        0.6;

    final qrCodeImage = QrImageView(
      data: tokenLink,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      size: qrCodeSize,
    );

    return Container(
        decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                width: Dimensions.borderQRCodeImage,
                color: Colors.white,
              ),
              top: BorderSide(
                width: Dimensions.borderQRCodeImage,
                color: Colors.white,
              ),
              end: BorderSide(
                width: Dimensions.borderQRCodeImage,
                color: Colors.white,
              ),
              bottom: BorderSide(
                width: Dimensions.borderQRCodeImage,
                color: Colors.white,
              ),
            ),
            borderRadius: BorderRadiusDirectional.circular(
              Dimensions.radiusSmall,
            ),
            color: Colors.white),
        child: qrCodeImage);
  }

  Widget _buildShareMessage(BuildContext context) {
    return Padding(
      padding: Dimensions.paddingTop40,
      child: Column(
        children: [
          Text(
            S.current.messageShareWithWR,
            textAlign: TextAlign.center,
            style: context.theme.appTextStyle.titleLarge
                .copyWith(color: Colors.white),
          ),
          Dimensions.spacingVertical,
          Text(
            S.current.messageScanQROrShare,
            textAlign: TextAlign.center,
            style: context.theme.appTextStyle.bodyMedium
                .copyWith(color: Colors.white),
          )
        ],
      ),
    );
  }
}
