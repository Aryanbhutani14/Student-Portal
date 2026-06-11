package com.placement.portal.controller;

import com.placement.portal.dto.StudentProfileDto;
import com.placement.portal.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@RestController
@RequestMapping("/student")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    @GetMapping("/profile")
    public ResponseEntity<StudentProfileDto> getProfile(Principal principal) {
        String email = principal.getName();
        return ResponseEntity.ok(studentService.getStudentProfile(email));
    }

    @PutMapping("/profile")
    public ResponseEntity<StudentProfileDto> updateProfile(
            Principal principal,
            @RequestBody StudentProfileDto requestDto
    ) {
        String email = principal.getName();
        return ResponseEntity.ok(studentService.updateStudentProfile(email, requestDto));
    }
}
