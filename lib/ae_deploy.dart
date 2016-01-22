library tekartik.deploy.aedeploy;

import 'package:path/path.dart';
import 'dart:async';
//import 'dart:convert';
import 'package:fs_shim/utils/src/utils_impl.dart';
import 'package:fs_shim/utils/read_write.dart';
import 'package:fs_shim/utils/entity.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'package:process_run/cmd_run.dart';
import 'package:mustache_no_mirror/mustache.dart' as mustache;
import 'package:tekartik_pub/pub_fs_io.dart';
import 'dart:io' as io;
import 'package:yaml/yaml.dart' as yaml;
import 'package:resource/resource.dart';

@deprecated
devPrint(String msg) {
  print(msg);
}

/*
class _Script extends Script {}

String get _scriptPath => getScriptPath(_Script);
String get _scriptDir => dirname(_scriptPath);
String get _aeEmptyAppTemplateDir => join(_scriptDir, 'ae', 'empty_app');
*/
// Future<String> _getAeEmptyAppTemplateDir() async {}
///
Logger _log = new Logger("tekartik.aedeploy");

///
/// Deploy between 2 folders with an option config file
///
/// [settings] can be set (files and exclude keys)
///
Future aeDeployEmpty(String applicationId, String module) async {
  String baseUrl = "package:tekartik_deploy/ae/empty_app/";
  Uri uri = Uri.parse(baseUrl);

  //Directory dir = new Directory(_aeEmptyAppTemplateDir);
  Directory out = new Directory((await io.Directory.systemTemp
          .createTemp('empty_app $applicationId $module'))
      .path);

  await emptyOrCreateDirectory(out);

  Map settings = {
    "applicationId": applicationId,
    "module": module,
    "date": new DateTime.now()
  };

  _enumerate([List<String> parts]) async {
    if (parts == null) {
      parts = [];
    }

    String listUrlPath = join(url.joinAll(parts), ".list.yaml");

    Uri listUri = uri.resolve(listUrlPath);
    String text = await ResourceLoader.defaultLoader.readAsString(listUri);
    print(text);
    Map list = yaml.loadYaml(text);

    List<String> files = list["files"];
    if (files != null) {
      for (String file in files) {
        Uri fileUri = listUri.resolve(file);
        String input = await ResourceLoader.defaultLoader.readAsString(fileUri);
        //devPrint(input);

        mustache.Template t = mustache.parse(input, lenient: true);

        String output =
            t.renderString(settings, lenient: true, htmlEscapeValues: false);

        //devPrint(output);
        // file path
        File outFile = childFile(out, join(joinAll(parts), file));
        print(outFile);
        await writeString(outFile, output);
      }
    }
  }

  await _enumerate();

  deploy(String applicationId, String module) async {
    ProcessCmd cmd = new ProcessCmd('gcloud', [
      'preview',
      "app",
      "deploy",
      join(out.path, "app.yaml"),
      "--project",
      applicationId, //   Force deploying, overriding any previous in-progress deployments to this version
      "--quiet", // No prompt
    ]);
    //ProcessCmd cmd = new ProcessCmd('gcloud', ['help']);
    print(processCmdToDebugString(cmd));
    await runCmd(cmd
      ..connectStdin = true
      ..connectStderr = true
      ..connectStdout = true
      ..runInShell = true
      ..includeParentEnvironment = true);
  }

  print(out);
  await deploy(applicationId, module);
}
