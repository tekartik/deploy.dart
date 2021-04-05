import 'package:dev_test/package.dart';
import 'package:process_run/shell.dart';

Future main() async {
  await packageRunCi('.',
      options: PackageRunCiOptions(noOverride: true, noTest: true));
  await Shell().run('dart test -j 1 -p vm,chrome');
}
