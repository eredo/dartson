import '../lib/dartson.dart';
import 'package:unittest/unittest.dart';
import 'test_dartson.dart';


@MirrorsUsed(targets: const[
  'test_dartson'
  ],
  override: '*')
import 'dart:mirrors';


void main() {
    test('parse: DateTime', () {
      var date = new DateTime.now();
      var ctg = parse('{"testDate":"${date.toString()}"}', SimpleDateContainer);
      expect(ctg.testDate is DateTime, true);
      expect(ctg.testDate == date, true);
    });
}