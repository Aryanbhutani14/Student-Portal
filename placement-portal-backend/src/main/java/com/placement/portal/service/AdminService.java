package com.placement.portal.service;

import com.placement.portal.dto.AdminStatsDto;
import com.placement.portal.dto.RecruiterDto;
import com.placement.portal.dto.StudentProfileDto;
import com.placement.portal.entity.Recruiter;
import com.placement.portal.entity.Student;
import com.placement.portal.repository.JobRepository;
import com.placement.portal.repository.RecruiterRepository;
import com.placement.portal.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final StudentRepository studentRepository;
    private final RecruiterRepository recruiterRepository;
    private final JobRepository jobRepository;

    public AdminStatsDto getAdminStats() {
        return AdminStatsDto.builder()
                .totalStudents(studentRepository.count())
                .totalRecruiters(recruiterRepository.count())
                .totalJobs(jobRepository.count())
                .build();
    }

    public List<RecruiterDto> getAllRecruiters() {
        return recruiterRepository.findAll().stream()
                .map(r -> RecruiterDto.builder()
                        .id(r.getId())
                        .email(r.getUser().getEmail())
                        .companyName(r.getCompanyName())
                        .website(r.getWebsite())
                        .verified(r.getVerified())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public void verifyRecruiter(Long recruiterId, boolean verified) {
        Recruiter recruiter = recruiterRepository.findById(recruiterId)
                .orElseThrow(() -> new IllegalArgumentException("Recruiter not found with id: " + recruiterId));
        recruiter.setVerified(verified);
        recruiterRepository.save(recruiter);
    }

    public List<StudentProfileDto> getAllStudents() {
        return studentRepository.findAll().stream()
                .map(s -> StudentProfileDto.builder()
                        .email(s.getUser().getEmail())
                        .name(s.getName())
                        .branch(s.getBranch())
                        .semester(s.getSemester())
                        .cgpa(s.getCgpa())
                        .skills(s.getSkills())
                        .certifications(s.getCertifications())
                        .projects(s.getProjects())
                        .experience(s.getExperience())
                        .github(s.getGithub())
                        .linkedin(s.getLinkedin())
                        .resumeUrl(s.getResumeUrl())
                        .build())
                .collect(Collectors.toList());
    }
}
