package com.familytree.repository;

import com.familytree.entity.AuditLogEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AuditLogRepository extends JpaRepository<AuditLogEntity, Long> {
    List<AuditLogEntity> findByFamilyIdOrderByTimestampDesc(String familyId);
}
