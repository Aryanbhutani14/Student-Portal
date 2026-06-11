package com.placement.portal.dto;

import lombok.*;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApplicationDto {
    private Long id;
    private Long jobId;
    private String company;
    private String role;
    private String location;
    private String salary;
    private String type;
    private String status;
    private LocalDateTime appliedDate;

    // Student fields for recruiter evaluation
    private String studentName;
    private String studentEmail;
    private String studentBranch;
    private Integer studentSemester;
    private Double studentCgpa;
    private String studentSkills;
    private String studentResumeUrl;
}
