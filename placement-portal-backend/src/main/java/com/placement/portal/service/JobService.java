package com.placement.portal.service;

import com.placement.portal.dto.JobDto;
import com.placement.portal.entity.Job;
import com.placement.portal.entity.Recruiter;
import com.placement.portal.entity.Student;
import com.placement.portal.entity.Application;
import com.placement.portal.repository.JobRepository;
import com.placement.portal.repository.RecruiterRepository;
import com.placement.portal.repository.StudentRepository;
import com.placement.portal.repository.ApplicationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class JobService {

    private final JobRepository jobRepository;
    private final RecruiterRepository recruiterRepository;
    private final StudentRepository studentRepository;
    private final ApplicationRepository applicationRepository;

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

    @Transactional
    public JobDto createJob(String email, JobDto dto) {
        Recruiter recruiter = recruiterRepository.findByUserEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Recruiter not found for email: " + email));

        Job job = Job.builder()
                .title(dto.getRole())
                .description(dto.getDescription())
                .location(dto.getLocation())
                .salary(dto.getSalary())
                .skillsRequired(dto.getSkillsRequired())
                .deadline(dto.getDeadline())
                .jobType(dto.getType())
                .recruiter(recruiter)
                .build();

        Job savedJob = jobRepository.save(job);
        return mapToDto(savedJob);
    }

    @Transactional(readOnly = true)
    public List<JobDto> searchJobs(String skill, String location, String type) {
        List<Job> allJobs = jobRepository.findAll();

        return allJobs.stream()
                .filter(job -> {
                    if (skill != null && !skill.trim().isEmpty()) {
                        String s = skill.trim().toLowerCase();
                        if (job.getSkillsRequired() == null || !job.getSkillsRequired().toLowerCase().contains(s)) {
                            return false;
                        }
                    }
                    if (location != null && !location.trim().isEmpty()) {
                        String loc = location.trim().toLowerCase();
                        if (job.getLocation() == null || !job.getLocation().toLowerCase().contains(loc)) {
                            return false;
                        }
                    }
                    if (type != null && !type.trim().isEmpty() && !type.equalsIgnoreCase("All")) {
                        String t = type.trim();
                        if (job.getJobType() == null || !job.getJobType().equalsIgnoreCase(t)) {
                            return false;
                        }
                    }
                    return true;
                })
                .sorted((j1, j2) -> j2.getId().compareTo(j1.getId()))
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<JobDto> getJobsByRecruiter(String email) {
        List<Job> jobs = jobRepository.findByRecruiterUserEmail(email);
        return jobs.stream().map(this::mapToDto).collect(Collectors.toList());
    }

    private JobDto mapToDto(Job job) {
        return JobDto.builder()
                .id(job.getId())
                .company(job.getRecruiter().getCompanyName())
                .role(job.getTitle())
                .description(job.getDescription())
                .location(job.getLocation())
                .salary(job.getSalary())
                .skillsRequired(job.getSkillsRequired())
                .deadline(job.getDeadline())
                .type(job.getJobType())
                .recruiterId(job.getRecruiter().getId())
                .build();
    }
}
