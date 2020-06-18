import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/ui/home/compose_page.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page.dart';
import 'package:hkgalden_flutter/viewmodels/home_page_view_model.dart';
class HomePage extends StatelessWidget {
  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, HomePageViewModel>(
      converter: (store) => HomePageViewModel.create(store),
      distinct: true,
      builder: (BuildContext context, HomePageViewModel viewModel) => Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Spacer(flex: 1),
              Hero(tag: 'logo', child: SizedBox(child: SvgPicture.asset('assets/icon-hkgalden.svg'), width: 25, height: 25)),
              SizedBox(width: 5),
              Text(viewModel.title, style: TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
              Spacer(flex: 2),
            ],
          ),
          //leading: SvgPicture.asset('assets/icon-hkgalden.svg'),
        ),
        body: viewModel.isThreadLoading && viewModel.isRefresh == false ? 
          Center(
            child: CircularProgressIndicator(),
          ) : 
          RefreshIndicator(
          onRefresh: () => viewModel.onRefresh(viewModel.selectedChannelId),
          child: ListView.separated(
            separatorBuilder: (context, index) => Divider(indent: 8,height: 1,thickness: 1,),
            itemCount: viewModel.threads.length,
            itemBuilder: (context, index) => InkWell(
              child: ThreadCell(
                title: viewModel.threads[index].title,
                authorName: viewModel.threads[index].replies[0].authorNickname,
                totalReplies: viewModel.threads[index].totalReplies,
                lastReply: viewModel.threads[index].replies.length == 2 ? 
                            viewModel.threads[index].replies[1].date : 
                            viewModel.threads[index].replies[0].date,
              ),
              onTap: () {
                store.dispatch(RequestThreadAction(threadId: viewModel.threads[index].threadId));
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => ThreadPage(
                      title: viewModel.threads[index].title,
                      threadId: viewModel.threads[index].threadId,
                    )
                  )
                );
              }
            ),
          ),
        ),
        drawer: HomeDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(SlideInFromBottomRoute(page: ComposePage())),
          child: Icon(Icons.create),
        ),
      ),
    );
  }
}