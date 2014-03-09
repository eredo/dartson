library dartson.default_transformers;

import './dartson.dart';

part 'transformers/date_time.dart';

void register() {
  registerTransformer(new DateTimeParser<DateTime>());
}