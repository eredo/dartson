# Changelog

## 1.0.0-alpha+2 (09/17/2018)

- Add replacement functionality
- Add `encodeList` and `decodeList` for de/serializing lists directly
- Fix #51 by adding latest version constrain

## 1.0.0-alpha+1 (09/10/2018)

- Add `extend` method to `Dartson` to extend a serializer
- Fix bug where `codec` is always set to null

**Breaking changes**

- Codec usage is now different, please see `README.md`
- `DartsonEntityNotExistsException` renamed to `UnknownEntityException`
- `NoDeserializeMethodOnTypeTransformer` renamed to `MissingDecodeMethodException`
- `NoSerializeMethodOnTypeTransformer` renamed to `MissingEncodeMethodException`

## 1.0.0-alpha (09/06/2018)
- Support dart 2.0 with `build_runner`
- Add enum support (thanks to `json_serializable`)

**Breaking changes**
 
- `@Entity` is deprecated and ignored
- See `README.md` for how to use dartson `1.0.0`
- Reflection implementation is currently not supported 
  (still under evaluation if it will be supported in the future)

## 0.2.6 (10/05/2015)
- Bump dependency versions in pubspec

## 0.2.4 (7/04/2015)
- Support for "double" types
- Update of source_spans dependency

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
