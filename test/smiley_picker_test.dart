import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/models/smiley.dart';
import 'package:hkgalden_flutter/models/smiley_pack.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/repository/smiley_pack_repository.dart';
import 'package:hkgalden_flutter/utils/smiley_embed.dart';

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

      expect(packs, hasLength(2));
      expect(packs.first.id, 'hkg');
      expect(packs.first.smilies, hasLength(2));
      expect(packs.first.smilies.first.id, 'A7WUrp9FZ62');
      expect(packs.last.id, 'animal');
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

    test('empty pack list has no default (logged-out case)', () {
      expect(selectDefaultSmileyPackId(const []), isNull);
    });

    test('findSmileyPackById matches id or returns null', () {
      expect(findSmileyPackById(_kPacks, 'hkg'), _kPacks.first);
      expect(findSmileyPackById(_kPacks, 'missing'), isNull);
      expect(findSmileyPackById(_kPacks, null), isNull);
    });
  });

  group('insert → delta → DeltaJsonParser.toGaldenHtml (shipped path)', () {
    late DeltaJsonParser parser;

    setUp(() {
      parser = DeltaJsonParser();
    });

    test(
      'SmileyEmbed.payload produces complete Galden smiley HTML',
      () async {
        final op = {
          'insert': {SmileyEmbed.type: SmileyEmbed.payload(_kPackId, _kSosad)},
        };
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

    test('clearCache drops cache; late in-flight completion may repopulate', () async {
      final completer = Completer<List<SmileyPack>?>();
      final repo = _FakeSmileyPackRepository(() => completer.future);

      final pending = repo.getInstalledPacks();
      repo.clearCache();
      completer.complete(_kPacks);
      await pending;

      // No generation guard: the completion lands in the fresh cache.
      expect(repo.cachedPacks, _kPacks);
    });
  });
}
