package com.placement.portal.dto;

import lombok.Data;

@Data
public class StatusUpdateRequest {
    private Long applicationId;
    private String status;
}
