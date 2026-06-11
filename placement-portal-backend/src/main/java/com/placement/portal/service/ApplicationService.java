package com.placement.portal.service;

import com.placement.portal.dto.ApplicationDto;
import com.placement.portal.entity.Application;
import com.placement.portal.entity.ApplicationStatus;
import com.placement.portal.entity.Job;
import com.placement.portal.entity.Student;
import com.placement.portal.repository.ApplicationRepository;
import com.placement.portal.repository.JobRepository;
import com.placement.portal.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ApplicationService {

    private final ApplicationRepository applicationRepository;
    private final StudentRepository studentRepository;
    private final JobRepository jobRepository;

    @Transactional
    public void applyForJob(String studentEmail, Long jobId) {
        Student student = studentRepository.findByUserEmail(studentEmail)
                .orElseThrow(() -> new IllegalArgumentException("Student not found for email: " + studentEmail));
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new IllegalArgumentException("Job not found for ID: " + jobId));

        if (applicationRepository.existsByStudentIdAndJobId(student.getId(), job.getId())) {
            throw new IllegalArgumentException("You have already applied for this job");
        }

        Application application = Application.builder()
                .student(student)
                .job(job)
                .build();
        applicationRepository.save(application);
    }

    @Transactional(readOnly = true)
    public List<ApplicationDto> getStudentApplications(String studentEmail) {
        List<Application> applications = applicationRepository.findByStudentUserEmail(studentEmail);
        return applications.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ApplicationDto> getRecruiterApplications(String recruiterEmail) {
        List<Application> applications = applicationRepository.findByJobRecruiterUserEmail(recruiterEmail);
        return applications.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public void updateApplicationStatus(String recruiterEmail, Long applicationId, String statusStr) {
        Application application = applicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("Application not found for ID: " + applicationId));

        // Security check: recruiter owns the job posting
        if (!application.getJob().getRecruiter().getUser().getEmail().equals(recruiterEmail)) {
            throw new SecurityException("You are not authorized to update this application's status.");
        }

        try {
            ApplicationStatus newStatus = ApplicationStatus.valueOf(statusStr.toUpperCase());
            application.setStatus(newStatus);
            applicationRepository.save(application);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid status: " + statusStr);
        }
    }

    private ApplicationDto mapToDto(Application application) {
        Job job = application.getJob();
        Student student = application.getStudent();
        return ApplicationDto.builder()
                .id(application.getId())
                .jobId(job.getId())
                .company(job.getRecruiter().getCompanyName())
                .role(job.getTitle())
                .location(job.getLocation())
                .salary(job.getSalary())
                .type(job.getJobType())
                .status(application.getStatus().name())
                .appliedDate(application.getAppliedDate())
                .studentName(student.getName())
                .studentEmail(student.getUser().getEmail())
                .studentBranch(student.getBranch())
                .studentSemester(student.getSemester())
                .studentCgpa(student.getCgpa())
                .studentSkills(student.getSkills())
                .studentResumeUrl(student.getResumeUrl())
                .build();
    }
}
