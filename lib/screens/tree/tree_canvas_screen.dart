import 'package:flutter/material.dart'; import 'package:flutter_riverpod/flutter_riverpod.dart'; import 'package:go_router/go_router.dart'; import 'package:graphview/GraphView.dart';
import '../../state/providers.dart'; import '../../widgets/app_scaffold.dart'; import '../../models/family_member.dart'; import 'widgets/org_chart_node.dart';

class CustomLinkPainter extends CustomPainter {
  final Map<String, Node> nodeMap;
  final List<FamilyMember> members;
  CustomLinkPainter(this.nodeMap, this.members);

  @override
  void paint(Canvas canvas, Size size) {
    for (final member in members) {
      final sourceNode = nodeMap[member.id];
      if (sourceNode == null) continue;

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
          final dir = (c2 - c1) / dist;
          for (double d = 0; d < dist; d += 10) {
            final start = c1 + dir * d;
            final end = c1 + dir * (d + 5);
            path.moveTo(start.dx, start.dy);
            if (d + 5 < dist) path.lineTo(end.dx, end.dy);
          }
          canvas.drawPath(path, paint);
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
    final childrenMap=<String,List<String>>{}; 
    for(final m in members){ 
      childrenMap[m.id]=List.from(m.relations.childrenIds); 
    } 
    for(final m in members){ 
      if(m.relations.fatherId!=null && !childrenMap[m.relations.fatherId!]!.contains(m.id)) childrenMap[m.relations.fatherId!]!.add(m.id); 
      if(m.relations.motherId!=null && !childrenMap[m.relations.motherId!]!.contains(m.id)) childrenMap[m.relations.motherId!]!.add(m.id); 
    } 
    final allChildren=childrenMap.values.expand((e)=>e).toSet(); 
    final roots=members.where((m)=>!allChildren.contains(m.id)).toList(); 

    // Find all hidden nodes (descendants of any collapsed node)
    final hiddenNodes = <String>{};
    void markHidden(String id) {
      if (hiddenNodes.contains(id)) return;
      hiddenNodes.add(id);
      for (final cid in childrenMap[id] ?? []) {
        markHidden(cid);
      }
    }
    for (final cid in _collapsedNodes) {
      for (final childId in childrenMap[cid] ?? []) {
        markHidden(childId);
      }
    }

    final graph=Graph()..isTree=false; 
    final nodeMap=<String,Node>{}; 
    Node getNode(String id)=>nodeMap.putIfAbsent(id,()=>Node.Id(id)); 
    final visited=<String>{}; 
    void traverse(String id){ 
      if(visited.contains(id))return; 
      visited.add(id); 
      final node=getNode(id); 
      for(final cid in childrenMap[id]??[]){ 
        if (!hiddenNodes.contains(cid)) {
          graph.addEdge(node,getNode(cid)); 
          traverse(cid); 
        }
      } 
    } 
    for(final r in roots) {
      if (!hiddenNodes.contains(r.id)) {
        traverse(r.id);
      }
    }
    for(final m in members){ 
      if(!visited.contains(m.id) && !hiddenNodes.contains(m.id)){ 
        getNode(m.id); 
      } 
    } 
    _graph=graph; 
    _nodeMap = nodeMap;
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
    final childrenMap=<String,List<String>>{}; 
    for(final m in members){ 
      childrenMap[m.id]=List.from(m.relations.childrenIds); 
      if(m.relations.fatherId!=null && !childrenMap[m.relations.fatherId!]!.contains(m.id)) childrenMap[m.relations.fatherId!]!.add(m.id); 
      if(m.relations.motherId!=null && !childrenMap[m.relations.motherId!]!.contains(m.id)) childrenMap[m.relations.motherId!]!.add(m.id); 
    } 
    return AppScaffold(
      title:fam.name, 
      familyId:widget.familyId, 
      actions:[IconButton(onPressed:()=>context.go('/family/${widget.familyId}/member/new'), icon:const Icon(Icons.person_add))], 
      child: Column(children:[
        Padding(padding: const EdgeInsets.all(12), child: Autocomplete<String>(optionsBuilder:(t)=>members.map((m)=>'${m.data['firstName']} ${m.data['lastName']}').where((n)=>n.toLowerCase().contains(t.text.toLowerCase())), onSelected:(s){final m=members.firstWhere((m)=>'$s'=='${m.data['firstName']} ${m.data['lastName']}'); context.go('/family/${widget.familyId}/member/${m.id}');}, fieldViewBuilder:(c,tc,fn,sub)=>TextField(controller:tc, focusNode:fn, decoration: const InputDecoration(prefixIcon:Icon(Icons.search), hintText:'Search family')))), 
        Expanded(
          child: InteractiveViewer(
            constrained:false, 
            minScale:.1,maxScale:2.5,boundaryMargin: const EdgeInsets.all(2000), 
            child: members.isEmpty ? const Center(child: Text('No members found.')) : 
            Stack(
              clipBehavior: Clip.none,
              children: [
                GraphView(
                  graph:graph, 
                  algorithm:_algorithm, 
                  paint:Paint()..color=Colors.blueGrey..strokeWidth=2..style=PaintingStyle.stroke, 
                  builder:(Node n){ 
                    final id=n.key?.value as String?; 
                    final m=members.where((x)=>x.id==id).firstOrNull; 
                    if(m==null)return const SizedBox(); 
                    final hasChildren=(childrenMap[m.id]?.isNotEmpty??false); 
                    return OrgChartNode(
                      member:m, 
                      settings:fam.settings, 
                      isExpanded:!_collapsedNodes.contains(m.id), 
                      hasChildren:hasChildren, 
                      onToggleExpand:(){ 
                        setState((){ 
                          if(_collapsedNodes.contains(m.id)) _collapsedNodes.remove(m.id); else _collapsedNodes.add(m.id); 
                        }); 
                      },
                      onAddCustomLink: () => _showAddCustomLinkDialog(context, m, members),
                    ); 
                  }
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CustomLinkPainter(_nodeMap, members),
                    ),
                  ),
                ),
              ],
            )
          )
        ) 
      ])
    ); 
  }
}
extension FirstOrNull<E> on Iterable<E>{E? get firstOrNull=>isEmpty?null:first;}
