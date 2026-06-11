package com.placement.portal.controller;

import com.placement.portal.dto.ApplicationDto;
import com.placement.portal.dto.ApplyRequest;
import com.placement.portal.service.ApplicationService;
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
}
