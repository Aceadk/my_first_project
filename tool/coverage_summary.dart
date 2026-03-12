import 'dart:io';

class CoverageEntry {
  CoverageEntry({
    required this.path,
    required this.totalLines,
    required this.coveredLines,
  });

  final String path;
  final int totalLines;
  final int coveredLines;

  int get uncoveredLines => totalLines - coveredLines;
  double get percentCovered =>
      totalLines == 0 ? 0 : (coveredLines / totalLines) * 100;

  String toArtifactLine() {
    return '${percentCovered.toStringAsFixed(1)}%\t'
        '$coveredLines/$totalLines\t'
        'uncovered=$uncoveredLines\t'
        '$path';
  }
}

void main(List<String> args) {
  final options = _parseArgs(args);
  final lcovFile = File(options.lcovPath);
  if (!lcovFile.existsSync()) {
    stderr.writeln('Error: ${options.lcovPath} not found.');
    exit(1);
  }

  final entries = _parseCoverageEntries(lcovFile.readAsLinesSync());
  if (entries.isEmpty) {
    stderr.writeln('Error: no business-logic coverage entries found.');
    exit(1);
  }

  final totalLines = entries.fold<int>(
    0,
    (sum, entry) => sum + entry.totalLines,
  );
  final coveredLines = entries.fold<int>(
    0,
    (sum, entry) => sum + entry.coveredLines,
  );
  final overallCoverage = totalLines == 0
      ? 0
      : (coveredLines / totalLines) * 100;

  stdout.writeln('Total Lines: $totalLines');
  stdout.writeln('Covered Lines: $coveredLines');
  stdout.writeln('Overall Coverage: ${overallCoverage.toStringAsFixed(2)}%');
  stdout.writeln(
    'Hotspot Files: ${entries.length} '
    '(threshold < ${options.threshold.toStringAsFixed(1)}%)',
  );

  final artifactLines = <String>[
    '# Coverage Hotspot Artifact',
    'lcov=${options.lcovPath}',
    'overall=${overallCoverage.toStringAsFixed(2)}%',
    'business_logic_lines=$coveredLines/$totalLines',
    'threshold=${options.threshold.toStringAsFixed(1)}%',
    '',
    ...entries
        .where((entry) => entry.percentCovered < options.threshold)
        .map((entry) => entry.toArtifactLine()),
  ];

  if (options.artifactPath != null) {
    final artifactFile = File(options.artifactPath!);
    artifactFile.writeAsStringSync('${artifactLines.join('\n')}\n');
    stdout.writeln('Wrote hotspot artifact to ${artifactFile.path}');
  } else {
    stdout.writeln('');
    for (final line in artifactLines) {
      stdout.writeln(line);
    }
  }
}

class _CoverageOptions {
  const _CoverageOptions({
    required this.lcovPath,
    required this.threshold,
    required this.artifactPath,
  });

  final String lcovPath;
  final double threshold;
  final String? artifactPath;
}

_CoverageOptions _parseArgs(List<String> args) {
  var lcovPath = 'coverage/lcov.info';
  var threshold = 80.0;
  String? artifactPath;

  for (final arg in args) {
    if (arg.startsWith('--lcov=')) {
      lcovPath = arg.substring('--lcov='.length);
      continue;
    }
    if (arg.startsWith('--artifact=')) {
      artifactPath = arg.substring('--artifact='.length);
      continue;
    }
    if (arg.startsWith('--threshold=')) {
      threshold = double.parse(arg.substring('--threshold='.length));
      continue;
    }
    throw ArgumentError(
      'Unsupported argument: $arg\n'
      'Supported: --lcov=<path> --artifact=<path> --threshold=<percent>',
    );
  }

  return _CoverageOptions(
    lcovPath: lcovPath,
    threshold: threshold,
    artifactPath: artifactPath,
  );
}

List<CoverageEntry> _parseCoverageEntries(List<String> lines) {
  final entries = <CoverageEntry>[];
  String? currentFile;
  var currentIsTracked = false;
  var currentTotal = 0;
  var currentCovered = 0;

  void finalizeRecord() {
    if (currentFile == null || !currentIsTracked || currentTotal == 0) {
      currentFile = null;
      currentIsTracked = false;
      currentTotal = 0;
      currentCovered = 0;
      return;
    }

    entries.add(
      CoverageEntry(
        path: currentFile!,
        totalLines: currentTotal,
        coveredLines: currentCovered,
      ),
    );
    currentFile = null;
    currentIsTracked = false;
    currentTotal = 0;
    currentCovered = 0;
  }

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      finalizeRecord();
      currentFile = line.substring(3).trim();
      currentIsTracked = _isTrackedBusinessLogicFile(currentFile!);
      continue;
    }

    if (!currentIsTracked) {
      if (line == 'end_of_record') {
        finalizeRecord();
      }
      continue;
    }

    if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length < 2) continue;
      final hits = int.tryParse(parts[1]) ?? 0;
      currentTotal += 1;
      if (hits > 0) {
        currentCovered += 1;
      }
      continue;
    }

    if (line == 'end_of_record') {
      finalizeRecord();
    }
  }

  finalizeRecord();

  entries.sort((left, right) {
    final percent = left.percentCovered.compareTo(right.percentCovered);
    if (percent != 0) return percent;

    final uncovered = right.uncoveredLines.compareTo(left.uncoveredLines);
    if (uncovered != 0) return uncovered;

    final total = right.totalLines.compareTo(left.totalLines);
    if (total != 0) return total;

    return left.path.compareTo(right.path);
  });

  return entries;
}

bool _isTrackedBusinessLogicFile(String path) {
  final isGenerated =
      path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.contains('/generated/');
  if (isGenerated) return false;

  final isUi =
      path.contains('/presentation/pages/') ||
      path.contains('/presentation/screens/') ||
      path.contains('/presentation/widgets/') ||
      path.contains('/view/') ||
      path.contains('/ui/');
  if (isUi) return false;

  final isBusinessLogic =
      path.contains('/domain/') ||
      path.contains('/data/') ||
      path.contains('/bloc/') ||
      path.contains('/cubit/') ||
      path.contains('/core/');

  return isBusinessLogic;
}
