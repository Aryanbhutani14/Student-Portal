package com.placement.portal.dto;

import lombok.*;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnalyticsDto {
    private double placementPercentage;
    private String highestPackage;
    private Map<String, Long> branchWisePlacements;
    private long totalStudents;
    private long totalRecruiters;
    private long totalJobs;
}
