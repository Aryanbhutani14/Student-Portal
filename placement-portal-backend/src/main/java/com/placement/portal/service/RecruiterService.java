package com.placement.portal.service;

import com.placement.portal.dto.RecruiterDto;
import com.placement.portal.entity.Recruiter;
import com.placement.portal.repository.RecruiterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RecruiterService {

    private final RecruiterRepository recruiterRepository;

    @Transactional(readOnly = true)
    public RecruiterDto getRecruiterProfile(String email) {
        Recruiter recruiter = recruiterRepository.findByUserEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Recruiter not found for user: " + email));
        return mapToDto(recruiter);
    }

    @Transactional
    public RecruiterDto updateRecruiterProfile(String email, RecruiterDto dto) {
        Recruiter recruiter = recruiterRepository.findByUserEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Recruiter not found for user: " + email));

        if (dto.getCompanyName() != null && !dto.getCompanyName().isBlank()) {
            recruiter.setCompanyName(dto.getCompanyName().trim());
        }
        if (dto.getWebsite() != null) {
            recruiter.setWebsite(dto.getWebsite().trim());
        }

        Recruiter updated = recruiterRepository.save(recruiter);
        return mapToDto(updated);
    }

    private RecruiterDto mapToDto(Recruiter recruiter) {
        return RecruiterDto.builder()
                .id(recruiter.getId())
                .email(recruiter.getUser().getEmail())
                .companyName(recruiter.getCompanyName())
                .website(recruiter.getWebsite())
                .verified(recruiter.getVerified())
                .build();
    }
}
