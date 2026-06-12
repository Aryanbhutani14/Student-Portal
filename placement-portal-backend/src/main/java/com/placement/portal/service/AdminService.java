package com.placement.portal.service;

import com.placement.portal.dto.AdminStatsDto;
import com.placement.portal.dto.AnalyticsDto;
import com.placement.portal.dto.RecruiterDto;
import com.placement.portal.dto.StudentProfileDto;
import com.placement.portal.entity.*;
import com.placement.portal.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final StudentRepository studentRepository;
    private final RecruiterRepository recruiterRepository;
    private final JobRepository jobRepository;
    private final ApplicationRepository applicationRepository;

    public AdminStatsDto getAdminStats() {
        return AdminStatsDto.builder()
                .totalStudents(studentRepository.count())
                .totalRecruiters(recruiterRepository.count())
                .totalJobs(jobRepository.count())
                .build();
    }

    public AnalyticsDto getAnalytics() {
        long totalStudents = studentRepository.count();
        long totalRecruiters = recruiterRepository.count();
        long totalJobs = jobRepository.count();

        List<Application> applications = applicationRepository.findAll();

        // 1. Placed students (distinct student IDs with status SELECTED)
        Set<Long> placedStudentIds = applications.stream()
                .filter(a -> a.getStatus() == ApplicationStatus.SELECTED)
                .map(a -> a.getStudent().getId())
                .collect(Collectors.toSet());

        long placedCount = placedStudentIds.size();
        double placementPercentage = totalStudents > 0 ? ((double) placedCount / totalStudents) * 100.0 : 0.0;

        // 2. Highest package
        List<Job> placedJobs = applications.stream()
                .filter(a -> a.getStatus() == ApplicationStatus.SELECTED)
                .map(Application::getJob)
                .collect(Collectors.toList());

        String highestPackage = "N/A";
        if (!placedJobs.isEmpty()) {
            Job maxJob = placedJobs.stream()
                    .max((j1, j2) -> Double.compare(parseSalaryToDouble(j1.getSalary()), parseSalaryToDouble(j2.getSalary())))
                    .orElse(null);
            if (maxJob != null) {
                highestPackage = maxJob.getSalary();
            }
        } else {
            // Fallback to highest salary of all jobs if no placements yet
            List<Job> allJobs = jobRepository.findAll();
            if (!allJobs.isEmpty()) {
                Job maxJob = allJobs.stream()
                        .max((j1, j2) -> Double.compare(parseSalaryToDouble(j1.getSalary()), parseSalaryToDouble(j2.getSalary())))
                        .orElse(null);
                if (maxJob != null) {
                    highestPackage = maxJob.getSalary();
                }
            }
        }

        // 3. Branch-wise placements (distinct students per branch)
        Map<String, Long> branchWisePlacements = applications.stream()
                .filter(a -> a.getStatus() == ApplicationStatus.SELECTED)
                .map(Application::getStudent)
                .collect(Collectors.toMap(
                        Student::getId,
                        s -> s,
                        (s1, s2) -> s1
                ))
                .values().stream()
                .collect(Collectors.groupingBy(
                        s -> s.getBranch() != null ? s.getBranch() : "Not Specified",
                        Collectors.counting()
                ));

        return AnalyticsDto.builder()
                .placementPercentage(placementPercentage)
                .highestPackage(highestPackage)
                .branchWisePlacements(branchWisePlacements)
                .totalStudents(totalStudents)
                .totalRecruiters(totalRecruiters)
                .totalJobs(totalJobs)
                .build();
    }

    private double parseSalaryToDouble(String salaryStr) {
        if (salaryStr == null) return 0.0;
        String clean = salaryStr.toLowerCase().replaceAll("[^0-9\\.]", "").trim();
        if (clean.isEmpty()) return 0.0;
        try {
            double val = Double.parseDouble(clean);
            if (salaryStr.toLowerCase().contains("lpa")) {
                return val;
            } else if (salaryStr.toLowerCase().contains("month")) {
                return (val * 12) / 100000.0;
            } else if (salaryStr.toLowerCase().contains("lakh")) {
                return val;
            } else if (val > 1000) {
                return val / 100000.0;
            }
            return val;
        } catch (NumberFormatException e) {
            return 0.0;
        }
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
