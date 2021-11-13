import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_whatsapp_stickers/flutter_whatsapp_stickers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_stickers_flutter/components/ReusableImage.dart';
import 'package:whatsapp_stickers_flutter/modals/InstallStickersModal.dart';
import 'package:whatsapp_stickers_flutter/modals/StickerListModal.dart';
import 'package:whatsapp_stickers_flutter/utils/utils.dart';
import '../services/ads_manager.dart';

import 'StickerPackInformation.dart';

class StickerList extends StatefulWidget {
  BannerAd banner;

  StickerList({this.banner});
  @override
  _StickerListState createState() => _StickerListState();
}

class _StickerListState extends State<StickerList> {
  final WhatsAppStickers whatsAppStickers = WhatsAppStickers();

  void _loadStickers() async {
    String data =
        await rootBundle.loadString("sticker_packs/sticker_packs.json");
    final response = json.decode(data);

    for (int i = 0; i < response['sticker_packs'].length; i++) {
      Provider.of<StickerListModel>(context, listen: false)
          .addSticker(response['sticker_packs'][i]);
    }
    _checkInstallationStatuses();
  }

  void _checkInstallationStatuses() async {
    print(
        "Total Stickers : ${Provider.of<StickerListModel>(context, listen: false).stickerListSize}");
    for (var j = 0;
        j <
            Provider.of<StickerListModel>(context, listen: false)
                .stickerListSize;
        j++) {
      var tempName = Provider.of<StickerListModel>(context, listen: false)
          .getStickerList[j]['identifier'];
      bool tempInstall =
          await WhatsAppStickers().isStickerPackInstalled(tempName);

      if (tempInstall == true) {
        if (!Provider.of<InstallStickersModal>(context, listen: false)
            .installStickers
            .contains(tempName)) {
          Provider.of<InstallStickersModal>(context, listen: false)
              .add(tempName);
        }
      } else {
        if (Provider.of<InstallStickersModal>(context, listen: false)
            .installStickers
            .contains(tempName)) {
          Provider.of<InstallStickersModal>(context, listen: false)
              .remove(tempName);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStickers();
    AdsManager.createInterAd();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => SystemNavigator.pop(),
      child: Consumer<StickerListModel>(
        builder: (context, sticker, child) {
          return ListView.separated(
            scrollDirection: Axis.vertical,
            // shrinkWrap: true,
            itemCount: sticker.stickerListSize,
            itemBuilder: (context, index) {
              if (sticker.stickerListSize == 0) {
                return Container(
                  child: CircularProgressIndicator(),
                );
              } else {
                var stickerId = sticker.getStickerList[index]['identifier'];
                var stickerName = sticker.getStickerList[index]['name'];
                var stickerPublisher =
                    sticker.getStickerList[index]['publisher'];
                var stickerTrayIcon =
                    sticker.getStickerList[index]['tray_image_file'];
                var tempStickerList = List();
                var stickers = sticker.getStickerList[index]['stickers'];

                bool stickerInstalled = false;
                if (Provider.of<InstallStickersModal>(context, listen: false)
                    .installStickers
                    .contains(stickerId)) {
                  stickerInstalled = true;
                } else {
                  stickerInstalled = false;
                }
                tempStickerList
                    .add(sticker.getStickerList[index]['identifier']);
                tempStickerList.add(sticker.getStickerList[index]['name']);
                tempStickerList.add(sticker.getStickerList[index]['publisher']);
                tempStickerList
                    .add(sticker.getStickerList[index]['tray_image_file']);
                tempStickerList.add(sticker.getStickerList[index]['stickers']);
                tempStickerList.add(stickerInstalled);
                tempStickerList.add(
                    Provider.of<InstallStickersModal>(context, listen: false)
                        .installStickers);

                return stickerPack(
                  tempStickerList,
                  stickers,
                  stickerName,
                  stickerPublisher,
                  stickerId,
                  stickerTrayIcon,
                  stickerInstalled,
                );
              }
            },
            separatorBuilder: (_, __) => Divider(),
          );
        },
      ),
    );
  }

  Widget stickerPack(
      List stickerList,
      List stickers,
      String name,
      String publisher,
      String identifier,
      String stickerTrayIcon,
      bool installed) {
    Widget depInstallWidget;

    List<Widget> images = [];

    for (int i = 0; i < 5; i++) {
      images.add(
        ReusableImage(
          imagePath: "sticker_packs/$identifier/${stickers[i]['image_file']}",
        ),
      );
      images.add(SizedBox(
        width: 5,
      ));
    }

    if (installed == true) {
      depInstallWidget = IconButton(
        icon: Icon(
          Icons.check,
        ),
        color: Colors.teal,
        tooltip: 'Add Sticker to WhatsApp',
        onPressed: () {},
      );
    } else {
      depInstallWidget = IconButton(
        icon: Icon(
          Icons.add,
        ),
        color: Colors.teal,
        tooltip: 'Add Sticker to WhatsApp',
        onPressed: () async {
          // heeeerrrrreeeee <=x=>
          print("interrrr ===========> 1");
          
          whatsAppStickers.addStickerPack(
            packageName: WhatsAppPackage.Consumer,
            stickerPackIdentifier: identifier,
            stickerPackName: name,
            listener: (action, result, {error}) => processResponse(
              action: action,
              result: result,
              error: error,
              successCallback: () async {
                 AdsManager.showInter();
                _checkInstallationStatuses();
              },
              context: context,
            ),
          );
          AdsManager.createInterAd();
        },
      );
    }

    return Container(
      padding: EdgeInsets.all(10.0),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) =>
                StickerPackInformation(stickerList, widget.banner),
          ));
        },
        title: Row(
          children: [
            Text(
              "$name",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.lightGreen),
            ),
            SizedBox(
              width: 5,
            ),
            Text("$publisher",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        subtitle: Row(
          children: images,
        ),
        trailing: Column(
          children: <Widget>[
            depInstallWidget,
          ],
        ),
      ),
    );
  }
}
