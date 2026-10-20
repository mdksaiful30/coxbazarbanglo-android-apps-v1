import 'package:flutter_test/flutter_test.dart';
import 'package:coxbanglo/core/session.dart';
import 'package:coxbanglo/core/api.dart';

void main() {
  test('default release server is the production v1 HTTPS API', () {
    expect(Session.defaultApi, Session.productionApi);
    expect(
      Api.normalizeBase('https://coxbazarbanglo.learnwithzaman.com'),
      Session.productionApi,
    );
  });
}
