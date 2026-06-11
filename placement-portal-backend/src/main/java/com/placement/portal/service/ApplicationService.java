package com.placement.portal.service;

import com.placement.portal.dto.ApplicationDto;
import com.placement.portal.entity.Application;
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

    private ApplicationDto mapToDto(Application application) {
        Job job = application.getJob();
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
                .build();
    }
}
