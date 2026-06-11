package com.placement.portal.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "students")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    @JoinColumn(name = "user_id", referencedColumnName = "id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    private String name;

    private String branch;

    private Integer semester;

    private Double cgpa;

    @Column(columnDefinition = "TEXT")
    private String skills;

    private String github;

    private String linkedin;

    @Column(name = "resume_url")
    private String resumeUrl;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "saved_jobs",
        joinColumns = @JoinColumn(name = "student_id"),
        inverseJoinColumns = @JoinColumn(name = "job_id")
    )
    @Builder.Default
    private Set<Job> savedJobs = new HashSet<>();
}
