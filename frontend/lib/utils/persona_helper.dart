import '../models/family_member.dart';

class PersonaHelper {
  static const Map<String, List<String>> _availablePersonas = {
    'female-adult': ['accountant', 'architect', 'artist', 'barista', 'chef', 'designer', 'developer', 'doctor', 'engineer', 'farmer', 'manager', 'musician', 'nurse', 'pilot', 'police', 'scientist', 'teacher', 'writer'],
    'female-child': ['accountant', 'architect', 'artist', 'athlete', 'barista', 'chef', 'designer', 'developer', 'doctor', 'engineer', 'farmer', 'lawyer', 'manager', 'musician', 'nurse', 'pilot', 'police', 'scientist', 'teacher', 'writer'],
    'female-senior': ['accountant', 'architect', 'artist', 'athlete', 'designer', 'developer', 'doctor', 'engineer', 'lawyer', 'manager', 'nurse', 'pilot', 'police', 'scientist', 'teacher'],
    'female-teen': ['architect', 'athlete', 'chef', 'manager', 'musician', 'police', 'scientist', 'teacher', 'writer'],
    'male-adult': ['accountant', 'athlete', 'barista', 'designer', 'developer', 'doctor', 'engineer', 'farmer', 'nurse', 'pilot', 'police', 'scientist', 'teacher', 'writer'],
    'male-child': ['architect', 'athlete', 'chef', 'designer', 'developer', 'farmer', 'lawyer', 'manager', 'musician', 'nurse', 'police'],
    'male-senior': ['athlete', 'chef', 'designer', 'developer', 'doctor', 'engineer', 'farmer', 'manager', 'pilot', 'police', 'scientist', 'teacher'],
    'male-teen': ['accountant', 'artist', 'barista', 'chef', 'designer', 'doctor', 'engineer', 'farmer', 'lawyer', 'manager', 'musician', 'nurse', 'pilot', 'police', 'scientist', 'teacher', 'writer'],
  };

  static String getPersonaUrl(FamilyMember member) {
    // Determine gender (fallback to male)
    String gender = (member.data['gender']?.toString().toLowerCase() ?? 'male');
    if (gender != 'male' && gender != 'female') {
      gender = 'male';
    }

    // Determine age group
    String ageGroup = 'adult';
    final dobString = member.data['dob']?.toString();
    if (dobString != null && dobString.isNotEmpty) {
      try {
        final dob = DateTime.parse(dobString);
        final now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        
        if (age < 13) {
          ageGroup = 'child';
        } else if (age < 20) {
          ageGroup = 'teen';
        } else if (age >= 60) {
          ageGroup = 'senior';
        }
      } catch (e) {
        // Ignore parse errors, stick to default 'adult'
      }
    }

    // Determine profession
    String profession = (member.data['profession']?.toString().toLowerCase() ?? 'developer');
    profession = profession.replaceAll(RegExp(r'\s+'), '-');

    final key = '$gender-$ageGroup';
    final validProfessions = _availablePersonas[key] ?? [];

    if (!validProfessions.contains(profession)) {
      // Fallback to the first available profession if specific one doesn't exist
      profession = validProfessions.isNotEmpty ? validProfessions.first : 'developer';
    }

    // e.g. /personas/male/adult/male-adult-developer.png
    return '/personas/$gender/$ageGroup/$gender-$ageGroup-$profession.png';
  }

  static List<String> getAvailablePersonas(String genderStr, String ageStr) {
    String gender = genderStr.toLowerCase();
    if (gender != 'male' && gender != 'female') gender = 'male';

    String ageGroup = 'adult';
    int age = int.tryParse(ageStr) ?? 30;
    if (age < 13) {
      ageGroup = 'child';
    } else if (age < 20) {
      ageGroup = 'teen';
    } else if (age >= 60) {
      ageGroup = 'senior';
    }

    final key = '$gender-$ageGroup';
    final professions = _availablePersonas[key] ?? [];
    return professions.map((p) => '/personas/$gender/$ageGroup/$gender-$ageGroup-$p.png').toList();
  }

  static String getDynamicPersonaUrl(String genderStr, String ageStr, String professionStr) {
    String gender = genderStr.toLowerCase();
    if (gender != 'male' && gender != 'female') gender = 'male';

    String ageGroup = 'adult';
    int age = int.tryParse(ageStr) ?? 30;
    if (age < 13) {
      ageGroup = 'child';
    } else if (age < 20) {
      ageGroup = 'teen';
    } else if (age >= 60) {
      ageGroup = 'senior';
    }

    String profession = professionStr.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    if (profession.isEmpty) profession = 'developer';

    final key = '$gender-$ageGroup';
    final validProfessions = _availablePersonas[key] ?? [];

    if (!validProfessions.contains(profession)) {
      profession = validProfessions.isNotEmpty ? validProfessions.first : 'developer';
    }

    return '/personas/$gender/$ageGroup/$gender-$ageGroup-$profession.png';
  }
}
