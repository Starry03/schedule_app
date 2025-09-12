<!-- README in Italian: clear, concise, and developer-friendly -->

<!-- README in English: clear, concise, and developer-friendly -->
# Schedule App — Teacher Schedule Generator

Schedule App is a Flutter application for generating and managing teacher schedules. It is intended to be run locally or self-hosted, with Supabase (Postgres) as the backend. The project focuses on privacy and configurability for small institutions and schools.

## Key Features

- Manage teachers, subjects, classes and availability constraints
- Intelligent schedule generation algorithm
- Visual schedule editor and manual adjustments
- PDF export with a compact timetable layout
- Designed to work with Supabase but suitable for self-hosting

## Requirements

- Flutter SDK (3.x or newer)
- Dart
- A Supabase project with the tables used by the app (see models in `lib/models`)
- Supabase URL and anon key configured for the app (via `supabase_flutter`)

## Quick setup (development)

1. Clone the repository

	`git clone https://github.com/<owner>/<repo>.git`

2. Install dependencies

	`flutter pub get`

3. Configure Supabase

- Create a Supabase project and the required tables: `teachers`, `subjects`, `classes`, `schedules`, `schedule_slots`, `teacher_subjects`, `teacher_constraints`, etc.
- Configure the Supabase URL and anon key in your app environment so `lib/providers/data_provider.dart` can instantiate the client.

4. Run the app

	`flutter run -d <deviceId>`

Tip: For debugging data and network requests, use the Supabase dashboard and check logs in your Flutter app.

## PDF export details

The PDF export produces a wide timetable with the following behaviour:

- First column: `Teacher` (fixed width, adapts to longest name)
- 30 slot columns: 5 days × 6 hours each
- Cells that correspond to teacher availability constraints are highlighted with a light blue (celeste) background
- The generator attempts to resize the teacher-column font to avoid wrapping; if a layout error occurs a simplified fallback PDF is created

If you see rendering errors (e.g. layout assertions mentioning `isNaN`), the app will try a fallback export and save a `_fallback.pdf` file.

## Constraints (availability) workflow

To edit and save a single teacher's constraints:

1. Open the Teacher list and select `Vincoli` (Constraints) for a teacher.
2. Toggle the desired slots (blocked/unblocked) in the grid.
3. Press the save icon (top-right) to persist changes to Supabase (`teacher_constraints` table).

If changes are not saved, check your network connectivity, Supabase credentials, and app logs for errors.

## Troubleshooting

- `dart analyze` may show informational lints or a test-related error; these are generally non-blocking but fix tests if you run CI.
- Android PDF save issues: ensure file write permissions are configured in `AndroidManifest.xml` for devices that require them.
- If schedule generation fails due to conflicting constraints, verify `teacher_subjects` assignments and existing constraints.

## Contributing

Contributions are welcome. Please open an issue or a pull request for:

- Improvements to the scheduling algorithm
- UI/UX fixes (including PDF layout tweaks)
- Automated tests and CI configuration

## License

This project is open-source. Add your preferred license (MIT, Apache-2.0, etc.) here.

---

Would you like me to add developer shortcuts (DB migration scripts, seed commands, or Supabase schema snippets)? I can add those next.
