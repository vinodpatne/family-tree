package com.familytree.service;

import com.familytree.entity.FamilyMemberEntity;
import com.familytree.repository.FamilyMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

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
                .relations(relations != null ? relations : Map.of(
                        "fatherId", "",
                        "motherId", "",
                        "spouseIds", List.of(),
                        "childrenIds", List.of()
                ))
                .createdBy(userId)
                .lastEditedBy(userId)
                .build();
        memberRepository.save(member);

        auditService.log(familyId, userId, "MEMBER_CREATED", "member", member.getId(), null, data);
        notifyFamily(familyId, "member.created", member.getId(), userId);
        return member;
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

    private void notifyFamily(String familyId, String type, String memberId, String userId) {
        Map<String, Object> event = Map.of(
                "type", type,
                "memberId", memberId,
                "byUser", userId,
                "at", Instant.now().toString()
        );
        messagingTemplate.convertAndSend("/topic/family/" + familyId, event);
    }
}
