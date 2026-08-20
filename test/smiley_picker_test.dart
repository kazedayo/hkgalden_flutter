import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/models/smiley.dart';
import 'package:hkgalden_flutter/models/smiley_pack.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/repository/smiley_pack_repository.dart';
import 'package:hkgalden_flutter/utils/smiley_cdn.dart';
import 'package:hkgalden_flutter/utils/smiley_embed.dart';
import 'package:hkgalden_flutter/utils/smiley_pack_selection.dart';

/// Representative smiley matching models / web pack data shape.
const _kSosad = Smiley(
  id: 'A7WUrp9FZ62',
  alt: '[sosad]',
  width: 21,
  height: 17,
);

const _kPackId = 'hkg';

final _kPacks = [
  SmileyPack(
    id: _kPackId,
    title: 'HKG',
    smilies: const [_kSosad],
  ),
];

class _FakeSmileyPackRepository extends SmileyPackRepository {
  _FakeSmileyPackRepository(this._handler);

  final Future<List<SmileyPack>?> Function() _handler;
  int fetchCount = 0;

  @override
  Future<List<SmileyPack>?> fetchInstalledPacks() {
    fetchCount++;
    return _handler();
  }
}

void main() {
  group('smileyGifUrl (shipped CDN helper)', () {
    test('builds https://s.hkgalden.org/smilies/{packId}/{id}.gif', () {
      final url = smileyGifUrl(packId: _kPackId, smileyId: _kSosad.id);
      expect(url, 'https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif');
      expect(url, startsWith('https://s.hkgalden.org/smilies/'));
      expect(url, endsWith('.gif'));
    });
  });

  group('SmileyPack / Smiley model parsing (installedPacks shape)', () {
    test('parses GraphQL-shaped installedPacks fixture', () {
      const fixture = {
        'installedPacks': [
          {
            'id': 'hkg',
            'title': 'HKG',
            'smilies': [
              {
                'id': 'A7WUrp9FZ62',
                'alt': '[sosad]',
                'width': 21,
                'height': 17,
              },
              {
                'id': 'otherId',
                'alt': '[other]',
                'width': 30,
                'height': 30,
              },
            ],
          },
          {
            'id': 'animal',
            'title': 'Animal',
            'smilies': [
              {
                'id': 'cat1',
                'alt': '[cat]',
                'width': 40,
                'height': 40,
              },
            ],
          },
        ],
      };

      final packs = (fixture['installedPacks'] as List)
          .map((e) => SmileyPack.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(packs, isNotEmpty);
      expect(packs.length, 2);
      expect(packs.first.id, 'hkg');
      expect(packs.first.title, 'HKG');
      expect(packs.first.smilies, isNotEmpty);
      expect(packs.first.smilies.first.id, 'A7WUrp9FZ62');
      expect(packs.first.smilies.first.alt, '[sosad]');
      expect(packs.first.smilies.first.width, 21);
      expect(packs.first.smilies.first.height, 17);

      final gif = smileyGifUrl(
        packId: packs.first.id,
        smileyId: packs.first.smilies.first.id,
      );
      expect(gif, 'https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif');
    });

    test('empty installedPacks yields empty list (logged-out case)', () {
      const fixture = {'installedPacks': <dynamic>[]};
      final packs = (fixture['installedPacks'] as List)
          .map((e) => SmileyPack.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(packs, isEmpty);
      expect(selectDefaultSmileyPackId(packs), isNull);
    });
  });

  group('default pack selection', () {
    test('defaults to hkg when present', () {
      final packs = [
        const SmileyPack(id: 'animal', title: 'A', smilies: []),
        const SmileyPack(id: 'hkg', title: 'HKG', smilies: []),
        const SmileyPack(id: 'other', title: 'O', smilies: []),
      ];
      expect(selectDefaultSmileyPackId(packs), 'hkg');
    });

    test('falls back to first pack when hkg missing', () {
      final packs = [
        const SmileyPack(id: 'animal', title: 'A', smilies: []),
        const SmileyPack(id: 'other', title: 'O', smilies: []),
      ];
      expect(selectDefaultSmileyPackId(packs), 'animal');
    });
  });

  group('insert → delta → DeltaJsonParser.toGaldenHtml (shipped path)', () {
    late DeltaJsonParser parser;

    setUp(() {
      parser = DeltaJsonParser();
    });

    test(
      'SmileyEmbed.toDeltaOp produces complete Galden smiley HTML',
      () async {
        final op = SmileyEmbed.toDeltaOp(_kPackId, _kSosad);
        // Real controller path ends as JSON list of ops + trailing newline.
        final deltaJson = <dynamic>[
          op,
          {'insert': '\n'},
        ];

        final html = await parser.toGaldenHtml(deltaJson);

        expect(html, contains('data-nodetype="smiley"'));
        expect(html, contains('data-id="A7WUrp9FZ62"'));
        expect(html, contains('data-pack-id="hkg"'));
        expect(html, contains('data-sx="21"'));
        expect(html, contains('data-sy="17"'));
        expect(html, contains('data-alt="[sosad]"'));
        expect(
          html,
          contains(
            '<span data-nodetype="smiley" data-id="A7WUrp9FZ62" '
            'data-pack-id="hkg" data-sx="21" data-sy="17" '
            'data-alt="[sosad]"></span>',
          ),
        );
      },
    );

    test(
      'QuillController insertInto → document delta → toGaldenHtml',
      () async {
        final controller = QuillController.basic();
        // Ensure selection at start of empty doc
        controller.updateSelection(
          const TextSelection.collapsed(offset: 0),
          ChangeSource.local,
        );

        SmileyEmbed.insertInto(controller, _kPackId, _kSosad);

        final delta = controller.document.toDelta();
        final deltaJson = json.decode(json.encode(delta)) as List<dynamic>;

        // Document must contain a smiley embed payload from the real insert API.
        final hasSmileyInsert = deltaJson.any((op) {
          if (op is! Map) return false;
          final insert = op['insert'];
          if (insert is! Map) return false;
          final smiley = insert['smiley'];
          if (smiley is! Map) return false;
          return smiley['id'] == _kSosad.id &&
              smiley['packId'] == _kPackId &&
              smiley['width'] == _kSosad.width &&
              smiley['height'] == _kSosad.height &&
              smiley['alt'] == _kSosad.alt;
        });
        expect(hasSmileyInsert, isTrue,
            reason: 'controller document must contain smiley embed payload');

        final html = await parser.toGaldenHtml(deltaJson);

        expect(html, contains('data-nodetype="smiley"'));
        expect(html, contains('data-id="${_kSosad.id}"'));
        expect(html, contains('data-pack-id="$_kPackId"'));
        expect(html, contains('data-sx="${_kSosad.width}"'));
        expect(html, contains('data-sy="${_kSosad.height}"'));
        expect(html, contains('data-alt="${_kSosad.alt}"'));

        controller.dispose();
      },
    );

    test(
      'quill image embed insert shape still produces img HTML',
      () async {
        final sizedParser = DeltaJsonParser(
          imageSizeResolver: (url) async => (width: 100, height: 50),
        );
        final html = await sizedParser.toGaldenHtml([
          {
            'insert': {'image': 'https://example.com/pic.png'},
          },
          {'insert': '\n'},
        ]);
        expect(html, contains('data-nodetype="img"'));
        expect(html, contains('data-src="https://example.com/pic.png"'));
        expect(html, contains('data-sx="100"'));
        expect(html, contains('data-sy="50"'));
      },
    );
  });

  group('SmileyPackRepository cache / prewarm', () {
    test('first fetch is cached for later getInstalledPacks / cachedPacks',
        () async {
      final repo = _FakeSmileyPackRepository(() async => _kPacks);

      final first = await repo.getInstalledPacks();
      final second = await repo.getInstalledPacks();

      expect(first, _kPacks);
      expect(identical(first, second), isTrue);
      expect(identical(repo.cachedPacks, _kPacks), isTrue);
      expect(repo.fetchCount, 1);
    });

    test('concurrent getInstalledPacks share one in-flight fetch', () async {
      final completer = Completer<List<SmileyPack>?>();
      final repo = _FakeSmileyPackRepository(() => completer.future);

      final first = repo.getInstalledPacks();
      final second = repo.getInstalledPacks();
      expect(repo.fetchCount, 1);

      completer.complete(_kPacks);
      expect(await first, _kPacks);
      expect(await second, _kPacks);
      expect(repo.fetchCount, 1);
    });

    test('prewarm populates cachedPacks without awaiting', () async {
      final repo = _FakeSmileyPackRepository(() async => _kPacks);
      expect(repo.cachedPacks, isEmpty);

      repo.prewarm();
      expect(repo.fetchCount, 1);
      expect(repo.cachedPacks, isEmpty);

      await repo.getInstalledPacks();
      expect(repo.cachedPacks, _kPacks);
      expect(repo.fetchCount, 1);
    });

    test('null fetch is not cached so a later call retries', () async {
      var calls = 0;
      final repo = _FakeSmileyPackRepository(() async {
        calls++;
        if (calls == 1) return null;
        return _kPacks;
      });

      expect(await repo.getInstalledPacks(), isNull);
      expect(repo.cachedPacks, isEmpty);
      expect(await repo.getInstalledPacks(), _kPacks);
      expect(repo.cachedPacks, _kPacks);
      expect(repo.fetchCount, 2);
    });

    test('clearCache drops cached packs so the next call refetches', () async {
      final repo = _FakeSmileyPackRepository(() async => _kPacks);
      await repo.getInstalledPacks();
      repo.clearCache();
      expect(repo.cachedPacks, isEmpty);

      await repo.getInstalledPacks();
      expect(repo.fetchCount, 2);
      expect(repo.cachedPacks, _kPacks);
    });

    test('clearCache ignores an in-flight completion', () async {
      final completer = Completer<List<SmileyPack>?>();
      final repo = _FakeSmileyPackRepository(() => completer.future);

      final pending = repo.getInstalledPacks();
      repo.clearCache();
      completer.complete(_kPacks);
      await pending;

      expect(repo.cachedPacks, isEmpty);
    });
  });

  group('compose UI structural wiring', () {
    test('compose tree sources declare smiley pane + insert path', () {
      final composePage =
          File('lib/ui/common/compose_page/compose_page.dart').readAsStringSync();
      final smileyPane =
          File('lib/ui/common/compose_page/widgets/smiley_pane.dart')
              .readAsStringSync();
      final richEditor =
          File('lib/ui/common/compose_page/widgets/rich_text_editor.dart')
              .readAsStringSync();
      final api =
          File('lib/networking/hkgalden_api.dart').readAsStringSync();
      final repo = File('lib/repository/smiley_pack_repository.dart')
          .readAsStringSync();
      final startup =
          File('lib/ui/startup_screen.dart').readAsStringSync();
      final login = File('lib/ui/home/widgets/home_page_app_bar.dart')
          .readAsStringSync();
      final logout =
          File('lib/ui/home/widgets/home_page_popup_menu_button.dart')
              .readAsStringSync();

      expect(composePage.contains("part 'widgets/smiley_pane.dart'"), isTrue);
      expect(composePage.contains('SmileyPackRepository'), isTrue);
      expect(composePage.contains('_smileyPacks'), isTrue);
      expect(composePage.contains('cachedPacks'), isTrue,
          reason: 'compose must seed packs from repository cache on first frame');

      expect(repo.contains('prewarm'), isTrue);
      expect(repo.contains('cachedPacks'), isTrue);
      expect(repo.contains('clearCache'), isTrue);
      expect(startup.contains('.prewarm()'), isTrue,
          reason: 'startup with a token should prewarm packs before compose');
      expect(login.contains('.prewarm()'), isTrue,
          reason: 'login should prewarm packs for the next compose');
      expect(logout.contains('.clearCache()'), isTrue,
          reason: 'logout must drop another user\'s cached packs');

      expect(smileyPane.contains('_SmileyPane'), isTrue);
      expect(smileyPane.contains('SmileyEmbed.insertInto'), isTrue);
      expect(smileyPane.contains('smileyGifUrl'), isTrue);
      expect(smileyPane.contains('selectDefaultSmileyPackId'), isTrue);
      expect(smileyPane.contains('packs'), isTrue);
      expect(smileyPane.contains('smilies'), isTrue);
      // Nested scrolls must not join the bar-modal PrimaryScrollController
      // (otherwise pane scroll drives the compose-sheet dismiss gesture).
      expect(smileyPane.contains('primary: false'), isTrue);
      expect(smileyPane.contains('NotificationListener<ScrollNotification>'),
          isTrue);
      expect(smileyPane.contains('_packsScrollController'), isTrue);
      expect(smileyPane.contains('_smiliesScrollController'), isTrue);

      expect(richEditor.contains('_SmileyPane'), isTrue);
      expect(richEditor.contains('_SmileyEmbedBuilder'), isTrue);
      expect(richEditor.contains('SmileyEmbed.type'), isTrue);
      // Custom-keyboard behavior: not always on-screen; toggled + suppresses IME.
      expect(richEditor.contains('_smileyKeyboardOpen'), isTrue);
      expect(richEditor.contains('_toggleSmileyKeyboard'), isTrue);
      expect(richEditor.contains('controller.readOnly = open'), isTrue);
      expect(richEditor.contains("TextInput.hide"), isTrue);
      expect(richEditor.contains('onToggleSmileyKeyboard'), isTrue);
      expect(
        richEditor.contains('if (canShowSmiley)'),
        isTrue,
        reason: 'smiley pane must only build when keyboard mode is open',
      );

      final toolbar =
          File('lib/ui/common/compose_page/widgets/rich_text_toolbar.dart')
              .readAsStringSync();
      expect(toolbar.contains('onToggleSmileyKeyboard'), isTrue);
      expect(toolbar.contains('emoji_emotions'), isTrue);
      expect(toolbar.contains('keyboard_rounded'), isTrue);

      expect(api.contains('installedPacks'), isTrue);
      expect(api.contains('getInstalledPacksQuery'), isTrue);
    });

    testWidgets(
      'picker selection calls real insert path and document holds smiley embed',
      (tester) async {
        final controller = QuillController.basic();
        controller.updateSelection(
          const TextSelection.collapsed(offset: 0),
          ChangeSource.local,
        );

        final packs = [
          SmileyPack(
            id: 'hkg',
            title: 'HKG',
            smilies: const [_kSosad],
          ),
          const SmileyPack(
            id: 'animal',
            title: 'Animal',
            smilies: [
              Smiley(id: 'cat1', alt: '[cat]', width: 40, height: 40),
            ],
          ),
        ];

        // Drive the same insert path the pane uses (SmileyEmbed.insertInto).
        // Full ComposePage pump needs app providers/dotenv; this focused test
        // exercises the real shipped insert + payload shape used by the pane.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      TextButton(
                        key: const Key('insert_sosad'),
                        onPressed: () {
                          final packId =
                              selectDefaultSmileyPackId(packs) ?? packs.first.id;
                          final pack =
                              findSmileyPackById(packs, packId) ?? packs.first;
                          SmileyEmbed.insertInto(
                            controller,
                            pack.id,
                            pack.smilies.first,
                          );
                        },
                        child: const Text('insert'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('insert_sosad')));
        await tester.pump();

        final deltaJson =
            json.decode(json.encode(controller.document.toDelta()))
                as List<dynamic>;
        final smileyOps = deltaJson.where((op) {
          if (op is! Map) return false;
          final insert = op['insert'];
          return insert is Map && insert['smiley'] != null;
        }).toList();

        expect(smileyOps, isNotEmpty);
        final payload =
            (smileyOps.first as Map)['insert']['smiley'] as Map<String, dynamic>;
        expect(payload['id'], _kSosad.id);
        expect(payload['packId'], 'hkg');
        expect(payload['width'], 21);
        expect(payload['height'], 17);
        expect(payload['alt'], '[sosad]');

        final html = await DeltaJsonParser().toGaldenHtml(deltaJson);
        expect(html, contains('data-nodetype="smiley"'));
        expect(html, contains('data-id="A7WUrp9FZ62"'));
        expect(html, contains('data-pack-id="hkg"'));

        controller.dispose();
      },
    );
  });
}
