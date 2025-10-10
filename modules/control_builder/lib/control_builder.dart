import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/parse_generator.dart';

Builder parseBuilder(BuilderOptions options) => PartBuilder([ParseGenerator()], '.g.dart');
