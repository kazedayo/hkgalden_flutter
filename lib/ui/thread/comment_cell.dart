import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentCell extends StatelessWidget {
  final Reply reply;

  CommentCell({this.reply});

  @override
  Widget build(BuildContext context) => Card(
    child: Container(
      padding: EdgeInsets.only(top: 16, left: 16, right: 16),
      //height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AvatarWidget(
                //舊膠登icon死link會炒async #dead#
                avatarImage: reply.author.avatar == '' || reply.author.avatar.contains('476.gif') ? 
                  SvgPicture.asset('assets/icon-hkgalden.svg', width: 30,height: 30) : 
                  CachedNetworkImage(
                    imageUrl: reply.author.avatar, 
                    width: 30,
                    height: 30,
                    fadeInDuration: Duration(milliseconds: 300),
                    fadeOutDuration: Duration(milliseconds: 300),
                  ),
                  userGroup: reply.author.userGroup == null ? [] : reply.author.userGroup,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                reply.authorNickname, 
                style: TextStyle(
                  color: reply.author.gender == 'M' ? Color(0xff22c1fe) : Color(0xffff7aab),
                ),
              ),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('#${reply.floor}'),
                  Text(DateTimeFormat.format(reply.date.toLocal(), format: 'Y/m/d h:i A')),
                ],
              ),
            ],
          ),
          Html(
            data: HKGaldenHtmlParser().commentWithQuotes(reply),
            customRender: {
              'img': (context, child, attributes, node) {
                return CachedNetworkImage(
                  imageUrl: attributes['src'],
                  placeholder: (context, url) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  fadeInDuration: Duration(milliseconds: 300),
                  fadeOutDuration: Duration(milliseconds: 300),
                );
              },
              'color': (context, child, attributes, node) {
                return Text(
                  node.text, 
                  style: ThemeData.dark().textTheme.bodyText2.copyWith(
                    color: Color(int.parse('FF${attributes['hex']}', radix: 16)),
                    fontSize: FontSize.large.size
                  ),
                );
              },
              'icon': (context, child, attributes, node) {
                return CachedNetworkImage(
                  imageUrl: attributes['src'],
                  fadeInDuration: Duration(milliseconds: 300),
                  fadeOutDuration: Duration(milliseconds: 300),
                );
              }
            },
            style: {
              "html" : Style(backgroundColor: Colors.transparent, fontSize: FontSize.large),
              "blockquote" : Style(border: Border(left: BorderSide(color: Colors.grey)), padding: EdgeInsets.only(left: 4), margin: EdgeInsets.only(left: 10)),
            },
            onLinkTap: (url) => _launchURL(url),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(icon: Icon(Icons.format_quote), onPressed: () => null),
              IconButton(icon: Icon(Icons.block), onPressed: () => null),
              IconButton(icon: Icon(Icons.flag), onPressed: () => null),
            ],
          ),
        ],
      ),
    ),
  );

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: true);
    } else {
      throw 'Could not launch $url';
    }
  }
}