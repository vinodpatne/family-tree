package com.familytree.service;

import com.familytree.entity.AuditLogEntity;
import com.familytree.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public void log(String familyId, String userId, String action,
                    String entityType, String entityId,
                    Map<String, Object> before, Map<String, Object> after) {
        auditLogRepository.save(AuditLogEntity.builder()
                .familyId(familyId)
                .userId(userId)
                .action(action)
                .entityType(entityType)
                .entityId(entityId)
                .beforeData(before)
                .afterData(after)
                .timestamp(Instant.now())
                .build());
    }
}
