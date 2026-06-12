package com.placement.portal.controller;

import com.placement.portal.dto.RecruiterDto;
import com.placement.portal.service.RecruiterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@RestController
@RequestMapping("/recruiter")
@RequiredArgsConstructor
public class RecruiterController {

    private final RecruiterService recruiterService;

    private boolean isRecruiter(Principal principal) {
        if (principal instanceof Authentication) {
            return ((Authentication) principal).getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_RECRUITER"));
        }
        return false;
    }

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(Principal principal) {
        if (principal == null || !isRecruiter(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only recruiters can access this profile.");
        }
        try {
            String email = principal.getName();
            return ResponseEntity.ok(recruiterService.getRecruiterProfile(email));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(
            Principal principal,
            @RequestBody RecruiterDto requestDto
    ) {
        if (principal == null || !isRecruiter(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only recruiters can update this profile.");
        }
        try {
            String email = principal.getName();
            return ResponseEntity.ok(recruiterService.updateRecruiterProfile(email, requestDto));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
