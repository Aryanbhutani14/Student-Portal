package com.placement.portal.controller;

import com.placement.portal.dto.JobDto;
import com.placement.portal.service.JobService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/jobs")
@RequiredArgsConstructor
public class JobController {

    private final JobService jobService;

    @PostMapping("/{id}/apply")
    public ResponseEntity<?> applyForJob(
            Principal principal,
            @PathVariable("id") Long jobId
    ) {
        Authentication auth = (Authentication) principal;
        boolean isStudent = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_STUDENT"));

        if (!isStudent) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only students are authorized to apply for jobs.");
        }

        try {
            jobService.applyForJob(principal.getName(), jobId);
            return ResponseEntity.ok("Application submitted successfully.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/create")
    public ResponseEntity<?> createJob(
            Principal principal,
            @RequestBody JobDto dto
    ) {
        Authentication auth = (Authentication) principal;
        boolean isRecruiter = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_RECRUITER"));

        if (!isRecruiter) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only recruiters are authorized to create jobs.");
        }

        String email = principal.getName();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(jobService.createJob(email, dto));
    }

    @GetMapping
    public ResponseEntity<List<JobDto>> getJobs(
            @RequestParam(value = "skill", required = false) String skill,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "type", required = false) String type
    ) {
        return ResponseEntity.ok(jobService.searchJobs(skill, location, type));
    }

    @GetMapping("/recruiter")
    public ResponseEntity<?> getRecruiterJobs(Principal principal) {
        Authentication auth = (Authentication) principal;
        boolean isRecruiter = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_RECRUITER"));

        if (!isRecruiter) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only recruiters can fetch recruiter-specific jobs.");
        }

        String email = principal.getName();
        return ResponseEntity.ok(jobService.getJobsByRecruiter(email));
    }
}
