// your_flutter_project/batch_app/main.dart

import 'package:fantacy11/scripts/update_player_forms.dart' as batch_job_script;

void main(List<String> args) async {
  // Directly call the main function from your batch job script.
  // It handles its own environment variable/arg parsing and Firebase init.
  await batch_job_script.main(args);
}
