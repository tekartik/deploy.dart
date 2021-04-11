import 'package:dev_test/package.dart';

Future main() async {
  await packageRunCi('.', options: PackageRunCiOptions(noOverride: true));
  //await Shell().run('dart test -j 1 -p vm,chrome');
}
