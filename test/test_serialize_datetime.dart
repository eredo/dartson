import '../lib/dartson.dart';
import 'package:unittest/unittest.dart';
import 'test_dartson.dart';


@MirrorsUsed(targets: const[
  'test_dartson'
  ],
  override: '*')
import 'dart:mirrors';

void main() {

    test('serialize: DateTime', () {
      var obj = new SimpleDateContainer();
      obj.testDate = new DateTime.now();
      var str = serialize(obj);
      print(str);
      expect(str, '{"testDate":"${obj.testDate.toIso8601String()}"}');
    });

}