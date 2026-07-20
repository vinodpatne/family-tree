package com.familytree.service;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.UUID;

import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.familytree.entity.FamilyMemberEntity;
import com.familytree.repository.FamilyMemberRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class MemberService {

    private final FamilyMemberRepository memberRepository;
    private final AuditService auditService;
    private final SimpMessagingTemplate messagingTemplate;

    public List<FamilyMemberEntity> getMembers(String familyId) {
        return memberRepository.findByFamilyId(familyId);
    }

    public Optional<FamilyMemberEntity> getMember(String memberId) {
        return memberRepository.findById(memberId);
    }

    @Transactional
    public FamilyMemberEntity createMember(String familyId, Map<String, Object> data,
            Map<String, Object> relations, String userId) {
        FamilyMemberEntity member = FamilyMemberEntity.builder()
                .id(UUID.randomUUID().toString())
                .familyId(familyId)
                .schemaVersion(1)
                .data(data)
                .relations(relations != null ? relations
                        : new HashMap<>(Map.of(
                                "fatherId", "",
                                "motherId", "",
                                "spouseIds", List.of(),
                                "childrenIds", List.of())))
                .createdBy(userId)
                .lastEditedBy(userId)
                .build();
                
        autoLinkRelations(member);
        memberRepository.save(member);

        auditService.log(familyId, userId, "MEMBER_CREATED", "member", member.getId(), null, data);
        notifyFamily(familyId, "member.created", member.getId(), userId);
        return member;
    }

    @Transactional
    public void importMembersBatch(String familyId, List<Map<String, Object>> membersBatch, String userId) {
        List<FamilyMemberEntity> entitiesToSave = new java.util.ArrayList<>();
        for (Map<String, Object> body : membersBatch) {
            @SuppressWarnings("unchecked")
            Map<String, Object> data = (Map<String, Object>) body.get("data");
            @SuppressWarnings("unchecked")
            Map<String, Object> relations = (Map<String, Object>) body.get("relations");
            
            String id = (String) body.get("id");
            if (id == null || id.isBlank()) {
                id = UUID.randomUUID().toString();
            }
            
            FamilyMemberEntity member = FamilyMemberEntity.builder()
                    .id(id)
                    .familyId(familyId)
                    .schemaVersion(1)
                    .data(data != null ? data : new HashMap<>())
                    .relations(relations != null ? relations : new HashMap<>())
                    .createdBy(userId)
                    .lastEditedBy(userId)
                    .updatedAt(Instant.now())
                    .build();
                    
            entitiesToSave.add(member);
        }
        memberRepository.saveAll(entitiesToSave);
        auditService.log(familyId, userId, "MEMBERS_IMPORTED", "family", familyId, null, Map.of("count", entitiesToSave.size()));
        notifyFamily(familyId, "members.imported", familyId, userId);
    }

    @Transactional
    public FamilyMemberEntity updateMember(String memberId, Map<String, Object> patch, String userId) {
        FamilyMemberEntity member = memberRepository.findById(memberId)
                .orElseThrow(() -> new NoSuchElementException("Member not found: " + memberId));

        Map<String, Object> before = new HashMap<>(member.getData());

        if (patch.containsKey("data")) {
            @SuppressWarnings("unchecked")
            Map<String, Object> newData = (Map<String, Object>) patch.get("data");
            member.setData(newData);
        }
        if (patch.containsKey("relations")) {
            @SuppressWarnings("unchecked")
            Map<String, Object> newRelations = (Map<String, Object>) patch.get("relations");
            member.setRelations(newRelations);
        }
        if (patch.containsKey("photoBase64")) {
            member.setPhotoBase64((String) patch.get("photoBase64"));
        }

        autoLinkRelations(member);

        // Cascading parent last name updates
        String gender = (String) member.getData().get("gender");
        if (gender != null) {
            String oldLastName = "";
            String newLastName = "";
            if ("male".equals(gender)) {
                oldLastName = (String) before.get("lastName");
                newLastName = (String) member.getData().get("lastName");
            } else if ("female".equals(gender)) {
                oldLastName = (String) before.get("maidenLastName");
                newLastName = (String) member.getData().get("maidenLastName");
            }

            if (oldLastName != null && newLastName != null && !oldLastName.equals(newLastName) && !oldLastName.trim().isEmpty()) {
                Map<String, Object> relations = member.getRelations();
                if (relations != null) {
                    String fatherId = (String) relations.get("fatherId");
                    String motherId = (String) relations.get("motherId");

                    if (fatherId != null && !fatherId.isEmpty()) {
                        memberRepository.findById(fatherId).ifPresent(father -> {
                            Map<String, Object> fatherData = father.getData();
                            if (fatherData != null && oldLastName.equals(fatherData.get("lastName"))) {
                                Map<String, Object> beforeFather = new HashMap<>(fatherData);
                                fatherData.put("lastName", newLastName);
                                father.setLastEditedBy(userId);
                                father.setUpdatedAt(Instant.now());
                                memberRepository.save(father);
                                auditService.log(father.getFamilyId(), userId, "MEMBER_UPDATED", "member", fatherId, beforeFather, fatherData);
                                notifyFamily(father.getFamilyId(), "member.updated", fatherId, userId);
                            }
                        });
                    }

                    if (motherId != null && !motherId.isEmpty()) {
                        memberRepository.findById(motherId).ifPresent(mother -> {
                            Map<String, Object> motherData = mother.getData();
                            if (motherData != null && oldLastName.equals(motherData.get("lastName"))) {
                                Map<String, Object> beforeMother = new HashMap<>(motherData);
                                motherData.put("lastName", newLastName);
                                mother.setLastEditedBy(userId);
                                mother.setUpdatedAt(Instant.now());
                                memberRepository.save(mother);
                                auditService.log(mother.getFamilyId(), userId, "MEMBER_UPDATED", "member", motherId, beforeMother, motherData);
                                notifyFamily(mother.getFamilyId(), "member.updated", motherId, userId);
                            }
                        });
                    }
                }
            }
        }

        member.setLastEditedBy(userId);
        member.setUpdatedAt(Instant.now());
        memberRepository.save(member);

        auditService.log(member.getFamilyId(), userId, "MEMBER_UPDATED", "member", memberId, before, member.getData());
        notifyFamily(member.getFamilyId(), "member.updated", memberId, userId);
        return member;
    }

    @Transactional
    public void deleteMember(String memberId, String userId) {
        FamilyMemberEntity member = memberRepository.findById(memberId)
                .orElseThrow(() -> new NoSuchElementException("Member not found: " + memberId));
        String familyId = member.getFamilyId();

        auditService.log(familyId, userId, "MEMBER_DELETED", "member", memberId, member.getData(), null);
        memberRepository.delete(member);
        notifyFamily(familyId, "member.deleted", memberId, userId);
    }

    private void autoLinkRelations(FamilyMemberEntity member) {
        Map<String, Object> data = member.getData();
        Map<String, Object> relations = member.getRelations();
        if (data == null || relations == null) return;

        List<FamilyMemberEntity> allMembers = memberRepository.findByFamilyId(member.getFamilyId());

        linkParentTopDown(member, allMembers, "fatherId", "fatherFirstName", "fatherLastName", "male");
        linkParentTopDown(member, allMembers, "motherId", "motherFirstName", "motherLastName", "female");
        linkChildrenBottomUp(member, allMembers);
    }

    private void linkParentTopDown(FamilyMemberEntity member, List<FamilyMemberEntity> allMembers, 
                                   String parentIdKey, String parentFirstKey, String parentLastKey, String parentGender) {
        Map<String, Object> relations = member.getRelations();
        Map<String, Object> data = member.getData();
        
        String parentId = (String) relations.get(parentIdKey);
        if (parentId == null || parentId.trim().isEmpty()) {
            String parentFirst = (String) data.get(parentFirstKey);
            String parentLast = (String) data.get(parentLastKey);
            
            if (parentFirst != null && !parentFirst.trim().isEmpty() &&
                parentLast != null && !parentLast.trim().isEmpty()) {

                Optional<FamilyMemberEntity> matchingParent = allMembers.stream()
                    .filter(m -> m.getData() != null &&
                                 !m.getId().equals(member.getId()) &&
                                 parentFirst.equals(m.getData().get("firstName")) &&
                                 parentLast.equals(m.getData().get("lastName")) &&
                                 parentGender.equals(m.getData().get("gender")))
                    .findFirst();

                if (matchingParent.isPresent()) {
                    FamilyMemberEntity parent = matchingParent.get();
                    relations.put(parentIdKey, parent.getId());
                    addChildToParent(parent, member.getId());
                    memberRepository.save(parent);
                }
            }
        }
    }

    private void linkChildrenBottomUp(FamilyMemberEntity member, List<FamilyMemberEntity> allMembers) {
        Map<String, Object> data = member.getData();
        String myFirstName = (String) data.get("firstName");
        String myLastName = (String) data.get("lastName");
        String myGender = (String) data.get("gender");

        if (myFirstName == null || myFirstName.trim().isEmpty() ||
            myLastName == null || myLastName.trim().isEmpty() || myGender == null) {
            return;
        }

        for (FamilyMemberEntity other : allMembers) {
            if (other.getId().equals(member.getId()) || other.getData() == null || other.getRelations() == null) continue;

            if ("female".equals(myGender)) {
                checkAndLinkChild(member, other, allMembers, "motherId", "motherFirstName", "motherLastName", "fatherId");
            } else if ("male".equals(myGender)) {
                checkAndLinkChild(member, other, allMembers, "fatherId", "fatherFirstName", "fatherLastName", "motherId");
            }
        }
    }

    private void checkAndLinkChild(FamilyMemberEntity parent, FamilyMemberEntity child, List<FamilyMemberEntity> allMembers,
                                   String parentIdKey, String parentFirstKey, String parentLastKey, String spouseIdKey) {
        Map<String, Object> childData = child.getData();
        Map<String, Object> childRelations = child.getRelations();
        
        String parentFirst = (String) parent.getData().get("firstName");
        String parentLast = (String) parent.getData().get("lastName");

        String childParentFirst = (String) childData.get(parentFirstKey);
        String childParentLast = (String) childData.get(parentLastKey);
        String currentParentId = (String) childRelations.get(parentIdKey);

        if ((currentParentId == null || currentParentId.trim().isEmpty()) &&
            parentFirst.equals(childParentFirst) && parentLast.equals(childParentLast)) {

            // Link child to this parent
            childRelations.put(parentIdKey, parent.getId());
            
            // Link this parent to child
            addChildToParent(parent, child.getId());

            // Auto-link spouse
            String childSpouseId = (String) childRelations.get(spouseIdKey);
            if (childSpouseId != null && !childSpouseId.trim().isEmpty()) {
                Optional<FamilyMemberEntity> spouseOpt = allMembers.stream()
                        .filter(m -> m.getId().equals(childSpouseId)).findFirst();
                if (spouseOpt.isPresent()) {
                    FamilyMemberEntity spouse = spouseOpt.get();
                    linkSpouses(parent, spouse);
                    memberRepository.save(spouse);
                }
            }
            
            memberRepository.save(child);
        }
    }

    private void addChildToParent(FamilyMemberEntity parent, String childId) {
        Map<String, Object> parentRelations = parent.getRelations();
        if (parentRelations != null) {
            @SuppressWarnings("unchecked")
            List<String> childrenIds = parentRelations.containsKey("childrenIds") ?
                    new java.util.ArrayList<>((List<String>) parentRelations.get("childrenIds")) : new java.util.ArrayList<>();
            if (!childrenIds.contains(childId)) {
                childrenIds.add(childId);
                parentRelations.put("childrenIds", childrenIds);
            }
        }
    }

    private void linkSpouses(FamilyMemberEntity p1, FamilyMemberEntity p2) {
        addSpouseToMember(p1, p2.getId());
        addSpouseToMember(p2, p1.getId());
    }

    private void addSpouseToMember(FamilyMemberEntity member, String spouseId) {
        Map<String, Object> relations = member.getRelations();
        if (relations != null) {
            @SuppressWarnings("unchecked")
            List<String> spouses = relations.containsKey("spouseIds") ?
                    new java.util.ArrayList<>((List<String>) relations.get("spouseIds")) : new java.util.ArrayList<>();
            if (!spouses.contains(spouseId)) {
                spouses.add(spouseId);
                relations.put("spouseIds", spouses);
            }
        }
    }

    private void notifyFamily(String familyId, String type, String memberId, String userId) {
        Map<String, Object> event = Map.of(
                "type", type,
                "memberId", memberId,
                "byUser", userId,
                "at", Instant.now().toString());
        messagingTemplate.convertAndSend("/topic/family/" + familyId, event);
    }
}
