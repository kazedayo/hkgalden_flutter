import 'package:graphql/client.dart';

class HKGaldenApi {
  static final HttpLink api = HttpLink(uri: 'https://hkgalden.org/_');

  final GraphQLClient client = GraphQLClient(
    cache: InMemoryCache(),
    link: api,
  );
}