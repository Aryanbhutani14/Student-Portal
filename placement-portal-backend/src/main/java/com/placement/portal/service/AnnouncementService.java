package com.placement.portal.service;

import com.placement.portal.dto.AnnouncementDto;
import com.placement.portal.entity.Announcement;
import com.placement.portal.entity.User;
import com.placement.portal.repository.AnnouncementRepository;
import com.placement.portal.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AnnouncementService {

    private final AnnouncementRepository announcementRepository;
    private final UserRepository userRepository;

    @Transactional
    public AnnouncementDto createAnnouncement(String adminEmail, AnnouncementDto dto) {
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> new IllegalArgumentException("Admin user not found: " + adminEmail));

        Announcement announcement = Announcement.builder()
                .title(dto.getTitle())
                .description(dto.getDescription())
                .createdBy(admin)
                .build();

        announcement = announcementRepository.save(announcement);

        return AnnouncementDto.builder()
                .id(announcement.getId())
                .title(announcement.getTitle())
                .description(announcement.getDescription())
                .createdByEmail(admin.getEmail())
                .date(announcement.getDate())
                .build();
    }

    public List<AnnouncementDto> getAnnouncements() {
        return announcementRepository.findAllByOrderByDateDesc().stream()
                .map(a -> AnnouncementDto.builder()
                        .id(a.getId())
                        .title(a.getTitle())
                        .description(a.getDescription())
                        .createdByEmail(a.getCreatedBy() != null ? a.getCreatedBy().getEmail() : "System")
                        .date(a.getDate())
                        .build())
                .collect(Collectors.toList());
    }
}
