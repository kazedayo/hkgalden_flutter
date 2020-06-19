import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:url_launcher/url_launcher.dart';

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
                avatarImage: reply.author.avatar == '' ? 
                  Image.asset('assets/default-icon.png', width: 30,height: 30,) : 
                  Image.network(reply.author.avatar, width: 30,height: 30,),
                  userGroup: reply.author.userGroup == null ? [] : reply.author.userGroup,
              ),
              SizedBox(
                width: 5,
              ),
              Text(reply.authorNickname),
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