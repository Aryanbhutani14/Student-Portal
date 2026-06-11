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
}
