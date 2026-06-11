package com.placement.portal.service;

import com.placement.portal.dto.JobDto;
import com.placement.portal.entity.Job;
import com.placement.portal.entity.Student;
import com.placement.portal.repository.JobRepository;
import com.placement.portal.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BookmarkService {

    private final StudentRepository studentRepository;
    private final JobRepository jobRepository;

    @Transactional
    public boolean toggleSaveJob(String email, Long jobId) {
        Student student = studentRepository.findByUserEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Student not found for email: " + email));
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new IllegalArgumentException("Job not found for ID: " + jobId));

        boolean isAlreadySaved = student.getSavedJobs().contains(job);
        if (isAlreadySaved) {
            student.getSavedJobs().remove(job);
        } else {
            student.getSavedJobs().add(job);
        }

        studentRepository.save(student);
        return !isAlreadySaved; // returns true if now saved, false if removed
    }

    @Transactional(readOnly = true)
    public List<JobDto> getSavedJobs(String email) {
        Student student = studentRepository.findByUserEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Student not found for email: " + email));

        return student.getSavedJobs().stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
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
