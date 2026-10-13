import 'package:process_run/shell_run.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

bool? _isLftpSupported;

/// Check if lftp is supported.
bool get isLftpSupported => _isLftpSupported ??= whichSync('lftp') != null;

/// Ftp client.
class FtpClient {
  /// Allow unsecure connection.
  bool? allowUnsecure;

  /// Host.
  String? host; // ftp vs sftp
  /// Port.
  int? port;

  /// Username.
  String? username;

  /// Password.
  String? password;

  /// [src] is local, [dst] is remote
  Future lftpDeploy({required String src, required String dst}) async {
    await _runLftp(
      'mirror --only-newer --reverse --delete --verbose $src $dst',
    );
  }

  /// List remote directory content.
  /// [remoteDir] is remote directory.
  Future ls({required String remoteDir}) async {
    await _runLftp('ls $remoteDir');
  }

  /// Run lftp without printing the script, which holds the password.
  Future<void> _runLftp(String command) async {
    var script = ftpClientLftpScript(this, command);
    stdout.writeln(
      '\$ ${ftpClientLftpScript(this, command, hidePassword: true).trim().split('\n').last}',
    );
    await run(script, commandVerbose: false);
  }

  /// Read from a map.
  void fromMap(Map map) {
    allowUnsecure = parseBool(map['allowUnsecure']);
    host = map['host']?.toString();
    port = parseInt(map['port']);
    username = map['username']?.toString();
    password = map['password']?.toString();
  }
}

/// The lftp script running [command] on [client], then quitting.
///
/// [hidePassword] replaces the password, to print the script.
String ftpClientLftpScript(
  FtpClient client,
  String command, {
  bool hidePassword = false,
}) {
  var allowUnsecure = client.allowUnsecure ?? false;
  var preCommand = allowUnsecure ? 'set ftp:ssl-allow no ; ' : '';
  var scheme = allowUnsecure ? 'ftp:' : 'sftp:';
  var port = client.port;
  return '''
# call lftp
lftp $scheme//${client.username}:${hidePassword ? '****' : client.password}@${client.host}${(port != null) ? ':$port' : ''} -e "$preCommand$command ; quit"
''';
}
