package com.placement.portal.service;

import com.placement.portal.dto.AuthResponse;
import com.placement.portal.dto.LoginRequest;
import com.placement.portal.dto.RegisterRequest;
import com.placement.portal.entity.Role;
import com.placement.portal.entity.Student;
import com.placement.portal.entity.Recruiter;
import com.placement.portal.entity.User;
import com.placement.portal.repository.RecruiterRepository;
import com.placement.portal.repository.StudentRepository;
import com.placement.portal.repository.UserRepository;
import com.placement.portal.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final RecruiterRepository recruiterRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final EmailService emailService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if ((request.getRole() == Role.STUDENT || request.getRole() == Role.ADMIN) &&
                !request.getEmail().endsWith("@bmu.edu.in")) {
            throw new IllegalArgumentException("Email must belong to the @bmu.edu.in domain");
        }

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already exists");
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .isVerified(true)
                .build();

        user = userRepository.save(user);

        if (request.getRole() == Role.STUDENT) {
            Student student = Student.builder()
                    .user(user)
                    .name(request.getName())
                    .build();
            studentRepository.save(student);
        } else if (request.getRole() == Role.RECRUITER) {
            Recruiter recruiter = Recruiter.builder()
                    .user(user)
                    .companyName(request.getName())
                    .verified(false)
                    .build();
            recruiterRepository.save(recruiter);
        }

        UserDetails userDetails = new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPassword(),
                List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
        );

        Map<String, Object> claims = new HashMap<>();
        claims.put("role", user.getRole().name());

        String jwtToken = jwtService.generateToken(claims, userDetails);
        return AuthResponse.builder()
                .token(jwtToken)
                .role(user.getRole().name())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if ((user.getRole() == Role.STUDENT || user.getRole() == Role.ADMIN) &&
                !user.getEmail().endsWith("@bmu.edu.in")) {
            throw new IllegalArgumentException("Email must belong to the @bmu.edu.in domain");
        }

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                         request.getEmail(),
                        request.getPassword()
                )
        );

        UserDetails userDetails = new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPassword(),
                List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
        );

        Map<String, Object> claims = new HashMap<>();
        claims.put("role", user.getRole().name());

        String jwtToken = jwtService.generateToken(claims, userDetails);
        return AuthResponse.builder()
                .token(jwtToken)
                .role(user.getRole().name())
                .build();
    }

    @Transactional
    public void sendOtp(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));
        if ((user.getRole() == Role.STUDENT || user.getRole() == Role.ADMIN) &&
                !email.endsWith("@bmu.edu.in")) {
            throw new IllegalArgumentException("Email must belong to the @bmu.edu.in domain");
        }

        String otp = String.format("%06d", (int)(Math.random() * 900000 + 100000));
        user.setOtp(otp);
        user.setOtpExpiry(LocalDateTime.now().plusMinutes(5));
        userRepository.save(user);

        emailService.sendOtp(email, otp);
    }

    @Transactional
    public void verifyOtp(String email, String otp) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found with email: " + email));

        if (user.getOtp() == null || !user.getOtp().equals(otp)) {
            throw new IllegalArgumentException("Invalid OTP code");
        }

        if (user.getOtpExpiry() == null || LocalDateTime.now().isAfter(user.getOtpExpiry())) {
            throw new IllegalArgumentException("OTP code has expired");
        }

        user.setIsVerified(true);
        user.setOtp(null);
        user.setOtpExpiry(null);
        userRepository.save(user);
    }
}
