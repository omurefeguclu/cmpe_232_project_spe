-- ==========================================
-- SEED DATA FOR RecruitmentDB
-- Run this AFTER database.sql has been executed.
--
-- Insertion order (FK dependency chain):
--   JobSector, Skill, ForeignLanguage
--   → User (30 rows: 1-10 Candidates, 11-20 Owners, 21-30 Interviewers)
--   → CandidateUser, CompanyOwnerUser, InterviewerUser
--   → Company → JobPosting
--   → CandidateSkills, CandidateForeignLanguages
--   → JobApplication → Interviews
-- ==========================================

USE RecruitmentDB;
GO

-- ==========================================
-- 1. JobSector  (10 rows — IDENTITY IDs: 1-10)
-- ==========================================
INSERT INTO JobSector (SectorName) VALUES
('Technology'),
('Finance'),
('Healthcare'),
('Education'),
('Manufacturing'),
('Retail'),
('Media & Entertainment'),
('Energy'),
('Construction'),
('Logistics');
GO

-- ==========================================
-- 2. Skill  (10 rows — IDENTITY IDs: 1-10)
-- ==========================================
INSERT INTO Skill (SkillName) VALUES
('Java'),
('SQL'),
('React'),
('Python'),
('Project Management'),
('.NET / C#'),
('Machine Learning'),
('Docker & Kubernetes'),
('Communication'),
('Data Analysis');
GO

-- ==========================================
-- 3. ForeignLanguage  (10 rows — IDENTITY IDs: 1-10)
-- ==========================================
INSERT INTO ForeignLanguage (LanguageName) VALUES
('English'),
('German'),
('French'),
('Spanish'),
('Japanese'),
('Chinese'),
('Italian'),
('Russian'),
('Arabic'),
('Portuguese');
GO

-- ==========================================
-- 4. User  (30 rows — IDENTITY IDs: 1-30)
--    1-10  → will become CandidateUser
--    11-20 → will become CompanyOwnerUser
--    21-30 → will become InterviewerUser
-- ==========================================
INSERT INTO [User] (Email, PasswordHash) VALUES
('alice.johnson@mail.com',     'hash_cand_01'),  -- Id 1
('bob.smith@mail.com',         'hash_cand_02'),  -- Id 2
('carol.lee@mail.com',         'hash_cand_03'),  -- Id 3
('david.park@mail.com',        'hash_cand_04'),  -- Id 4
('emma.davis@mail.com',        'hash_cand_05'),  -- Id 5
('frank.white@mail.com',       'hash_cand_06'),  -- Id 6
('grace.kim@mail.com',         'hash_cand_07'),  -- Id 7
('henry.brown@mail.com',       'hash_cand_08'),  -- Id 8
('iris.taylor@mail.com',       'hash_cand_09'),  -- Id 9
('jake.wilson@mail.com',       'hash_cand_10'),  -- Id 10
('carlos.ruiz@company.com',    'hash_own_01'),   -- Id 11
('diana.chen@company.com',     'hash_own_02'),   -- Id 12
('evan.thomas@company.com',    'hash_own_03'),   -- Id 13
('fiona.scott@company.com',    'hash_own_04'),   -- Id 14
('george.hall@company.com',    'hash_own_05'),   -- Id 15
('helen.martin@company.com',   'hash_own_06'),   -- Id 16
('ivan.garcia@company.com',    'hash_own_07'),   -- Id 17
('julia.adams@company.com',    'hash_own_08'),   -- Id 18
('kevin.clark@company.com',    'hash_own_09'),   -- Id 19
('laura.lewis@company.com',    'hash_own_10'),   -- Id 20
('mike.turner@hr.com',         'hash_int_01'),   -- Id 21
('nina.walker@hr.com',         'hash_int_02'),   -- Id 22
('oscar.hill@hr.com',          'hash_int_03'),   -- Id 23
('paula.young@hr.com',         'hash_int_04'),   -- Id 24
('quinn.baker@hr.com',         'hash_int_05'),   -- Id 25
('rachel.green@hr.com',        'hash_int_06'),   -- Id 26
('sam.porter@hr.com',          'hash_int_07'),   -- Id 27
('tina.foster@hr.com',         'hash_int_08'),   -- Id 28
('umar.price@hr.com',          'hash_int_09'),   -- Id 29
('vera.cox@hr.com',            'hash_int_10');   -- Id 30
GO

