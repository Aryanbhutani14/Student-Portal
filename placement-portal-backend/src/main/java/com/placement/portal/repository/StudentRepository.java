package com.placement.portal.repository;

import com.placement.portal.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.util.Optional;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    Optional<Student> findByUserEmail(String email);

    @Modifying
    @Transactional
    @Query(value = "DELETE FROM saved_jobs", nativeQuery = true)
    void deleteSavedJobsRelation();
}

