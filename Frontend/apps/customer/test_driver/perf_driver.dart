// Writes the motion timeline summary to out/perf/ and fails over budget (P27):
// 90th-percentile build and raster under 12 ms, no frame over 32 ms.
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

const _p90Budget = 12.0;
const _worstBudget = 32.0;

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final timeline = driver.Timeline.fromJson(
      data!['motion']! as Map<String, dynamic>,
    );
    final summary = driver.TimelineSummary.summarize(timeline);
    await summary.writeTimelineToFile(
      'motion',
      pretty: true,
      destinationDirectory: Platform.environment['PAO_PERF_OUT'] ?? 'out/perf',
    );
    final over = <String>[
      if (summary.computePercentileFrameBuildTimeMillis(90) >= _p90Budget)
        'p90 build',
      if (summary.computePercentileFrameRasterizerTimeMillis(90) >= _p90Budget)
        'p90 raster',
      if (summary.computeWorstFrameBuildTimeMillis() > _worstBudget)
        'worst build',
      if (summary.computeWorstFrameRasterizerTimeMillis() > _worstBudget)
        'worst raster',
    ];
    if (over.isNotEmpty) {
      stderr.writeln('motion over budget: ${over.join(', ')}');
      exit(1);
    }
  },
);
