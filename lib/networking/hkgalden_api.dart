import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';

class HKGaldenApi {
  static final HttpLink api = HttpLink(uri: 'https://hkgalden.org/_');

  static final AuthLink bearerToken = AuthLink(getToken: () async {
    String tokenString = await TokenSecureStorage().storage.read(key: 'token');
    //print(tokenString);
    return 'Bearer $tokenString';
  });

  static final Link link = bearerToken.concat(api);

  static final String clientId = '15897154848030720.apis.hkgalden.org';

  final GraphQLClient client = GraphQLClient(
    cache: InMemoryCache(),
    link: link,
  );
}
