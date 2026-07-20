import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/family.dart';
import '../../../models/family_member.dart';
import 'member_avatar.dart';

class OrgChartNode extends StatelessWidget {
  const OrgChartNode({
    super.key,
    required this.member,
    required this.settings,
    required this.isExpanded,
    required this.hasChildren,
    required this.onToggleExpand,
    required this.onAddCustomLink,
  });

  final FamilyMember member;
  final FamilySettings settings;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddCustomLink;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/family/${member.familyId}/member/${member.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 220,
          height: 90,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 4,
              ),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  children: [
                    MemberAvatar(member: member, settings: settings, size: 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${member.data['firstName'] ?? ''} ${member.data['lastName'] ?? ''}'.trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (member.data['profession'] ?? 'Unknown Role').toString(),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasChildren)
                Positioned(
                  top: -4,
                  right: -4,
                  child: IconButton(
                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
                    onPressed: onToggleExpand,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.add_circle, size: 24, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'customLink') {
                        onAddCustomLink();
                        return;
                      }
                      Map<String, String> query = {};
                      final isFemale = member.data['gender']?.toString().toLowerCase() == 'female';
                      if (value == 'childId') {
                        query['childId'] = member.id;
                      } else if (value == 'spouseId') {
                        query['spouseId'] = member.id;
                      } else if (value == 'sibling') {
                        if (member.relations.fatherId != null) query['fatherId'] = member.relations.fatherId!;
                        if (member.relations.motherId != null) query['motherId'] = member.relations.motherId!;
                      } else if (value == 'child') { 
                        if (isFemale) {
                          query['motherId'] = member.id;
                          if (member.relations.spouseIds.isNotEmpty) query['fatherId'] = member.relations.spouseIds.first;
                        } else {
                          query['fatherId'] = member.id;
                          if (member.relations.spouseIds.isNotEmpty) query['motherId'] = member.relations.spouseIds.first;
                        }
                      }
                      final uri = Uri(path: '/family/${member.familyId}/member/new', queryParameters: query);
                      context.go(uri.toString());
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'child', child: Text('Add Child')),
                      PopupMenuItem(value: 'childId', child: Text('Add Parent')),
                      PopupMenuItem(value: 'spouseId', child: Text('Add Spouse')),
                      PopupMenuItem(value: 'sibling', child: Text('Add Sibling')),
                      PopupMenuItem(value: 'customLink', child: Text('Add Custom Link')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
