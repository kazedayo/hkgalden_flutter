part of '../compose_page.dart';

class _TagSelectDialog extends StatelessWidget {
  final Function(Tag, String) onTagSelect;

  const _TagSelectDialog({required this.onTagSelect});

  @override
  Widget build(BuildContext context) {
    final ChannelLoaded state =
        BlocProvider.of<ChannelBloc>(context).state as ChannelLoaded;
    return SingleChildScrollView(
      //padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: state.channels
            .map(
              (channel) => Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(channel.channelName,
                        style: Theme.of(context)
                            .textTheme
                            .caption!
                            .copyWith(color: Colors.white60)),
                    Wrap(
                      spacing: 8,
                      children: channel.tags
                          .map(
                            (tag) => InputChip(
                              label: Text('#${tag.name}',
                                  strutStyle: const StrutStyle(height: 1.25),
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                              backgroundColor: tag.color,
                              onPressed: () {
                                onTagSelect(tag, channel.channelId);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
