package com.placement.portal.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    @Pattern(regexp = "^[A-Za-z0-9._%+-]+@bmu\\.edu\\.in$", message = "Email must belong to the @bmu.edu.in domain")
    private String email;

    @NotBlank(message = "Password is required")
    private String password;
}
