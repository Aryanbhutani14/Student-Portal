package com.placement.portal.controller;

import com.placement.portal.dto.AuthResponse;
import com.placement.portal.dto.LoginRequest;
import com.placement.portal.dto.RegisterRequest;
import com.placement.portal.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(
            @Valid @RequestBody RegisterRequest request
    ) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(
            @Valid @RequestBody LoginRequest request
    ) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(
            @RequestBody Map<String, String> request
    ) {
        String email = request.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email is required"));
        }
        // Placeholder behavior: return success message
        return ResponseEntity.ok(Map.of("message", "Password reset instructions have been sent to " + email));
    }

    @PostMapping("/send-otp")
    public ResponseEntity<Map<String, String>> sendOtp(
            @RequestBody Map<String, String> request
    ) {
        String email = request.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email is required"));
        }
        authService.sendOtp(email);
        return ResponseEntity.ok(Map.of("message", "OTP sent successfully"));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<Map<String, String>> verifyOtp(
            @RequestBody Map<String, String> request
    ) {
        String email = request.get("email");
        String otp = request.get("otp");
        if (email == null || email.isBlank() || otp == null || otp.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email and OTP are required"));
        }
        authService.verifyOtp(email, otp);
        return ResponseEntity.ok(Map.of("message", "Email verified successfully"));
    }
}