-- ==========================================
-- 5. CandidateUser  (10 rows — UserId: 1-10)
-- ==========================================
INSERT INTO CandidateUser (UserId, ResumeUrl, GitHubProfile) VALUES
(1,  'https://resume.io/alice-johnson',  'https://github.com/alicejohnson'),
(2,  'https://resume.io/bob-smith',      'https://github.com/bobsmith'),
(3,  'https://resume.io/carol-lee',      NULL),
(4,  'https://resume.io/david-park',     'https://github.com/davidpark'),
(5,  NULL,                               'https://github.com/emmadavis'),
(6,  'https://resume.io/frank-white',    NULL),
(7,  'https://resume.io/grace-kim',      'https://github.com/gracekim'),
(8,  NULL,                               'https://github.com/henrybrown'),
(9,  'https://resume.io/iris-taylor',    'https://github.com/iristaylor'),
(10, 'https://resume.io/jake-wilson',    NULL);
GO

-- ==========================================
-- 6. CompanyOwnerUser  (10 rows — UserId: 11-20)
-- ==========================================
INSERT INTO CompanyOwnerUser (UserId, VerificationTaxNumber) VALUES
(11, 'TX-2024-001'),
(12, 'TX-2024-002'),
(13, 'TX-2024-003'),
(14, 'TX-2024-004'),
(15, 'TX-2024-005'),
(16, 'TX-2024-006'),
(17, 'TX-2024-007'),
(18, 'TX-2024-008'),
(19, 'TX-2024-009'),
(20, 'TX-2024-010');
GO

-- ==========================================
-- 7. InterviewerUser  (10 rows — UserId: 21-30)
-- ==========================================
INSERT INTO InterviewerUser (UserId, Department, Title) VALUES
(21, 'Engineering',      'Senior Software Engineer'),
(22, 'Human Resources',  'HR Manager'),
(23, 'Data Science',     'Data Scientist'),
(24, 'Product',          'Product Manager'),
(25, 'Engineering',      'Backend Developer'),
(26, 'Engineering',      'Frontend Developer'),
(27, 'DevOps',           'DevOps Engineer'),
(28, 'Mobile',           'Mobile Developer'),
(29, 'Quality',          'QA Lead'),
(30, 'Security',         'Security Engineer');
GO

-- ==========================================
-- 8. Company  (10 rows — IDENTITY IDs: 1-10)
--    CompanyOwnerId → CompanyOwnerUser.UserId (11-20)
--    JobSectorId    → JobSector.Id            (1-10)
-- ==========================================
INSERT INTO Company (CompanyOwnerId, JobSectorId, CompanyName) VALUES
(11, 1,  'TechCorp Inc.'),
(12, 2,  'FinanceHub Ltd.'),
(13, 3,  'MediCare Solutions'),
(14, 4,  'EduLearn Platform'),
(15, 5,  'ManufactoPro'),
(16, 6,  'RetailMax'),
(17, 7,  'MediaVerse'),
(18, 8,  'EnergyWorks'),
(19, 9,  'Buildex Construction'),
(20, 10, 'LogiFlow Logistics');
GO

-- ==========================================
-- 9. JobPosting  (10 rows — Weak Entity, IDENTITY IDs: 1-10)
--    CompanyId → Company.Id (1-10)
-- ==========================================
INSERT INTO JobPosting (CompanyId, Title, Description) VALUES
(1,  'Backend Software Engineer',
     'We are looking for a skilled backend developer with Java or .NET experience to join our core platform team.'),
(2,  'Financial Data Analyst',
     'Seeking a detail-oriented analyst to support financial reporting and business intelligence operations.'),
(3,  'Healthcare Software Consultant',
     'Build and maintain healthcare information systems that serve thousands of patients daily.'),
(4,  'E-Learning Content Developer',
     'Design and develop interactive online learning modules for our global education platform.'),
(5,  'CNC Machine Operator',
     'Operate and maintain CNC machines in a modern manufacturing environment.'),
(6,  'Retail Store Manager',
     'Lead daily store operations, coach your team, and deliver exceptional customer experience.'),
(7,  'Video Content Producer',
     'Produce and edit high-quality video content across our digital media channels.'),
(8,  'Renewable Energy Engineer',
     'Design and deploy next-generation solar and wind energy solutions.'),
(9,  'Civil Site Engineer',
     'Oversee construction projects ensuring compliance with safety standards and timelines.'),
