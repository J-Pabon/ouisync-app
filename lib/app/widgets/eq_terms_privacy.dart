import 'package:flutter/material.dart';

import '../../generated/l10n.dart';
import '../utils/utils.dart';

class EqTermsAndPrivacy extends StatelessWidget {
  const EqTermsAndPrivacy({super.key});

  @override
  Widget build(BuildContext context) => Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
          childrenPadding: EdgeInsets.symmetric(vertical: 20.0),
          title: Text(S.current.messageTapForTermsPrivacy,
              textAlign: TextAlign.end,
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSmall,
                  fontStyle: FontStyle.italic)),
          children: [_temsAndPrivacyTextBlock(context)]));

  Widget _temsAndPrivacyTextBlock(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        RichText(
            textAlign: TextAlign.start,
            text: TextSpan(
                style: TextStyle(
                    color: Colors.black87, fontSize: Dimensions.fontSmall),
                children: [
                  Fields.boldTextSpan('\n${S.current.titleTermsPrivacy}\n',
                      fontSize: Dimensions.fontBig)
                ])),
        RichText(
          text: TextSpan(
            style: TextStyle(
                color: Colors.black87, fontSize: Dimensions.fontSmall),
            children: [
              Fields.boldTextSpan('${S.current.titleOverview}\n\n'),
              TextSpan(text: '${S.current.messageTermsPrivacyP1}.\n\n'),
              TextSpan(text: '${S.current.messageTermsPrivacyP2}.\n\n'),
              Fields.boldTextSpan('${S.current.titleTermsOfUse}\n\n'),
              TextSpan(text: '${S.current.messageTermsPrivacyP3}\n\n'),
              Fields.boldTextSpan('·	'),
              TextSpan(text: S.current.messageTerms1_1),
              Fields.linkTextSpan(
                  context, S.current.messageCanadaPrivacyAct, _launchCPA),
              TextSpan(text: ' ${S.current.messageOr.toLowerCase()} '),
              Fields.linkTextSpan(
                  context, S.current.messagePIPEDA, _launchPIPEDA),
              TextSpan(text: ' ${S.current.messageTerms1_2},\n\n'),
              Fields.boldTextSpan('·	'),
              TextSpan(text: '${S.current.messageTerms2};\n\n'),
              Fields.boldTextSpan('·	'),
              TextSpan(text: '${S.current.messageTerms3};\n\n'),
              Fields.boldTextSpan('·	'),
              TextSpan(text: '${S.current.messageTerms4};\n\n'),
              Fields.boldTextSpan('·	'),
              TextSpan(text: '${S.current.messageTerms5}.\n\n'),
              Fields.boldTextSpan('${S.current.titlePrivacyNotice}\n\n'),
              TextSpan(text: '${S.current.messagePrivacyIntro}.\n\n'),
              Fields.boldTextSpan('${S.current.titleDataCollection}\n\n',
                  fontSize: Dimensions.fontMicro),
              TextSpan(text: '${S.current.messageDataCollectionP1}.\n\n'),
              TextSpan(text: '${S.current.messageDataCollectionP2}.\n\n'),
              Fields.boldTextSpan('${S.current.titleDataSharing}\n\n',
                  fontSize: Dimensions.fontMicro),
              TextSpan(text: '${S.current.messageDataSharingP1}.\n\n'),
              Fields.boldTextSpan('${S.current.titleSecurityPractices}\n\n',
                  fontSize: Dimensions.fontMicro),
              TextSpan(text: '${S.current.messageSecurityPracticesP1}.\n\n'),
              TextSpan(text: '${S.current.messageSecurityPracticesP2}.\n\n'),
              TextSpan(text: '${S.current.messageSecurityPracticesP3}.\n\n'),
              TextSpan(text: '${S.current.messageSecurityPracticesP4}.\n\n'),
              Fields.boldTextSpan('${S.current.titleDeletionDataServer}\n\n',
                  fontSize: Dimensions.fontMicro),
              TextSpan(text: '${S.current.messageDeletionDataServerP1}.\n\n'),
              Fields.italicTextSpan('${S.current.messageNote}: ',
                  fontSize: Dimensions.fontMicro, fontWeight: FontWeight.bold),
              Fields.italicTextSpan(
                  '${S.current.messageDeletionDataServerNote}.\n\n',
                  fontSize: Dimensions.fontMicro),
              Fields.boldTextSpan('${S.current.titleLogData}\n\n'),
              TextSpan(text: '${S.current.messageLogDataP1}.\n\n'),
              TextSpan(text: '${S.current.messageLogDataP2}\n\n'),
              Fields.boldTextSpan('·	'),
              TextSpan(text: '${S.current.messageLogData1};\n\n'),
              Fields.boldTextSpan('·	'),
              TextSpan(text: '${S.current.messageLogData2};\n\n'),
              Fields.boldTextSpan('·	'),
              TextSpan(text: '${S.current.messageLogData3}.\n\n'),
              TextSpan(text: '${S.current.messageLogDataP3}.\n\n'),
              Fields.boldTextSpan('${S.current.titleCookies}\n\n'),
              TextSpan(text: '${S.current.messageCookiesP1}.\n\n'),
              Fields.boldTextSpan('${S.current.titleLinksOtherSites}\n\n'),
              TextSpan(text: '${S.current.messageLinksOtherSitesP1}.\n\n'),
              Fields.boldTextSpan('${S.current.titleChildrensPrivacy}\n\n'),
              TextSpan(text: '${S.current.messageChildrensPolicyP1}.\n\n'),
              Fields.boldTextSpan('${S.current.titleChangesToTerms}\n\n'),
              TextSpan(text: '${S.current.messageChangesToTermsP1}.\n\n'),
              TextSpan(text: '${S.current.messageChangesToTermsP2}.\n\n'),
              Fields.boldTextSpan('${S.current.titleContactUs}\n\n'),
              TextSpan(text: '${S.current.messageContatUsP1} '),
              Fields.linkTextSpan(
                  context, Constants.supportEmail, (context) {}),
              TextSpan(text: '.'),
            ],
          ),
        )
      ]);

  void _launchCPA(BuildContext context) async {
    final title = Text(S.current.messageCanadaPrivacyAct);
    await Fields.openUrl(context, title, Constants.canadaPrivacyAct);
  }

  void _launchPIPEDA(BuildContext context) async {
    final title = Text(S.current.titlePIPEDA);
    await Fields.openUrl(context, title, Constants.pipedaUrl);
  }
}