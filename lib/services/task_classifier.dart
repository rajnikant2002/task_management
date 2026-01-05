import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskClassifier {
  // Classify category - maps keyword categories to TaskCategory enum
  // Keyword Categories → TaskCategory Enum Mapping:
  // - scheduling (meeting, schedule, call, appointment, deadline) → Work
  // - finance (payment, invoice, bill, budget, cost, expense) → Work
  // - technical (bug, fix, error, install, repair, maintain) → Work
  // - safety (safety, hazard, inspection, compliance, PPE) → Health
  // - general (default/no match) → Other
  static TaskCategory classifyCategory(String text) {
    if (text.isEmpty) return TaskCategory.other;

    final lower = text.toLowerCase();

    // Scheduling category keywords: meeting, schedule, call, appointment, deadline
    // Maps to: TaskCategory.work
    final schedulingPatterns = [
      r'\bmeeting\b',
      r'\bschedule\b',
      r'\bcall\b',
      r'\bappointment\b',
      r'\bdeadline\b',
      r'\bconference\b',
      r'\bmeet\b',
    ];
    for (final pattern in schedulingPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return TaskCategory.work; // scheduling → Work
      }
    }

    // Finance category keywords: payment, invoice, bill, budget, cost, expense
    // Maps to: TaskCategory.work
    final financePatterns = [
      r'\bbudget\b',
      r'\binvoice\b',
      r'\bpayment\b',
      r'\bbill\b',
      r'\bcost\b',
      r'\bexpense\b',
      r'\bfinance\b',
      r'\bmoney\b',
    ];
    for (final pattern in financePatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return TaskCategory.work; // finance → Work
      }
    }

    // Technical category keywords: bug, fix, error, install, repair, maintain
    // Maps to: TaskCategory.work
    final technicalPatterns = [
      r'\bbug\b',
      r'\bfix\b',
      r'\berror\b',
      r'\binstall\b',
      r'\brepair\b',
      r'\bmaintain\b',
      r'\btechnical\b',
      r'\bdebug\b',
    ];
    for (final pattern in technicalPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return TaskCategory.work; // technical → Work
      }
    }

    // Safety category keywords: safety, hazard, inspection, compliance, PPE
    // Maps to: TaskCategory.health
    final safetyPatterns = [
      r'\bsafety\b',
      r'\bhazard\b',
      r'\binspection\b',
      r'\bcompliance\b',
      r'\bppe\b',
    ];
    for (final pattern in safetyPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return TaskCategory.health; // safety → Health
      }
    }

    // Shopping category keywords: buy, purchase, shop, grocery, shopping
    // Maps to: TaskCategory.shopping
    final shoppingPatterns = [
      r'\bbuy\b',
      r'\bpurchase\b',
      r'\bshop\b',
      r'\bgrocery\b',
      r'\bshopping\b',
    ];
    for (final pattern in shoppingPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return TaskCategory.shopping;
      }
    }

    // Personal category keywords: personal, family, home, vacation, hobby
    // Maps to: TaskCategory.personal
    final personalPatterns = [
      r'\bpersonal\b',
      r'\bfamily\b',
      r'\bhome\b',
      r'\bvacation\b',
      r'\bhobby\b',
    ];
    for (final pattern in personalPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return TaskCategory.personal;
      }
    }

    // General category (default) - no keyword match
    // Maps to: TaskCategory.other
    return TaskCategory.other; // general → Other
  }

  // Classify priority
  static TaskPriority classifyPriority(String text) {
    if (text.isEmpty) return TaskPriority.low;

    final lower = text.toLowerCase();

    // High priority keywords - check for whole word matches to avoid false positives
    final highPriorityPatterns = [
      r'\burgent\b',
      r'\basap\b',
      r'\bimmediately\b',
      r'\btoday\b',
      r'\bcritical\b',
      r'\bemergency\b',
      r'\bfast\b',
      r'\bquick\b',
      r'\brush\b',
      r'\bnow\b',
      r'\bpriority\b',
    ];

    for (final pattern in highPriorityPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return TaskPriority.high;
      }
    }

    // Medium priority keywords
    final mediumPriorityPatterns = [
      r'\bsoon\b',
      r'\bthis week\b',
      r'\bimportant\b',
      r'\bnext week\b',
    ];

    for (final pattern in mediumPriorityPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return TaskPriority.medium;
      }
    }

    return TaskPriority.low;
  }

  // Get category display name - returns descriptive name based on detected keywords
  static String getCategoryDisplayName(TaskCategory category, String text) {
    if (text.isEmpty) return 'General';

    final lower = text.toLowerCase();

    // Check which keyword category was detected (in priority order)
    // Scheduling keywords: meeting, schedule, call, appointment, deadline
    final schedulingPattern = RegExp(
      r'\b(meeting|schedule|call|appointment|deadline|conference|meet)\b',
      caseSensitive: false,
    );
    if (schedulingPattern.hasMatch(lower)) {
      return 'Scheduling';
    }

    // Finance keywords: payment, invoice, bill, budget, cost, expense
    final financePattern = RegExp(
      r'\b(budget|invoice|payment|bill|cost|expense|finance|money)\b',
      caseSensitive: false,
    );
    if (financePattern.hasMatch(lower)) {
      return 'Finance';
    }

    // Technical keywords: bug, fix, error, install, repair, maintain
    final technicalPattern = RegExp(
      r'\b(bug|fix|error|install|repair|maintain|technical|debug)\b',
      caseSensitive: false,
    );
    if (technicalPattern.hasMatch(lower)) {
      return 'Technical';
    }

    // Safety keywords: safety, hazard, inspection, compliance, PPE
    final safetyPattern = RegExp(
      r'\b(safety|hazard|inspection|compliance|ppe)\b',
      caseSensitive: false,
    );
    if (safetyPattern.hasMatch(lower)) {
      return 'Safety';
    }

    // General (default) - no keyword match
    return 'General';
  }

  // Get category display name (backward compatibility)
  static String getCategoryDisplayNameSimple(TaskCategory category) {
    return category.value;
  }

  // Get priority display name
  static String getPriorityDisplayName(TaskPriority priority) {
    return priority.value;
  }

  // Get category color
  static Color getCategoryColor(TaskCategory category) {
    return TaskCategory.getColor(category);
  }

  // Get priority color
  static Color getPriorityColor(TaskPriority priority) {
    return TaskPriority.getColor(priority);
  }

  // Extract entities from text
  static Map<String, dynamic> extractEntities(String text) {
    final entities = <String, dynamic>{};

    // Store detected keyword category name (Scheduling, Finance, Technical, Safety, General)
    final detectedCategoryName = getCategoryDisplayName(
      classifyCategory(text),
      text,
    );
    entities['detected_category'] = detectedCategoryName;

    // Extract dates/times
    final dates = _extractDates(text);
    if (dates.isNotEmpty) {
      entities['dates'] = dates;
    }

    // Extract person names (after "with", "by", "assign to", "assigned to")
    final persons = _extractPersonNames(text);
    if (persons.isNotEmpty) {
      entities['persons'] = persons;
    }

    // Extract locations
    final locations = _extractLocations(text);
    if (locations.isNotEmpty) {
      entities['locations'] = locations;
    }

    // Extract action verbs
    final actions = _extractActionVerbs(text);
    if (actions.isNotEmpty) {
      entities['actions'] = actions;
    }

    return entities;
  }

  // Extract dates from text
  static List<String> _extractDates(String text) {
    final dates = <String>[];
    final lower = text.toLowerCase();

    // Relative dates
    final relativeDates = [
      'today',
      'tomorrow',
      'yesterday',
      'next week',
      'this week',
      'next month',
      'this month',
      'next year',
      'this year',
    ];

    for (final date in relativeDates) {
      if (lower.contains(date)) {
        dates.add(date);
      }
    }

    // Date patterns: MM/DD/YYYY, DD/MM/YYYY, MM-DD-YYYY, DD-MM-YYYY
    final datePatterns = [
      RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b'),
      RegExp(
        r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}(?:st|nd|rd|th)?(?:,\s*\d{4})?\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
        caseSensitive: false,
      ),
      // Time patterns: "at 3pm", "at 3:30", "by 5pm"
      RegExp(
        r'\b(at|by|before|after)\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in datePatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final matchedText = match.group(0) ?? '';
        if (matchedText.isNotEmpty) {
          dates.add(matchedText);
        }
      }
    }

    return dates.toSet().toList();
  }

  // Extract person names from text
  static List<String> _extractPersonNames(String text) {
    final persons = <String>[];

    // Patterns: "with John", "with John Doe", "by Jane", "assign to Bob", "assigned to Alice"
    // Also handle: "meeting with John", "call with Jane Smith"
    final patterns = [
      // "with [Name]" - can be preceded by words like "meeting", "call", etc.
      RegExp(
        r'\bwith\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
        caseSensitive: true,
      ),
      // "by [Name]" - can be preceded by words like "done", "created", etc.
      RegExp(r'\bby\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b', caseSensitive: true),
      // "assign to [Name]" or "assigned to [Name]"
      RegExp(
        r'\bassign(?:ed)?\s+to\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
        caseSensitive: true,
      ),
      // "for [Name]" - sometimes used for assignment
      RegExp(
        r'\bfor\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b',
        caseSensitive: true,
      ),
    ];

    // Common words to exclude (not names)
    final excludeWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
      'is',
      'was',
      'are',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'should',
      'could',
      'may',
      'might',
      'must',
      'can',
      'this',
      'that',
      'these',
      'those',
    };

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        if (match.groupCount > 0) {
          final name = match.group(1);
          if (name != null &&
              name.length > 1 &&
              !excludeWords.contains(name.toLowerCase())) {
            persons.add(name.trim());
          }
        }
      }
    }

    return persons.toSet().toList();
  }

  // Extract locations from text
  static List<String> _extractLocations(String text) {
    final locations = <String>[];

    // Common location indicators and patterns
    final locationPatterns = [
      // "at [Location]", "in [Location]", "on [Location]"
      RegExp(
        r'\b(at|in|on)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*(?:\s+(?:Room|Office|Building|Hall|Center|Centre|Place|Street|Avenue|Road))?)\b',
        caseSensitive: true,
      ),
      // "room [Number/Name]", "office [Number/Name]"
      RegExp(
        r'\b(room|office|building|location|venue|hall|center|centre)\s+([A-Z0-9][A-Za-z0-9\s]+)\b',
        caseSensitive: false,
      ),
      // Standalone location names (capitalized, multiple words)
      RegExp(
        r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})\s+(?:Room|Office|Building|Hall|Center|Centre|Place|Street|Avenue|Road)\b',
        caseSensitive: true,
      ),
    ];

    // Common words to exclude (not locations)
    final excludeWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'this',
      'that',
      'these',
      'those',
      'with',
      'by',
      'for',
      'from',
      'to',
      'of',
      'in',
      'on',
      'at',
    };

    for (final pattern in locationPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        String? location;
        if (match.groupCount >= 2) {
          // Take the location part (group 2)
          location = match.group(2);
        } else if (match.groupCount == 1) {
          location = match.group(1);
        }

        if (location != null &&
            location.length > 1 &&
            !excludeWords.contains(location.toLowerCase())) {
          locations.add(location.trim());
        }
      }
    }

    return locations.toSet().toList();
  }

  // Extract action verbs from text
  static List<String> _extractActionVerbs(String text) {
    final actions = <String>[];

    // Common action verbs - look for them as whole words or in context
    final actionVerbs = [
      'schedule',
      'meet',
      'call',
      'fix',
      'repair',
      'install',
      'review',
      'update',
      'create',
      'complete',
      'finish',
      'submit',
      'send',
      'prepare',
      'organize',
      'plan',
      'discuss',
      'analyze',
      'check',
      'verify',
      'conduct',
      'inspect',
      'document',
      'diagnose',
      'test',
      'block',
      'set',
      'assign',
      'delegate',
      'approve',
      'reject',
      'cancel',
      'reschedule',
    ];

    // Extract verbs that appear in the text
    for (final verb in actionVerbs) {
      // Look for verb as whole word (with word boundaries)
      final pattern = RegExp(r'\b' + verb + r'\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        actions.add(verb);
      }
    }

    return actions.toSet().toList();
  }

  // Get suggested actions based on category
  static List<String> getSuggestedActions(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        // Check if it's scheduling-related
        final categoryName = category.value.toLowerCase();
        if (categoryName.contains('work')) {
          // Check common work-related keywords to determine subcategory
          // For now, return general work actions
          return ['Block calendar', 'Set reminder', 'Prepare agenda'];
        }
        return ['Review task', 'Update status', 'Set deadline'];
      case TaskCategory.personal:
        return ['Add to personal calendar', 'Set personal reminder'];
      case TaskCategory.shopping:
        return ['Create shopping list', 'Check budget'];
      case TaskCategory.health:
        return [
          'Conduct inspection',
          'Update checklist',
          'Review safety protocols',
        ];
      case TaskCategory.other:
        return ['Review task', 'Set reminder'];
    }
  }

  // Get suggested actions based on detected category keywords
  static List<String> getSuggestedActionsByText(String text) {
    final lower = text.toLowerCase();

    // Scheduling category keywords: meeting, schedule, call, appointment, deadline
    if (RegExp(
      r'\b(meeting|schedule|call|appointment|deadline)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return [
        'Block calendar',
        'Set reminder',
        'Send invite',
        'Prepare agenda',
      ];
    }
    // Finance category keywords: payment, invoice, bill, budget, cost, expense
    else if (RegExp(
      r'\b(payment|invoice|bill|budget|cost|expense)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return [
        'Check budget',
        'Review records',
        'Get approval',
        'Generate invoice',
        'Update records',
      ];
    }
    // Technical category keywords: bug, fix, error, install, repair, maintain
    else if (RegExp(
      r'\b(bug|fix|error|install|repair|maintain)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return [
        'Diagnose issue',
        'Document fix',
        'Check resources',
        'Assign technician',
      ];
    }
    // Safety category keywords: safety, hazard, inspection, compliance, PPE
    else if (RegExp(
      r'\b(safety|hazard|inspection|compliance|ppe)\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return [
        'Conduct inspection',
        'Update checklist',
        'File report',
        'Notify supervisor',
      ];
    }

    // Default: return general actions
    return ['Review task', 'Set reminder'];
  }
}