(10, 'Logistics Coordinator',
     'Coordinate shipments, manage vendor relationships, and optimize supply chain operations.');
GO

-- ==========================================
-- 10. CandidateSkills  (10 rows — IDENTITY IDs: 1-10)
--     UNIQUE(CandidateId, SkillId) — diagonal mapping avoids duplicates
--     CandidateId → CandidateUser.UserId (1-10)
--     SkillId     → Skill.Id            (1-10)
-- ==========================================
INSERT INTO CandidateSkills (CandidateId, SkillId, ProficiencyLevel) VALUES
(1,  1,  'Expert'),
(2,  2,  'Advanced'),
(3,  3,  'Intermediate'),
(4,  4,  'Expert'),
(5,  5,  'Advanced'),
(6,  6,  'Beginner'),
(7,  7,  'Intermediate'),
(8,  8,  'Advanced'),
(9,  9,  'Expert'),
(10, 10, 'Beginner');
GO

-- ==========================================
-- 11. CandidateForeignLanguages  (10 rows — IDENTITY IDs: 1-10)
--     UNIQUE(CandidateId, ForeignLanguageId) — diagonal mapping avoids duplicates
--     CandidateId      → CandidateUser.UserId   (1-10)
--     ForeignLanguageId → ForeignLanguage.Id    (1-10)
-- ==========================================
INSERT INTO CandidateForeignLanguages (CandidateId, ForeignLanguageId, ProficiencyLevel) VALUES
(1,  1,  'C2'),
(2,  2,  'B2'),
(3,  3,  'B1'),
(4,  4,  'C1'),
(5,  5,  'A2'),
(6,  6,  'B1'),
(7,  7,  'C1'),
(8,  8,  'A1'),
(9,  9,  'B2'),
(10, 10, 'C2');
GO

-- ==========================================
-- 12. JobApplication  (10 rows — IDENTITY IDs: 1-10)
--     UNIQUE(CandidateId, JobPostingId) — diagonal mapping avoids duplicates
--     CandidateId  → CandidateUser.UserId (1-10)
--     JobPostingId → JobPosting.Id        (1-10)
--     FK_JobApplication_JobPosting is ON DELETE NO ACTION;
--     cascade is handled by trigger trg_JobPosting_CascadeDeleteApplications
-- ==========================================
INSERT INTO JobApplication (CandidateId, JobPostingId, ApplicationStatus) VALUES
(1,  1,  'Pending'),
(2,  2,  'Pending'),
(3,  3,  'Pending'),
(4,  4,  'In Review'),
(5,  5,  'In Review'),
(6,  6,  'In Review'),
(7,  7,  'Accepted'),
(8,  8,  'Accepted'),
(9,  9,  'Rejected'),
(10, 10, 'Rejected');
GO

-- ==========================================
-- 13. Interviews  (10 rows — IDENTITY IDs: 1-10)
--     ApplicationId → JobApplication.Id        (1-10)
--     InterviewerId → InterviewerUser.UserId   (21-30)
--     FK_Interviews_Interviewer is ON DELETE NO ACTION (no cascade by design)
--     Completed interviews have Score + Notes; Scheduled/Cancelled do not.
-- ==========================================
INSERT INTO Interviews (ApplicationId, InterviewerId, ScheduledDate, Status, Score, Notes) VALUES
(1,  21, '2026-04-01 10:00:00', 'Scheduled', NULL, NULL),
(2,  22, '2026-04-03 11:00:00', 'Scheduled', NULL, NULL),
(3,  23, '2026-04-07 09:30:00', 'Scheduled', NULL, NULL),
(4,  24, '2026-04-10 14:00:00', 'Scheduled', NULL, NULL),
(5,  25, '2026-03-10 10:00:00', 'Completed', 85,   'Strong technical skills, communicates well.'),
(6,  26, '2026-03-12 11:00:00', 'Completed', 72,   'Solid experience but some gaps in system design.'),
(7,  27, '2026-03-15 13:00:00', 'Completed', 91,   'Excellent candidate, highly recommended for hire.'),
(8,  28, '2026-03-18 15:00:00', 'Completed', 60,   'Average performance; needs improvement in algorithms.'),
(9,  29, '2026-03-20 09:00:00', 'Cancelled', NULL, 'Candidate did not attend the scheduled interview.'),
(10, 30, '2026-03-22 10:00:00', 'Cancelled', NULL, 'Rescheduling requested by the interviewer.');
GO
