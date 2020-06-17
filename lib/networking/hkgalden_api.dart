import 'package:graphql/client.dart';

class HKGaldenApi {
  static final HttpLink api = HttpLink(uri: 'https://hkgalden.org/_');
  static final String clientId = '15897154848030720.apis.hkgalden.org';

  final GraphQLClient client = GraphQLClient(
    cache: InMemoryCache(),
    link: api,
  );
}