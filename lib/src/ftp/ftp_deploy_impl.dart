import 'package:process_run/shell_run.dart';
import 'package:process_run/which.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

bool _isLftpSupported;
bool get isLftpSupported => _isLftpSupported ??= whichSync('lftp') != null;

class FtpClient {
  bool allowUnsecure;
  String host; // ftp vs sftp
  int port;
  String username;
  String password;

  /// [src] is local, [dst] is remote
  Future lftpDeploy({@required String src, @required String dst}) async {
    var cmd =
        '''${_preCommand}mirror --only-newer --reverse --delete --verbose $src $dst } ; quit''';
    // '''set ftp:ssl-allow no; ls''';

    var scheme = (allowUnsecure ?? false) ? 'ftp:' : 'sftp:';
    await run('''
# call lftp, upload files
lftp $scheme//$username:$password@$host${(port != null) ? '$port' : ''} -e "$cmd"
''');
  }

  String get _preCommand {
    if (allowUnsecure ?? false) {
      return 'set ftp:ssl-allow no ; ';
    } else {
      return '';
    }
  }

  /// [src] is local, [dst] is remote
  Future ls({@required String remoteDir}) async {
    var cmd = '''${_preCommand}ls $remoteDir } ; quit''';
    // '''set ftp:ssl-allow no; ls''';

    var scheme = (allowUnsecure ?? false) ? 'ftp:' : 'sftp:';
    await run('''
# call lftp, upload files
lftp $scheme//$username:$password@$host${(port != null) ? '$port' : ''} -e "$cmd"
''');
  }

  void fromMap(Map map) {
    allowUnsecure = parseBool(map['allowUnsecure']);
    host = map['host']?.toString();
    port = parseInt(map['port']);
    username = map['username']?.toString();
    password = map['password']?.toString();
  }
}
