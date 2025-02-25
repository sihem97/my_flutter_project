import 'package:flutter/material.dart';
import 'teachers_map.dart';
import 'l10n/app_localizations.dart'; // Import your localization helper

class EducationLevelSelectionScreen extends StatelessWidget {
  // Mapping of education levels to their corresponding subject translation keys.
  // Use lowercase keys that match the keys in your JSON files.
  final Map<String, List<String>> subjects = {
    'primaire': [
      'mathematics',
      'arabic_language',
      'physics',
      'science_nature_life',
      'french_language'
    ],
    'cem': [
      'mathematics',
      'arabic_language',
      'physics',
      'science_nature_life',
      'french_language',
      'english_language'
    ],
    'lycee': [
      'mathematics',
      'arabic_language',
      'physics',
      'science_nature_life',
      'french_language',
      'english_language',
      'philosophy',
      'accounting'
    ],
  };

  EducationLevelSelectionScreen({Key? key}) : super(key: key);

  /// Builds a clickable card for an education level.
  Widget _buildLevelOption({
    required BuildContext context,
    required String level, // translation key for the education level
    required List<String> subjectList,
    required Color cardColor,
    required IconData iconData,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // Navigate to the subject selection screen when tapped.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectSelectionScreen(
                level: level,
                subjects: subjectList,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left: Icon with a subtle background.
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor == Colors.white
                        ? Colors.red.shade800.withOpacity(0.1)
                        : Colors.white.withOpacity(0.4),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    iconData,
                    size: 60,
                    color: cardColor == Colors.white
                        ? Colors.red.shade800
                        : Colors.white,
                  ),
                ),
              ),
              // Center: Education level text.
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate(level),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cardColor == Colors.white
                        ? Colors.red.shade800
                        : Colors.white,
                  ),
                ),
              ),
              // Right: Forward arrow icon.
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: cardColor == Colors.white
                      ? Colors.red.shade800
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(AppLocalizations.of(context).translate('education_level')),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Option 1: Primaire
          _buildLevelOption(
            context: context,
            level: 'primaire',
            subjectList: subjects['primaire']!,
            cardColor: Colors.white,
            iconData: Icons.school,
          ),
          // Option 2: CEM
          _buildLevelOption(
            context: context,
            level: 'cem',
            subjectList: subjects['cem']!,
            cardColor: Colors.white,
            iconData: Icons.school,
          ),
          // Option 3: Lycee
          _buildLevelOption(
            context: context,
            level: 'lycee',
            subjectList: subjects['lycee']!,
            cardColor: Colors.white,
            iconData: Icons.school,
          ),
        ],
      ),
    );
  }
}

class SubjectSelectionScreen extends StatelessWidget {
  final String level; // education level translation key
  final List<String> subjects;

  const SubjectSelectionScreen({
    Key? key,
    required this.level,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${AppLocalizations.of(context).translate('subjects')} - ${AppLocalizations.of(context).translate(level)}",
        ),
        backgroundColor: Colors.red.shade800,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: subjects.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final subjectKey = subjects[index];
          return ListTile(
            title: Text(AppLocalizations.of(context).translate(subjectKey)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TeacherListScreen(subject: subjectKey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
