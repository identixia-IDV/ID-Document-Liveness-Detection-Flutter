#!/usr/bin/env dart
// Cross-platform setup checks (Windows / macOS / Linux).
// Usage from repo root:
//   dart run tool/bootstrap.dart
// Windows:
//   scripts\bootstrap.bat


import 'dart:io';


void main() async {
  final root = Directory.current;
  final pubspec = File('${root.path}${Platform.pathSeparator}pubspec.yaml');
  if (!pubspec.existsSync() ||
      !pubspec.readAsStringSync().contains('name: document_reader_sdk')) {
    stderr.writeln(
      'Run from the ID-Document-Recognition-Liveness-Detection-Flutter repo root '
      '(folder that contains pubspec.yaml for document_reader_sdk).',
    );
    exitCode = 1;
    return;
  }


  section('Flutter');
  await run('flutter', ['--version']);
  await run('flutter', ['pub', 'get']);
  await run('flutter', ['pub', 'get'], workingDirectory: p(root, 'example'));


  section('Android AAR');
  final aar = File(p(root, 'example', 'android', 'libdocumentlivenesssdk', 'documentlivenesssdk.aar'));
  if (aar.existsSync()) {
    ok(aar.path);
  } else {
    missing(
      aar.path,
      'Copy from Drive or ID-Document-Liveness-Detection-Android/libdocumentlivenesssdk/documentlivenesssdk.aar',
    );
  }


  section('iOS documentlivenesssdk');
  if (Platform.isWindows) {
    print(
      'Skipped on Windows (iOS builds require macOS + Xcode). '
      'On a Mac: place ios/Frameworks/documentlivenesssdk.framework then run this script again '
      '(or pod install, which creates documentlivenesssdk.xcframework).',
    );
  } else {
    final fwPath = p(root, 'ios', 'Frameworks', 'documentlivenesssdk.framework');
    final fw = Directory(fwPath);
    final binary = File('$fwPath${Platform.pathSeparator}documentlivenesssdk');
    if (fw.existsSync() && binary.existsSync()) {
      ok(fwPath);
      final code = await ensureXcframework(root);
      if (code != 0) exitCode = code;
    } else if (fw.existsSync() && !binary.existsSync()) {
      missing(
        binary.path,
        'ios/Frameworks/documentlivenesssdk.framework is incomplete (Info.plist only). '
        'Copy a full build from ID-Document-Recognition-Liveness-Detection-iOS-SDK/libdocumentlivenesssdk/documentlivenesssdk.framework '
        '(run: cd ../ID-Document-Recognition-Liveness-Detection-iOS-SDK && python scripts/export.py).',
      );
    } else {
      missing(
        fwPath,
        'Unzip documentlivenesssdk.framework into ios/Frameworks/ (macOS only for device builds).',
      );
    }
  }


  section('Done');
  print('Next:  cd example && flutter run');
  if (!Platform.isWindows) {
    print(
      'iOS: open example/ios/Runner.xcworkspace → set Team; '
      'keep bundle id com.identixia.documentliveness.app',
    );
  }
}


Future<int> ensureXcframework(Directory root) async {
  final fwPath = p(root, 'ios', 'Frameworks', 'documentlivenesssdk.framework');
  final fw = Directory(fwPath);
  final binary = File('$fwPath${Platform.pathSeparator}documentlivenesssdk');
  final xcPath = p(root, 'ios', 'Frameworks', 'documentlivenesssdk.xcframework');
  final xc = Directory(xcPath);
  final plist = File('$xcPath${Platform.pathSeparator}Info.plist');
  final spmXcPath =
      p(root, 'ios', 'document_reader_sdk', 'Frameworks', 'documentlivenesssdk.xcframework');


  var rebuilt = false;
  if (xc.existsSync() &&
      plist.existsSync() &&
      binary.existsSync() &&
      !binary.lastModifiedSync().isAfter(plist.lastModifiedSync())) {
    print('documentlivenesssdk.xcframework already up to date');
  } else {
    if (xc.existsSync()) {
      xc.deleteSync(recursive: true);
    }


    print('Creating $xcPath');
    final result = await Process.run(
      'xcodebuild',
      [
        '-create-xcframework',
        '-framework',
        fw.path,
        '-output',
        xcPath,
      ],
      workingDirectory: root.path,
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      stderr.writeln(
        'xcodebuild failed (install Xcode Command Line Tools on macOS).',
      );
      return result.exitCode;
    }
    ok(xcPath);
    rebuilt = true;
  }


  // SwiftPM binaryTarget path is inside the package directory (not ../Frameworks).
  final spmParent =
      Directory(p(root, 'ios', 'document_reader_sdk', 'Frameworks'));
  spmParent.createSync(recursive: true);
  final spmLink = Link(spmXcPath);
  final spmDir = Directory(spmXcPath);
  final needsSync = rebuilt ||
      !spmDir.existsSync() ||
      spmLink.existsSync() ||
      (plist.existsSync() &&
          File('$spmXcPath${Platform.pathSeparator}Info.plist').existsSync() &&
          plist.lastModifiedSync().isAfter(
            File('$spmXcPath${Platform.pathSeparator}Info.plist')
                .lastModifiedSync(),
          ));
  if (needsSync && xc.existsSync()) {
    if (spmLink.existsSync()) spmLink.deleteSync();
    if (spmDir.existsSync()) spmDir.deleteSync(recursive: true);
    await Process.run(
      'cp',
      ['-R', xcPath, spmXcPath],
      runInShell: false,
    );
    // Fallback for platforms without cp -R semantics matching directories.
    if (!Directory(spmXcPath).existsSync()) {
      // ignore: avoid_slow_async_io
      await _copyDir(xc, Directory(spmXcPath));
    }
    ok('SwiftPM binary: $spmXcPath');
  }
  return 0;
}


Future<void> _copyDir(Directory src, Directory dest) async {
  dest.createSync(recursive: true);
  await for (final entity in src.list(recursive: false)) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    final out = '${dest.path}${Platform.pathSeparator}$name';
    if (entity is Directory) {
      await _copyDir(entity, Directory(out));
    } else if (entity is File) {
      entity.copySync(out);
    }
  }
}


Future<void> run(
  String exe,
  List<String> args, {
  String? workingDirectory,
}) async {
  print('+ $exe ${args.join(' ')}');
  final result = await Process.run(
    exe,
    args,
    workingDirectory: workingDirectory,
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
  }
}


String p(Directory root, String a, [String? b, String? c, String? d]) {
  final parts = [root.path, a, if (b != null) b, if (c != null) c, if (d != null) d];
  return parts.join(Platform.pathSeparator);
}


void section(String title) => print('\n== $title ==');
void ok(String path) => print('ok: $path');
void missing(String path, String hint) {
  print('MISSING: $path');
  print('  → $hint');
  exitCode = 1;
}
