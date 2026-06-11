package com.placement.portal.controller;

import com.placement.portal.dto.ApplicationDto;
import com.placement.portal.dto.ApplyRequest;
import com.placement.portal.dto.SaveJobRequest;
import com.placement.portal.dto.StatusUpdateRequest;
import com.placement.portal.dto.JobDto;
import com.placement.portal.service.ApplicationService;
import com.placement.portal.service.BookmarkService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequiredArgsConstructor
public class ApplicationController {

    private final ApplicationService applicationService;
    private final BookmarkService bookmarkService;

    @PostMapping("/apply")
    public ResponseEntity<?> applyForJob(
            Principal principal,
            @RequestBody ApplyRequest request
    ) {
        if (request == null || request.getJobId() == null) {
            return ResponseEntity.badRequest().body("Job ID is required.");
        }

        Authentication auth = (Authentication) principal;
        boolean isStudent = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_STUDENT"));

        if (!isStudent) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only students are authorized to apply for jobs.");
        }

        try {
            applicationService.applyForJob(principal.getName(), request.getJobId());
            return ResponseEntity.ok("Application submitted successfully.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/student/applications")
    public ResponseEntity<?> getStudentApplications(Principal principal) {
        Authentication auth = (Authentication) principal;
        boolean isStudent = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_STUDENT"));

        if (!isStudent) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only students can fetch their applications.");
        }

        List<ApplicationDto> applications = applicationService.getStudentApplications(principal.getName());
        return ResponseEntity.ok(applications);
    }

    @GetMapping("/recruiter/applications")
    public ResponseEntity<?> getRecruiterApplications(Principal principal) {
        Authentication auth = (Authentication) principal;
        boolean isRecruiter = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_RECRUITER"));

        if (!isRecruiter) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only recruiters can fetch applications.");
        }

        List<ApplicationDto> applications = applicationService.getRecruiterApplications(principal.getName());
        return ResponseEntity.ok(applications);
    }

    @PatchMapping("/application/status")
    public ResponseEntity<?> updateApplicationStatus(
            Principal principal,
            @RequestBody StatusUpdateRequest request
    ) {
        if (request == null || request.getApplicationId() == null || request.getStatus() == null) {
            return ResponseEntity.badRequest().body("Application ID and status are required.");
        }

        Authentication auth = (Authentication) principal;
        boolean isRecruiter = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_RECRUITER"));

        if (!isRecruiter) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only recruiters are authorized to update status.");
        }

        try {
            applicationService.updateApplicationStatus(principal.getName(), request.getApplicationId(), request.getStatus());
            return ResponseEntity.ok("Application status updated successfully.");
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/save-job")
    public ResponseEntity<?> saveJob(
            Principal principal,
            @RequestBody SaveJobRequest request
    ) {
        if (request == null || request.getJobId() == null) {
            return ResponseEntity.badRequest().body("Job ID is required.");
        }

        Authentication auth = (Authentication) principal;
        boolean isStudent = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_STUDENT"));

        if (!isStudent) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only students are authorized to save jobs.");
        }

        try {
            boolean saved = bookmarkService.toggleSaveJob(principal.getName(), request.getJobId());
            if (saved) {
                return ResponseEntity.ok("Job bookmarked successfully.");
            } else {
                return ResponseEntity.ok("Job removed from bookmarks.");
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/saved-jobs")
    public ResponseEntity<?> getSavedJobs(Principal principal) {
        Authentication auth = (Authentication) principal;
        boolean isStudent = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_STUDENT"));

        if (!isStudent) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only students can fetch saved jobs.");
        }

        List<JobDto> savedJobs = bookmarkService.getSavedJobs(principal.getName());
        return ResponseEntity.ok(savedJobs);
    }
}
