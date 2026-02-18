// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print('Error: coverage/lcov.info not found.');
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  int totalLines = 0;
  int coveredLines = 0;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      // Check if file is generated
      if (line.endsWith('.g.dart') || line.endsWith('.freezed.dart')) {
        // Skip subsequent lines until next SF
        // Wait, lcov format is blocks. SF:file ... end_of_record
        // I need stateful parsing.
      }
    }
  }

  // Re-write the loop to handle file context
  bool isBusinessLogic = false;
  String currentFile = '';
  Map<String, List<int>> fileCoverage = {}; // filename -> [total, covered]

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      final fileName = line.substring(3).trim();
      currentFile = fileName;
      final isGenerated =
          fileName.endsWith('.g.dart') || fileName.endsWith('.freezed.dart');
      final isUi =
          fileName.contains('/presentation/pages/') ||
          fileName.contains('/presentation/widgets/') ||
          fileName.contains('/view/') ||
          fileName.contains('/ui/');

      // Business logic definitions:
      final isDomain = fileName.contains('/domain/');
      final isData = fileName.contains('/data/');
      final isBloc =
          fileName.contains('/bloc/') || fileName.contains('/cubit/');
      final isCore = fileName.contains('/core/');

      isBusinessLogic =
          !isGenerated && !isUi && (isDomain || isData || isBloc || isCore);
      if (isBusinessLogic) {
        fileCoverage[currentFile] = [0, 0];
      }
    } else if (isBusinessLogic && line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final hits = int.tryParse(parts[1]) ?? 0;
        fileCoverage[currentFile]![0]++; // total lines
        if (hits > 0) {
          fileCoverage[currentFile]![1]++; // covered lines
        }

        totalLines++;
        if (hits > 0) {
          coveredLines++;
        }
      }
    }
  }

  if (totalLines == 0) {
    print('No instrumented lines found.');
    return;
  }

  print('Total Lines: $totalLines');
  print('Covered Lines: $coveredLines');
  final coverage = (coveredLines / totalLines) * 100;
  print('Overall Coverage: ${coverage.toStringAsFixed(2)}%');

  print('\n--- Low Coverage Files (< 80%) ---');
  final sortedFiles = fileCoverage.entries.toList()
    ..sort((a, b) {
      double covA = a.value[0] > 0 ? (a.value[1] / a.value[0]) : 0;
      double covB = b.value[0] > 0 ? (b.value[1] / b.value[0]) : 0;
      return covA.compareTo(covB);
    });

  for (final entry in sortedFiles) {
    final total = entry.value[0];
    if (total == 0) continue;
    final covered = entry.value[1];
    final pct = (covered / total) * 100;
    if (pct < 80.0) {
      print('${pct.toStringAsFixed(1)}% ($covered/$total) - ${entry.key}');
    }
  }
}
