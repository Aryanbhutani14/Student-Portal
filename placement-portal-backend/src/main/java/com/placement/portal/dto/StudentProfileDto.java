package com.placement.portal.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentProfileDto {
    private String email;
    private String name;
    private String branch;
    private Integer semester;
    private Double cgpa;
    private String skills;
    private String certifications;
    private String projects;
    private String experience;
    private String github;
    private String linkedin;
    private String resumeUrl;
}
