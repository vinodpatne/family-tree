package com.familytree.controller;

import com.familytree.entity.FamilyMemberEntity;
import com.familytree.entity.UserEntity;
import com.familytree.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class MemberController {

    private final MemberService memberService;

    @GetMapping("/api/families/{familyId}/members")
    public ResponseEntity<List<FamilyMemberEntity>> getMembers(@PathVariable String familyId) {
        return ResponseEntity.ok(memberService.getMembers(familyId));
    }

    @PostMapping("/api/families/{familyId}/members")
    @SuppressWarnings("unchecked")
    public ResponseEntity<FamilyMemberEntity> createMember(
            @PathVariable String familyId,
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal UserEntity user) {
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        Map<String, Object> relations = (Map<String, Object>) body.get("relations");
        if (data == null) {
            return ResponseEntity.badRequest().build();
        }
        FamilyMemberEntity member = memberService.createMember(familyId, data, relations, user.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(member);
    }

    @PostMapping("/api/families/{familyId}/members/batch")
    public ResponseEntity<Void> importMembers(
            @PathVariable String familyId,
            @RequestBody List<Map<String, Object>> membersBatch,
            @AuthenticationPrincipal UserEntity user) {
        memberService.importMembersBatch(familyId, membersBatch, user.getId());
        return ResponseEntity.ok().build();
    }

    @PatchMapping("/api/members/{memberId}")
    public ResponseEntity<FamilyMemberEntity> updateMember(
            @PathVariable String memberId,
            @RequestBody Map<String, Object> patch,
            @AuthenticationPrincipal UserEntity user) {
        FamilyMemberEntity updated = memberService.updateMember(memberId, patch, user.getId());
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/api/members/{memberId}")
    public ResponseEntity<Void> deleteMember(
            @PathVariable String memberId,
            @AuthenticationPrincipal UserEntity user) {
        memberService.deleteMember(memberId, user.getId());
        return ResponseEntity.noContent().build();
    }
}
