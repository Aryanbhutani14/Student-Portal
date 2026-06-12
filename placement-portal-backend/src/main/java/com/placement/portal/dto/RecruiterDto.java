package com.placement.portal.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecruiterDto {
    private Long id;
    private String email;
    private String companyName;
    private String website;
    private Boolean verified;
}
