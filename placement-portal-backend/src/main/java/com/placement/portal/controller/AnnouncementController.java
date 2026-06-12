package com.placement.portal.controller;

import com.placement.portal.dto.AnnouncementDto;
import com.placement.portal.service.AnnouncementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequiredArgsConstructor
public class AnnouncementController {

    private final AnnouncementService announcementService;

    @PostMapping("/announcement")
    public ResponseEntity<?> createAnnouncement(
            Principal principal,
            @RequestBody AnnouncementDto dto
    ) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("User not authenticated.");
        }
        
        Authentication auth = (Authentication) principal;
        boolean isAdmin = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!isAdmin) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Only admins can create announcements.");
        }

        if (dto.getTitle() == null || dto.getTitle().trim().isEmpty() ||
            dto.getDescription() == null || dto.getDescription().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Title and description are required.");
        }

        try {
            AnnouncementDto created = announcementService.createAnnouncement(principal.getName(), dto);
            return ResponseEntity.status(HttpStatus.CREATED).body(created);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/announcements")
    public ResponseEntity<?> getAnnouncements() {
        List<AnnouncementDto> announcements = announcementService.getAnnouncements();
        return ResponseEntity.ok(announcements);
    }
}
