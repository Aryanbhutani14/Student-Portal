package com.placement.portal.config;

import com.placement.portal.entity.*;
import com.placement.portal.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final RecruiterRepository recruiterRepository;
    private final StudentRepository studentRepository;
    private final JobRepository jobRepository;
    private final PasswordEncoder passwordEncoder;
    private final ApplicationRepository applicationRepository;
    private final AnnouncementRepository announcementRepository;

    @Override
    public void run(String... args) throws Exception {
        log.info("Cleaning database to perform clean seed of demo data...");
        try {
            applicationRepository.deleteAll();
            announcementRepository.deleteAll();
            jobRepository.deleteAll();
            recruiterRepository.deleteAll();
            studentRepository.deleteAll();
            userRepository.deleteAll();
        } catch (Exception e) {
            log.warn("Could not clean database: " + e.getMessage());
        }

        log.info("Seeding fresh dummy data for demonstration...");

        // 1. Create Recruiter: Apple
        User userApple = User.builder()
                .email("recruiter.apple@apple.com")
                .password(passwordEncoder.encode("password"))
                .role(Role.RECRUITER)
                .isVerified(true)
                .build();

        Recruiter recruiterApple = Recruiter.builder()
                .user(userApple)
                .companyName("Apple Inc.")
                .website("https://apple.com")
                .verified(true)
                .build();
        recruiterApple = recruiterRepository.save(recruiterApple);

        // 2. Create Recruiter: Google
        User userGoogle = User.builder()
                .email("recruiter.google@google.com")
                .password(passwordEncoder.encode("password"))
                .role(Role.RECRUITER)
                .isVerified(true)
                .build();

        Recruiter recruiterGoogle = Recruiter.builder()
                .user(userGoogle)
                .companyName("Google")
                .website("https://google.com")
                .verified(true)
                .build();
        recruiterGoogle = recruiterRepository.save(recruiterGoogle);

        // 3. Create Student
        User userStudent = User.builder()
                .email("student.test@bmu.edu.in")
                .password(passwordEncoder.encode("password"))
                .role(Role.STUDENT)
                .isVerified(true)
                .build();

        Student student = Student.builder()
                .user(userStudent)
                .name("Aryan Bhutani")
                .branch("Computer Science & Engineering")
                .semester(6)
                .cgpa(9.2)
                .skills("java, flutter, spring, sql")
                .github("https://github.com/aryanbhutani")
                .linkedin("https://linkedin.com/in/aryanbhutani")
                .build();
        studentRepository.save(student);

        // 3b. Create Second Student
        User userStudent2 = User.builder()
                .email("student.neha@bmu.edu.in")
                .password(passwordEncoder.encode("password"))
                .role(Role.STUDENT)
                .isVerified(true)
                .build();

        Student student2 = Student.builder()
                .user(userStudent2)
                .name("Neha Sharma")
                .branch("Electronics & Communication Engineering")
                .semester(6)
                .cgpa(8.7)
                .skills("python, embedded systems, iot")
                .github("https://github.com/nehasharma")
                .linkedin("https://linkedin.com/in/nehasharma")
                .build();
        studentRepository.save(student2);

        // 4. Create Admin
        User userAdmin = User.builder()
                .email("admin@bmu.edu.in")
                .password(passwordEncoder.encode("password"))
                .role(Role.ADMIN)
                .isVerified(true)
                .build();
        userRepository.save(userAdmin);

        // 4. Seed Jobs for Apple
        Job jobApple1 = Job.builder()
                .title("Software Engineering Intern")
                .description("Join the CoreOS team to build low-level systems, kernel extensions, and optimize memory management algorithms.")
                .location("Hyderabad")
                .salary("80,000 / month")
                .skillsRequired("c, c++, operating systems, data structures")
                .deadline(LocalDateTime.now().plusDays(30))
                .jobType("Internship")
                .recruiter(recruiterApple)
                .build();

        Job jobApple2 = Job.builder()
                .title("Frontend Developer")
                .description("Work on responsive and elegant user interfaces for Apple Music and Apple TV web players using modern framework engines.")
                .location("Delhi")
                .salary("18 LPA")
                .skillsRequired("javascript, css, html, flutter")
                .deadline(LocalDateTime.now().plusDays(15))
                .jobType("Full-Time")
                .recruiter(recruiterApple)
                .build();

        jobRepository.saveAll(List.of(jobApple1, jobApple2));

        // 5. Seed Jobs for Google
        Job jobGoogle1 = Job.builder()
                .title("Associate Product Manager")
                .description("Lead product features, design user flows, and coordinate with engineers to deliver search engine query tools globally.")
                .location("Gurugram")
                .salary("22 LPA")
                .skillsRequired("product design, communication, analytical tools, java")
                .deadline(LocalDateTime.now().plusDays(20))
                .jobType("Full-Time")
                .recruiter(recruiterGoogle)
                .build();

        Job jobGoogle2 = Job.builder()
                .title("Cloud Specialist Bootcamp")
                .description("Intensive training bootcamp focused on Google Cloud infrastructure architectures, container deployment, and Kubernetes networks.")
                .location("Remote")
                .salary("Stipend provided")
                .skillsRequired("cloud, networks, linux, docker")
                .deadline(LocalDateTime.now().plusDays(45))
                .jobType("Training")
                .recruiter(recruiterGoogle)
                .build();

        Job jobGoogle3 = Job.builder()
                .title("BMU Hackathon 2026 Challenge")
                .description("Solve complex system-level problems in real-time. Winners receive cash prizes, technical devices, and direct interview calls from Google.")
                .location("BMU Campus")
                .salary("Prizes up to 5 Lakhs")
                .skillsRequired("java, python, c++, algorithm, problem solving")
                .deadline(LocalDateTime.now().plusDays(5))
                .jobType("Hackathon")
                .recruiter(recruiterGoogle)
                .build();

        jobRepository.saveAll(List.of(jobGoogle1, jobGoogle2, jobGoogle3));

        // 6. Seed applications for analytics verification
        Application app1 = Application.builder()
                .student(student)
                .job(jobGoogle1)
                .status(ApplicationStatus.SELECTED)
                .build();

        Application app2 = Application.builder()
                .student(student2)
                .job(jobApple2)
                .status(ApplicationStatus.UNDER_REVIEW)
                .build();

        applicationRepository.saveAll(List.of(app1, app2));

        log.info("Successfully seeded dummy recruiter, student, and job opportunity data!");
    }
}
