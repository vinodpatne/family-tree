package com.familytree.repository;

import com.familytree.entity.FamilyMemberEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FamilyMemberRepository extends JpaRepository<FamilyMemberEntity, String> {
    List<FamilyMemberEntity> findByFamilyId(String familyId);
}
