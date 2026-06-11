package com.placement.portal.dto;

import lombok.*;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobDto {
    private Long id;
    private String company;
    private String role;
    private String description;
    private String location;
    private String salary;
    private String skillsRequired;
    private LocalDateTime deadline;
    private String type;
    private Long recruiterId;
}
