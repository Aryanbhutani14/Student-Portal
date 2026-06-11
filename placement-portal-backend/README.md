# BMU Student Placement Portal — Backend

A robust, secure Spring Boot 3.x backend REST API built for the BML Munjal University (BMU) Student Placement Portal. It manages database persistence, handles roles and authorization via JWT security filters, and coordinates email notifications.

---

## 🛠️ Tech Stack & Key Libraries

*   **Spring Boot 3.x**: WebMVC REST controllers and dependency injection container
*   **Spring Data JPA / Hibernate**: Handles object-relational mapping to PostgreSQL
*   **Spring Security**: Encrypts user credentials with BCrypt and acts as a firewall
*   **JSON Web Tokens (jjwt 0.12.6)**: Implements stateless authentication and authorization claims
*   **Spring Mail (JavaMail)**: Handles email dispatching utilizing SMTP servers
*   **Project Lombok**: Auto-generates builders, getters, setters, and logging handles

---

## 📁 Package Layout

```text
placement-portal-backend/src/main/java/com/placement/portal/
├── PlacementPortalBackendApplication.java
├── config/              # Password encoder and CORS filter declarations
├── controller/          # REST Controllers exposing resource mappings (AuthController)
├── dto/                 # Request/Response Data Transfer Objects (LoginRequest, RegisterRequest)
├── entity/              # JPA Database Models (User, Student, Recruiter, Job, etc.)
├── exception/           # Global exception interceptor and REST responses formatting
├── repository/          # Spring Data JPA CRUD interfaces
├── security/            # JWT validation filter, CustomDetailsService, SecurityConfig
├── service/             # Business Logic (AuthService, EmailService)
└── util/                # Helper tools
```

---

## 🗄️ Database Schema (PostgreSQL)

The tables are configured inside `src/main/resources/schema.sql` and mapped through JPA Entity definitions:

### 1. `users`
*   `id` (BIGINT, PK, SERIAL)
*   `email` (VARCHAR, UNIQUE, NOT NULL): Strictly constrained to `@bmu.edu.in` addresses
*   `password` (VARCHAR, NOT NULL): BCrypt hashed string
*   `role` (VARCHAR, NOT NULL): Evaluates role type (`'STUDENT'`, `'RECRUITER'`, `'ADMIN'`)
*   `is_verified` (BOOLEAN): Defaults to `false` until email is validated via OTP
*   `otp` (VARCHAR(6)): Temporary generated authentication code
*   `otp_expiry` (TIMESTAMP): 5-minute expiration time limit
*   `created_at` (TIMESTAMP): Record initialization date

### 2. `students`
*   `id` (BIGINT, PK, SERIAL)
*   `user_id` (BIGINT, UNIQUE, FK -> `users(id)` ON DELETE CASCADE)
*   `name` (VARCHAR, NOT NULL)
*   `branch` (VARCHAR), `semester` (INT), `cgpa` (NUMERIC(4,2))
*   `skills` (TEXT), `github` (VARCHAR), `linkedin` (VARCHAR)
*   `resume_url` (VARCHAR)

### 3. `recruiters`
*   `id` (BIGINT, PK, SERIAL)
*   `user_id` (BIGINT, UNIQUE, FK -> `users(id)` ON DELETE CASCADE)
*   `company_name` (VARCHAR, NOT NULL)
*   `website` (VARCHAR)
*   `verified` (BOOLEAN): Admin approval status

### 4. `jobs`
*   `id` (BIGINT, PK, SERIAL)
*   `title` (VARCHAR), `description` (TEXT), `location` (VARCHAR)
*   `salary` (VARCHAR), `skills_required` (TEXT), `deadline` (TIMESTAMP), `job_type` (VARCHAR)
*   `recruiter_id` (BIGINT, FK -> `recruiters(id)` ON DELETE CASCADE)

### 5. `applications`
*   `id` (BIGINT, PK, SERIAL)
*   `student_id` (BIGINT, FK -> `students(id)` ON DELETE CASCADE)
*   `job_id` (BIGINT, FK -> `jobs(id)` ON DELETE CASCADE)
*   `status` (VARCHAR): Status tracks: `APPLIED`, `UNDER_REVIEW`, `SHORTLISTED`, `INTERVIEW`, `SELECTED`, `REJECTED`
*   Constraint: Unique composite key on (`student_id`, `job_id`)

### 6. `resume_scores`
*   `id` (BIGINT, PK, SERIAL)
*   `student_id` (BIGINT, UNIQUE, FK -> `students(id)` ON DELETE CASCADE)
*   `score` (INT), `feedback` (TEXT)

---

## 🔒 Stateless Security & JWT

*   The filter `JwtAuthenticationFilter` intercepts HTTP headers searching for `Authorization: Bearer <token>`.
*   Extracted claims verify user email details and role grants (`ROLE_STUDENT` / `ROLE_RECRUITER` / `ROLE_ADMIN`).
*   Configured defaults fallback to:
    *   JWT secret key: `404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970`
    *   Expiration limit: `86400000` (24 hours)

---

## 📧 Email Service with Console-Logging Fallback

`EmailService` uses standard Spring Boot `JavaMailSender` bindings to email OTP codes to users.
If mail servers are unavailable or SMTP properties are not set locally, standard JavaMail dispatch errors are caught automatically. The system then redirects the OTP string to the Spring Boot console output instead:
```text
============== OFFLINE DEV FALLBACK ==============
TO: username@bmu.edu.in
OTP: 123456
==================================================
```
This enables developers to test registration and login pipelines without setting up email configurations.

---

## ⚙️ API Reference

All requests must use `Content-Type: application/json`.

### 1. Register Account
*   **URL**: `/auth/register`
*   **Method**: `POST`
*   **Request Body**:
    ```json
    {
      "email": "student.name.24cse@bmu.edu.in",
      "password": "securepassword",
      "role": "STUDENT",
      "name": "Student Name"
    }
    ```
*   **Response**: `{"token": "JWT_STRING"}` (Status `is_verified` starts as `false`)

### 2. Login
*   **URL**: `/auth/login`
*   **Method**: `POST`
*   **Request Body**:
    ```json
    {
      "email": "student.name.24cse@bmu.edu.in",
      "password": "securepassword"
    }
    ```
*   **Response**: `{"token": "JWT_STRING"}`
*   **Exceptions**: Throws `400 Bad Request` if user exists but has not completed the OTP verification.

### 3. Send OTP (Resend)
*   **URL**: `/auth/send-otp`
*   **Method**: `POST`
*   **Request Body**:
    ```json
    {
      "email": "student.name.24cse@bmu.edu.in"
    }
    ```
*   **Response**: `{"message": "OTP sent successfully"}`

### 4. Verify OTP
*   **URL**: `/auth/verify-otp`
*   **Method**: `POST`
*   **Request Body**:
    ```json
    {
      "email": "student.name.24cse@bmu.edu.in",
      "otp": "123456"
    }
    ```
*   **Response**: `{"message": "Email verified successfully"}`

---

## 🚀 Build & Run Configurations

### Maven Commands
Navigate to the directory and run these commands:

*   **Clean Compile**:
    ```bash
    mvn clean compile
    ```
*   **Start Local Dev Server**:
    ```bash
    mvn spring-boot:run
    ```
*   **Run Automated Tests**:
    ```bash
    mvn test
    ```
