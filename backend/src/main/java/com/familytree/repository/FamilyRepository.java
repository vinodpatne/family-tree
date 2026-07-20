package com.familytree.repository;

import com.familytree.entity.FamilyEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface FamilyRepository extends JpaRepository<FamilyEntity, String> {
    List<FamilyEntity> findByCreatedBy(String userId);

    @Query("SELECT f FROM FamilyEntity f WHERE f.createdBy = :userId OR CAST(f.memberUserIds AS string) LIKE CONCAT('%', :userId, '%')")
    List<FamilyEntity> findFamiliesForUser(String userId);
}
