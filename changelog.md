# Changelog

## 0.2.5 (7/10/2015)
- Added support for polymorphic relationships (inheritance) and dynamic root objects.

## 0.2.4 (6/26/2015)
- Added (circular) reference support
- Fixed using package prefix for generated sources (transformer)

## 0.2.3 (5/25/2015)
- Updated analyzer and test dependency (thanks to @rightisleft)

## 0.2.1 (2/10/2015)
- Changed the default DateTime serialized format to ISO 8601 with Z notation.

## 0.2.0 (1/29/2015)
- Added a transformer that generates static serialization rules and does not use mirrors.
- Breaking changes:
  - You now have to instantiate a Dartson instance instead of relying on global functions.
  - You now add custom transformer to the Dartson instance instead of adding them globally.

## 0.1.6 (6/05/2014)
- Added dartson.fill function
- Compatible to dart 1.4+

## 0.1.5 (3/14/2014)
- Added dartson.TypeTransformer see [README.md](./README.md)
- Added package:dartson/default_transformers.dart

## 0.1.4
- Fixed @MirrorsUsed annotations
- Added map and mapList functions to use an already parsed map
