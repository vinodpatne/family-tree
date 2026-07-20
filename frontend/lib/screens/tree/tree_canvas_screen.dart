import 'package:flutter/material.dart'; import 'package:flutter_riverpod/flutter_riverpod.dart'; import 'package:go_router/go_router.dart'; import 'package:graphview/GraphView.dart';
import '../../state/providers.dart'; import '../../widgets/app_scaffold.dart'; import '../../models/family_member.dart'; import 'widgets/org_chart_node.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../utils/download_helper.dart';
class SpouseCluster {
  final String id;
  final List<FamilyMember> members;
  SpouseCluster(this.id, this.members);
}

class CustomLinkPainter extends CustomPainter {
  final Map<String, Node> nodeMap;
  final List<FamilyMember> members;
  CustomLinkPainter(this.nodeMap, this.members);

  @override
  void paint(Canvas canvas, Size size) {
    final Set<String> drawnSpouses = {};

    for (final member in members) {
      // 1. Draw custom links
      final sourceNode = nodeMap[member.id];
      if (sourceNode != null) {
        for (final link in member.relations.customLinks) {
          final targetNode = nodeMap[link.targetId];
          if (targetNode == null) continue;

          final p1 = sourceNode.position;
          final p2 = targetNode.position;
          
          final c1 = Offset(p1.dx + 110, p1.dy + 70);
          final c2 = Offset(p2.dx + 110, p2.dy + 70);

          final paint = Paint()
            ..color = Colors.orange
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;

          if (link.isDotted) {
            final path = Path();
            final dist = (c2 - c1).distance;
            if (dist >= 1) {
              final dir = (c2 - c1) / dist;
              for (double d = 0; d < dist; d += 10) {
                final start = c1 + dir * d;
                final end = c1 + dir * (d + 5);
                path.moveTo(start.dx, start.dy);
                if (d + 5 < dist) path.lineTo(end.dx, end.dy);
              }
              canvas.drawPath(path, paint);
            }
          } else {
            canvas.drawLine(c1, c2, paint);
          }

          if (link.label.isNotEmpty) {
            final tp = TextPainter(
              text: TextSpan(text: ' ${link.label} ', style: const TextStyle(color: Colors.deepOrange, backgroundColor: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            tp.paint(canvas, Offset((c1.dx + c2.dx) / 2 - tp.width / 2, (c1.dy + c2.dy) / 2 - tp.height / 2));
          }
        }
      }

      // 2. Draw spouse links between parents who share children
      final fid = member.relations.fatherId;
      final mid = member.relations.motherId;

      if (fid != null && fid.isNotEmpty && mid != null && mid.isNotEmpty) {
        final pairKey = fid.compareTo(mid) < 0 ? '$fid-$mid' : '$mid-$fid';
        if (!drawnSpouses.contains(pairKey)) {
          drawnSpouses.add(pairKey);

          final fNode = nodeMap[fid];
          final mNode = nodeMap[mid];

          if (fNode != null && mNode != null) {
            final p1 = fNode.position;
            final p2 = mNode.position;
            
            final c1 = Offset(p1.dx + 110, p1.dy + 70);
            final c2 = Offset(p2.dx + 110, p2.dy + 70);

            final paint = Paint()
              ..color = Colors.pinkAccent
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke;

            final path = Path();
            final dist = (c2 - c1).distance;
            if (dist >= 1) {
              final dir = (c2 - c1) / dist;
              for (double d = 0; d < dist; d += 10) {
                final start = c1 + dir * d;
                final end = c1 + dir * (d + 5);
                path.moveTo(start.dx, start.dy);
                if (d + 5 < dist) path.lineTo(end.dx, end.dy);
              }
              canvas.drawPath(path, paint);

              final tp = TextPainter(
                text: const TextSpan(
                    text: ' spouse ',
                    style: TextStyle(color: Colors.pinkAccent, backgroundColor: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                textDirection: TextDirection.ltr,
              );
              tp.layout();
              tp.paint(canvas, Offset((c1.dx + c2.dx) / 2 - tp.width / 2, (c1.dy + c2.dy) / 2 - tp.height / 2));
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomLinkPainter oldDelegate) => true;
}

class TreeCanvasScreen extends ConsumerStatefulWidget{ const TreeCanvasScreen({super.key,required this.familyId}); final String familyId; @override ConsumerState<TreeCanvasScreen> createState()=>_S();} 
class _S extends ConsumerState<TreeCanvasScreen>{ 
  final Set<String> _collapsedNodes={}; 
  late final SugiyamaConfiguration builder = SugiyamaConfiguration()..nodeSeparation=40..levelSeparation=80..orientation=SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM; 
  late final SugiyamaAlgorithm _algorithm = SugiyamaAlgorithm(builder); 
  Graph? _graph; 
  List<FamilyMember>? _lastMembers; 
  Set<String>? _lastCollapsedNodes; 
  Map<String, Node> _nodeMap = {};
  List<SpouseCluster> _clusters = [];

  Graph _buildGraph(List<FamilyMember> members){ 
    bool membersUnchanged = _lastMembers != null && _lastMembers!.length == members.length; 
    if (membersUnchanged) { 
      for (int i = 0; i < members.length; i++) { 
        if (_lastMembers![i].id != members[i].id || _lastMembers![i].updatedAt != members[i].updatedAt) { 
          membersUnchanged = false; 
          break; 
        } 
      } 
    } 
    if(_graph!=null && membersUnchanged && _lastCollapsedNodes!=null && _lastCollapsedNodes!.length==_collapsedNodes.length && _lastCollapsedNodes!.containsAll(_collapsedNodes)){ 
      return _graph!; 
    } 
    _lastMembers=members; 
    _lastCollapsedNodes=Set.from(_collapsedNodes); 

    final spouseLinks = <String, Set<String>>{};
    final childrenMap = <String, Set<String>>{};
    
    for (final m in members) {
       spouseLinks.putIfAbsent(m.id, () => {});
       for (final sid in m.relations.spouseIds) {
           spouseLinks[m.id]!.add(sid);
       }
       if (m.relations.fatherId != null && m.relations.motherId != null) {
           spouseLinks.putIfAbsent(m.relations.fatherId!, () => {}).add(m.relations.motherId!);
           spouseLinks.putIfAbsent(m.relations.motherId!, () => {}).add(m.relations.fatherId!);
       }
       
       childrenMap.putIfAbsent(m.id, () => {}).addAll(m.relations.childrenIds);
    }
    
    for(final m in members){ 
      final fid = m.relations.fatherId;
      if(fid != null && fid.isNotEmpty) {
        childrenMap.putIfAbsent(fid, () => {}).add(m.id);
      }
      final mid = m.relations.motherId;
      if(mid != null && mid.isNotEmpty) {
        childrenMap.putIfAbsent(mid, () => {}).add(m.id);
      }
    } 

    final visitedClusters = <String>{};
    final clusters = <SpouseCluster>[];
    
    for (final m in members) {
      if (visitedClusters.contains(m.id)) continue;
      
      final clusterMembers = <String>{};
      final queue = [m.id];
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        if (clusterMembers.contains(current)) continue;
        clusterMembers.add(current);
        visitedClusters.add(current);
        for (final spouse in spouseLinks[current] ?? []) {
          if (!clusterMembers.contains(spouse)) {
            queue.add(spouse);
          }
        }
      }
      
      final sortedIds = clusterMembers.toList()..sort();
      final clusterId = sortedIds.join('_');
      final cMembers = sortedIds.map((id) => members.firstWhere((x) => x.id == id)).toList();
      cMembers.sort((a, b) {
         final ageA = int.tryParse(a.data['age']?.toString() ?? '') ?? 999;
         final ageB = int.tryParse(b.data['age']?.toString() ?? '') ?? 999;
         return ageA.compareTo(ageB);
      });
      clusters.add(SpouseCluster(clusterId, cMembers));
    }
    _clusters = clusters;

    final clusterChildrenMap = <String, Set<String>>{};
    for (final c in clusters) {
      final cChildIds = <String>{};
      for (final m in c.members) {
        cChildIds.addAll(childrenMap[m.id] ?? []);
      }
      
      for (final childId in cChildIds) {
        final childCluster = clusters.where((x) => x.members.any((cm) => cm.id == childId)).firstOrNull;
        if (childCluster != null) {
          clusterChildrenMap.putIfAbsent(c.id, () => {}).add(childCluster.id);
        }
      }
    }

    final hiddenClusters = <String>{};
    void markHidden(String cid) {
      if (hiddenClusters.contains(cid)) return;
      hiddenClusters.add(cid);
      for (final childId in clusterChildrenMap[cid] ?? []) {
        markHidden(childId);
      }
    }

    for (final c in clusters) {
       if (c.members.any((m) => _collapsedNodes.contains(m.id))) {
          for (final childId in clusterChildrenMap[c.id] ?? []) {
             markHidden(childId);
          }
       }
    }

    int getClusterAge(String cid) {
       final cluster = clusters.firstWhere((c) => c.id == cid);
       return cluster.members.map((m) => int.tryParse(m.data['age']?.toString() ?? '') ?? 999).fold(999, (a,b) => a < b ? a : b);
    }

    final allChildrenClusters = clusterChildrenMap.values.expand((e)=>e).toSet(); 
    final roots = clusters.where((c)=>!allChildrenClusters.contains(c.id)).toList(); 
    roots.sort((a, b) => getClusterAge(a.id).compareTo(getClusterAge(b.id)));

    final graph=Graph()..isTree=false; 
    final nodeMap=<String,Node>{}; 
    Node getNode(String id)=>nodeMap.putIfAbsent(id,()=>Node.Id(id)); 
    final visited=<String>{}; 
    
    void traverse(String id){ 
      if(visited.contains(id))return; 
      visited.add(id); 
      final node=getNode(id); 
      graph.addNode(node);
      final sortedChildren = (clusterChildrenMap[id] ?? []).toList();
      sortedChildren.sort((a, b) => getClusterAge(a).compareTo(getClusterAge(b)));
      for(final cid in sortedChildren){ 
        if (!hiddenClusters.contains(cid)) {
           graph.addEdge(node,getNode(cid)); 
           traverse(cid); 
        }
      } 
    } 
    for(final r in roots) {
      if (!hiddenClusters.contains(r.id)) {
        traverse(r.id);
      }
    }
    for(final c in clusters){ 
      if(!visited.contains(c.id) && !hiddenClusters.contains(c.id)){ 
        graph.addNode(getNode(c.id)); 
      } 
    } 
    _graph=graph; 
    
    _nodeMap = {};
    for (final c in clusters) {
      final node = nodeMap[c.id];
      if (node != null) {
        for (final m in c.members) {
          _nodeMap[m.id] = node;
        }
      }
    }

    return graph; 
  } 

  void _showAddCustomLinkDialog(BuildContext context, FamilyMember sourceMember, List<FamilyMember> members) {
    String? targetId;
    String label = '';
    bool isDotted = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Custom Link'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<FamilyMember>(
                    displayStringForOption: (m) => '${m.data['firstName']} ${m.data['lastName']}',
                    optionsBuilder: (t) => members.where((m) => m.id != sourceMember.id && '${m.data['firstName']} ${m.data['lastName']}'.toLowerCase().contains(t.text.toLowerCase())),
                    onSelected: (m) => setDialogState(() => targetId = m.id),
                    fieldViewBuilder: (c, tc, fn, sub) => TextField(
                      controller: tc,
                      focusNode: fn,
                      decoration: const InputDecoration(labelText: 'Search for target member...'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Link Label (e.g., Mentor)'),
                    onChanged: (v) => label = v,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Dotted Line?'),
                      const Spacer(),
                      Switch(value: isDotted, onChanged: (v) => setDialogState(() => isDotted = v)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    if (targetId == null) return;
                    final links = List<CustomLink>.from(sourceMember.relations.customLinks);
                    links.add(CustomLink(targetId: targetId!, label: label, isDotted: isDotted));
                    final updated = sourceMember.copyWith(relations: sourceMember.relations.copyWith(customLinks: links), updatedAt: DateTime.now());
                    await ref.read(repositoryProvider).saveMember(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override Widget build(BuildContext context){ 
    final fam=ref.watch(familyProvider(widget.familyId)).valueOrNull; 
    final members=ref.watch(membersProvider(widget.familyId)).valueOrNull??[]; 
    if(fam==null) return const Scaffold(body:Center(child:CircularProgressIndicator())); 
    final graph = _buildGraph(members); 
    
    final individualChildrenMap = <String, Set<String>>{}; 
    for(final m in members){ 
      individualChildrenMap.putIfAbsent(m.id, () => {}).addAll(m.relations.childrenIds); 
    } 
    for(final m in members){ 
      final fid = m.relations.fatherId;
      if(fid != null && fid.isNotEmpty) {
        individualChildrenMap.putIfAbsent(fid, () => {}).add(m.id);
      }
      final mid = m.relations.motherId;
      if(mid != null && mid.isNotEmpty) {
        individualChildrenMap.putIfAbsent(mid, () => {}).add(m.id);
      }
    } 

    final connectedClusterIds = <String>{};
    for (final edge in graph.edges) {
      final srcId = edge.source.key?.value as String?;
      final dstId = edge.destination.key?.value as String?;
      if (srcId != null) connectedClusterIds.add(srcId);
      if (dstId != null) connectedClusterIds.add(dstId);
    }
    
    final orphanMembers = <FamilyMember>[];
    for (final c in _clusters) {
      if (!connectedClusterIds.contains(c.id)) {
        orphanMembers.addAll(c.members);
      }
    }

    OrgChartNode buildNodeWidget(FamilyMember m) {
      final hasChildren = (individualChildrenMap[m.id]?.isNotEmpty ?? false);
      return OrgChartNode(
        key: ValueKey(m.id),
        member: m,
        settings: fam.settings,
        isExpanded: !_collapsedNodes.contains(m.id),
        hasChildren: hasChildren,
        onToggleExpand: () {
          setState(() {
            if (_collapsedNodes.contains(m.id))
              _collapsedNodes.remove(m.id);
            else
              _collapsedNodes.add(m.id);
          });
        },
        onAddCustomLink: () => _showAddCustomLinkDialog(context, m, members),
      );
    }

    return AppScaffold(
      title:fam.name, 
      familyId:widget.familyId, 
      actions:[
        IconButton(
          tooltip: 'Export to JSON',
          icon: const Icon(Icons.download),
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing Export...')));
            try {
              final exportedMembers = await ref.read(repositoryProvider).watchMembers(widget.familyId).first;
              final jsonStr = jsonEncode(exportedMembers.map((m) => m.toJson()).toList());
              downloadJsonFile('family_${widget.familyId}.json', jsonStr);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export Complete')));
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e')));
            }
          },
        ),
        IconButton(
          tooltip: 'Import from JSON',
          icon: const Icon(Icons.upload),
          onPressed: () async {
            try {
              final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
              if (result != null && result.files.single.bytes != null) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Importing...')));
                final jsonStr = utf8.decode(result.files.single.bytes!);
                final List<dynamic> parsed = jsonDecode(jsonStr);
                final batch = parsed.map((e) => Map<String, dynamic>.from(e)).toList();
                await ref.read(repositoryProvider).importMembers(widget.familyId, batch);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import Complete')));
              }
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e')));
            }
          },
        ),
        IconButton(onPressed:()=>context.go('/family/${widget.familyId}/member/new'), icon:const Icon(Icons.person_add))
      ], 
      child: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: Autocomplete<String>(optionsBuilder:(t)=>members.map((m)=>'${m.data['firstName']} ${m.data['lastName']}').where((n)=>n.toLowerCase().contains(t.text.toLowerCase())), onSelected:(s){final m=members.firstWhere((m)=>'$s'=='${m.data['firstName']} ${m.data['lastName']}'); context.go('/family/${widget.familyId}/member/${m.id}');}, fieldViewBuilder:(c,tc,fn,sub)=>TextField(controller:tc, focusNode:fn, decoration: const InputDecoration(prefixIcon:Icon(Icons.search), hintText:'Search family')))), 
        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No family members found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Add your first family member to start building the tree.'),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.go('/family/${widget.familyId}/member/new'),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Member'),
                      ),
                    ],
                  ),
                )
              : InteractiveViewer(
                  constrained: false,
                  minScale: .1,
                  maxScale: 2.5,
                  boundaryMargin: const EdgeInsets.all(2000),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (graph.edges.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Wrap(
                                spacing: 40,
                                runSpacing: 40,
                                children: members.map((m) => buildNodeWidget(m)).toList(),
                              ),
                            )
                          else ...[
                            GraphView(
                              graph: graph,
                              algorithm: _algorithm,
                              paint: Paint()
                                ..color = Colors.blueGrey
                                ..strokeWidth = 2
                                ..style = PaintingStyle.stroke,
                              builder: (Node n) {
                                final id = n.key?.value as String?;
                                final cluster = _clusters.where((x) => x.id == id).firstOrNull;
                                if (cluster == null) return const SizedBox();
                                
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (int i = 0; i < cluster.members.length; i++) ...[
                                      if (i > 0) const SizedBox(width: 20),
                                      buildNodeWidget(cluster.members[i]),
                                    ]
                                  ],
                                );
                              },
                            ),
                            if (orphanMembers.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 40, top: 20, right: 40, bottom: 40),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        'Unlinked Members',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 40,
                                      runSpacing: 40,
                                      children: orphanMembers.map((m) => buildNodeWidget(m)).toList(),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: CustomLinkPainter(_nodeMap, members),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ) 
      ])
    ); 
  }
}
extension FirstOrNull<E> on Iterable<E>{E? get firstOrNull=>isEmpty?null:first;}
