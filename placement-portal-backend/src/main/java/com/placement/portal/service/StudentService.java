package com.placement.portal.service;

import com.placement.portal.dto.StudentProfileDto;
import com.placement.portal.entity.Student;
import com.placement.portal.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class StudentService {

    private final StudentRepository studentRepository;

    @Transactional(readOnly = true)
    public StudentProfileDto getStudentProfile(String email) {
        Student student = studentRepository.findByUserEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Student not found for user: " + email));

        return mapToDto(student);
    }

    @Transactional
    public StudentProfileDto updateStudentProfile(String email, StudentProfileDto dto) {
        Student student = studentRepository.findByUserEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Student not found for user: " + email));

        student.setName(dto.getName());
        student.setBranch(dto.getBranch());
        student.setSemester(dto.getSemester());
        student.setCgpa(dto.getCgpa());
        student.setSkills(dto.getSkills());
        student.setCertifications(dto.getCertifications());
        student.setProjects(dto.getProjects());
        student.setExperience(dto.getExperience());
        student.setGithub(dto.getGithub());
        student.setLinkedin(dto.getLinkedin());
        student.setResumeUrl(dto.getResumeUrl());

        Student updatedStudent = studentRepository.save(student);
        return mapToDto(updatedStudent);
    }

    private StudentProfileDto mapToDto(Student student) {
        return StudentProfileDto.builder()
                .email(student.getUser().getEmail())
                .name(student.getName())
                .branch(student.getBranch())
                .semester(student.getSemester())
                .cgpa(student.getCgpa())
                .skills(student.getSkills())
                .certifications(student.getCertifications())
                .projects(student.getProjects())
                .experience(student.getExperience())
                .github(student.getGithub())
                .linkedin(student.getLinkedin())
                .resumeUrl(student.getResumeUrl())
                .build();
    }
}
