package com.familytree.repository;

import com.familytree.entity.FieldSchemaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface FieldSchemaRepository extends JpaRepository<FieldSchemaEntity, String> {
    Optional<FieldSchemaEntity> findByFamilyId(String familyId);
}
