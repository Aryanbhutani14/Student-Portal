-- Drop tables if they exist
DROP TABLE IF EXISTS saved_jobs CASCADE;
DROP TABLE IF EXISTS resume_scores CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS recruiters CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Users Table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('STUDENT', 'RECRUITER', 'ADMIN')),
    is_verified BOOLEAN DEFAULT FALSE,
    otp VARCHAR(6),
    otp_expiry TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Students Table
CREATE TABLE students (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    branch VARCHAR(100),
    semester INT,
    cgpa NUMERIC(4, 2),
    skills TEXT,
    github VARCHAR(255),
    linkedin VARCHAR(255),
    resume_url VARCHAR(255)
);

-- 3. Recruiters Table
CREATE TABLE recruiters (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_name VARCHAR(255) NOT NULL,
    website VARCHAR(255),
    verified BOOLEAN DEFAULT FALSE
);

-- 4. Jobs Table
CREATE TABLE jobs (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255),
    salary VARCHAR(100),
    skills_required TEXT,
    deadline TIMESTAMP,
    job_type VARCHAR(50),
    recruiter_id BIGINT NOT NULL REFERENCES recruiters(id) ON DELETE CASCADE
);

-- 5. Applications Table
CREATE TABLE applications (
    id BIGSERIAL PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL DEFAULT 'APPLIED' CHECK (status IN ('APPLIED', 'UNDER_REVIEW', 'SHORTLISTED', 'INTERVIEW', 'SELECTED', 'REJECTED')),
    applied_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_student_job UNIQUE (student_id, job_id)
);

-- 6. Resume Scores Table
CREATE TABLE resume_scores (
    id BIGSERIAL PRIMARY KEY,
    student_id BIGINT UNIQUE NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    score INT NOT NULL,
    feedback TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Saved Jobs Table
CREATE TABLE saved_jobs (
    student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    job_id BIGINT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    PRIMARY KEY (student_id, job_id)
);

-- 8. Announcements Table
CREATE TABLE announcements (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    created_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
