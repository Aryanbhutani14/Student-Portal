package com.placement.portal.controller;

import com.placement.portal.dto.AdminStatsDto;
import com.placement.portal.dto.AnalyticsDto;
import com.placement.portal.dto.RecruiterDto;
import com.placement.portal.dto.StudentProfileDto;
import com.placement.portal.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    private boolean isAdmin(Principal principal) {
        Authentication auth = (Authentication) principal;
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getStats(Principal principal) {
        if (principal == null || !isAdmin(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only admins can access stats.");
        }
        AdminStatsDto stats = adminService.getAdminStats();
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/analytics")
    public ResponseEntity<?> getAnalytics(Principal principal) {
        if (principal == null || !isAdmin(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only admins can access analytics.");
        }
        AnalyticsDto analytics = adminService.getAnalytics();
        return ResponseEntity.ok(analytics);
    }

    @GetMapping("/recruiters")
    public ResponseEntity<?> getRecruiters(Principal principal) {
        if (principal == null || !isAdmin(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only admins can fetch recruiters.");
        }
        List<RecruiterDto> recruiters = adminService.getAllRecruiters();
        return ResponseEntity.ok(recruiters);
    }

    @PostMapping("/recruiters/{id}/verify")
    public ResponseEntity<?> verifyRecruiter(
            Principal principal,
            @PathVariable Long id,
            @RequestParam boolean verified
    ) {
        if (principal == null || !isAdmin(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only admins can verify recruiters.");
        }
        try {
            adminService.verifyRecruiter(id, verified);
            return ResponseEntity.ok("Recruiter status updated successfully.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/students")
    public ResponseEntity<?> getStudents(Principal principal) {
        if (principal == null || !isAdmin(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only admins can view students.");
        }
        List<StudentProfileDto> students = adminService.getAllStudents();
        return ResponseEntity.ok(students);
    }

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(Principal principal) {
        if (principal == null || !isAdmin(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only admins can view admin profile.");
        }
        return ResponseEntity.ok(java.util.Map.of(
            "email", principal.getName(),
            "role", "ADMIN",
            "isVerified", true
        ));
    }
}

