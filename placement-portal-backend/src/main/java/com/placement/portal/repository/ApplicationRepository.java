package com.placement.portal.repository;

import com.placement.portal.entity.Application;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ApplicationRepository extends JpaRepository<Application, Long> {
    boolean existsByStudentIdAndJobId(Long studentId, Long jobId);
    List<Application> findByStudentUserEmail(String email);
    List<Application> findByJobRecruiterUserEmail(String email);
}
