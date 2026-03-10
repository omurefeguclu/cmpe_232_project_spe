# Interview-as-a-Service (IaaS) Platform — Project Proposal

## Abstract

This project presents an innovative **Interview-as-a-Service (IaaS)** platform designed to revolutionize recruitment processes by connecting independent Human Resources (HR) professionals with companies seeking talent. The system enables companies to publish job postings, collect applications, and delegate technical or HR interviews to specialized independent interviewers on the platform. A relational database built on **MSSQL** supports the platform's core operations including user management with role-based hierarchy, job posting lifecycle, candidate profile enrichment, application tracking, and interview evaluation workflows. The application targets three primary user groups — **companies**, **candidates**, and **independent interviewers** — each benefiting from a streamlined, fair, and transparent hiring pipeline.

---

## I. Introduction

The traditional recruitment process places a significant operational burden on companies, especially during the interview stage. Small and medium-sized enterprises often lack dedicated HR departments, while larger organizations struggle with scaling their interview capacity for high-volume hiring periods. Meanwhile, experienced HR professionals and domain experts seeking freelance opportunities have limited platforms to offer their interview services independently.

The **Interview-as-a-Service (IaaS)** platform addresses this gap by creating a marketplace that connects companies with independent interviewers. Companies can offload the interview workload to verified, specialized professionals, while candidates receive fair and expert evaluations from domain specialists rather than potentially biased internal reviewers.

Similar platforms exist in the recruitment technology space — services like **HireVue**, **Karat**, and **Interviewing.io** offer various forms of interview outsourcing. However, these platforms typically focus on either automated video assessments or are limited to technical coding interviews. Our platform differentiates itself by:

- Supporting **multiple interview types** (both technical and HR interviews) through a flexible interviewer specialization system (`Department` and `Title` fields).
- Providing a **complete end-to-end workflow** from job posting creation through application management to interview scheduling and scoring.
- Implementing a **rich candidate profiling system** with skills and foreign language proficiency tracking, enabling better interviewer–candidate matching.
- Using an **aggregation-based data model** that treats job applications as first-class entities, allowing multiple interviews to be linked to a single application.

### Use of AI Tools

AI tools (such as ChatGPT and GitHub Copilot) were used during the conceptual design phase to:
- Explore and compare ER modeling approaches, particularly for representing concept hierarchies, weak entities, and aggregations in a relational schema.
- Understand MSSQL-specific constraints such as the **multiple cascade path limitation** and design appropriate workarounds.
- Generate and validate SQL trigger logic for automatic timestamp management across parent–child table hierarchies.

---

## II. Requirements

### Entity and Relationship Requirements

The database schema consists of **9 entities**, **7 relationships**, and **4 complex structures**, exceeding the minimum requirements:

#### Entities (9)
1. **User** — Super-type entity storing common authentication fields (`Email`, `PasswordHash`) for all platform users. Primary keys are auto-incremented (`IDENTITY(1,1)`).
2. **CandidateUser** — Sub-type entity for job candidates with profile fields (`ResumeUrl`, `GitHubProfile`).
3. **CompanyOwnerUser** — Sub-type entity for company representatives with verification data (`VerificationTaxNumber`).
4. **InterviewerUser** — Sub-type entity for independent interviewers with specialization info (`Department`, `Title`).
5. **JobSector** — Independent entity defining industry sectors (Technology, Finance, Healthcare, etc.).
6. **Company** — Entity representing registered companies, linked to a sector and an owner.
7. **JobPosting** — Weak entity for job listings, existentially dependent on a Company.
8. **Skill** — Independent entity for technical and professional skills (Java, SQL, React, etc.).
9. **ForeignLanguage** — Independent entity for foreign languages (English, German, French, etc.).

#### Relationships (7)
1. **ISA (Concept Hierarchy)** — User → CandidateUser, CompanyOwnerUser, InterviewerUser (1:1 each).
2. **Owns** — CompanyOwnerUser to Company (1:N).
3. **BelongsTo** — JobSector to Company (1:N).
4. **Posts** — Company to JobPosting (1:N, weak entity identifying relationship).
5. **HasSkill** — CandidateUser to Skill (M:N association with `ProficiencyLevel` attribute).
6. **Speaks** — CandidateUser to ForeignLanguage (M:N association with `ProficiencyLevel` attribute).
7. **AppliesTo / Evaluates** — CandidateUser to JobPosting (M:N via JobApplication aggregation), then JobApplication aggregation to InterviewerUser (M:N via Interviews).

#### Complex Structures (4)
| Complex Structure | Implementation |
|---|---|
| **Concept Hierarchy (ISA)** | `User` → `CandidateUser`, `CompanyOwnerUser`, `InterviewerUser` via TPT mapping |
| **Weak Entity** | `JobPosting` depends on `Company` for existence (CASCADE delete) |
| **Aggregation** | `JobApplication` boxes the CandidateUser↔JobPosting M:N relationship into an entity-like structure |
| **Aggregation Link** | `Interviews` connects the JobApplication aggregation with `InterviewerUser` |

### Auto-Increment and Timestamp Requirements
- All entity primary keys use `IDENTITY(1,1)` for auto-increment.
- All tables with mutable data include `CreatedAt` (default `GETDATE()`) and `UpdatedAt` fields.
- **SQL Triggers** automatically update `UpdatedAt` on every row modification. Sub-type table updates also propagate to the parent `User` table's `UpdatedAt`.

### Constraints and Real-Life Scenario Rules
- **Uniqueness:** A candidate can apply to the same job posting only once (`UNIQUE(CandidateId, JobPostingId)`).
- **Uniqueness:** A candidate can register each skill or language only once (`UNIQUE(CandidateId, SkillId)`, `UNIQUE(CandidateId, ForeignLanguageId)`).
- **Email Uniqueness:** Each user must have a unique email address.
- **Referential Integrity:** `ON DELETE CASCADE` ensures dependent records are cleaned up when parent records are deleted. Due to MSSQL's multiple cascade path restriction, `Interviews.InterviewerId` does **not** use CASCADE.
- **State Machine Logic:** `ApplicationStatus` follows the lifecycle: *Pending → In Review → Accepted / Rejected*. `Interview.Status` follows: *Scheduled → Completed / Cancelled*.
- **Scoring Bounds:** Interview scores (`Score`) are integer-based, recorded alongside qualitative `Notes` by interviewers.
- **Proficiency Levels:** Skills use a structured scale (*Beginner, Intermediate, Advanced, Expert*); foreign languages follow the CEFR standard (*A1, A2, B1, B2, C1, C2*).

---

## III. Functionality

### Company Management
1. **Register as Company Owner** — A user can register as a company owner with tax number verification.
2. **Create Company Profile** — Company owners can create and manage company profiles linked to a specific job sector.
3. **Publish Job Postings** — Companies can create, update, and delete job postings with title and description.
4. **View Applications** — Companies can view all applications submitted to their job postings and track status changes.
5. **Assign Interviewers** — Companies can delegate interviews for specific applications to platform interviewers.

### Candidate Operations
6. **Register as Candidate** — Users can register as candidates with resume URL and GitHub profile.
7. **Manage Skills** — Candidates can add, update, and remove skills with proficiency levels (Beginner → Expert).
8. **Manage Languages** — Candidates can add, update, and remove foreign language proficiencies (A1 → C2).
9. **Browse and Apply** — Candidates can browse job postings and submit applications (one application per posting).
10. **Track Application Status** — Candidates can view their application statuses across all postings.

### Interviewer Operations
11. **Register as Interviewer** — Users can register as independent interviewers with department and title information.
12. **Conduct Interviews** — Interviewers can view assigned interviews, schedule dates, and update interview statuses.
13. **Score and Evaluate** — Interviewers can record scores and notes for completed interviews.

### Database-Level Functions
14. **Automatic Timestamps** — Triggers auto-update `UpdatedAt` across all modifiable tables.
15. **Cascading Deletes** — Deleting a company cascades to its postings, applications, and interviews.
16. **Duplicate Prevention** — Unique constraints prevent duplicate applications, skills, and language entries per candidate.

---

## IV. Workload Division

| Task | Responsible Student(s) |
|---|---|
| Database Schema Design (ER Diagram & SQL) | *[To be filled]* |
| User Management Module (Registration, Authentication, Role Hierarchy) | *[To be filled]* |
| Company & Job Posting Module (CRUD Operations) | *[To be filled]* |
| Candidate Profile Module (Skills, Languages, Applications) | *[To be filled]* |
| Interview Management Module (Scheduling, Scoring, Status Tracking) | *[To be filled]* |
| Triggers, Constraints & Database Integrity | *[To be filled]* |
| Testing & Documentation | *[To be filled]* |

> **Note:** Please fill in the responsible student names for each task based on your group's agreement.

---

## V. References

1. Microsoft SQL Server Documentation — [https://learn.microsoft.com/en-us/sql/sql-server/](https://learn.microsoft.com/en-us/sql/sql-server/)
2. Entity-Relationship Model — Elmasri, R. & Navathe, S. B., *Fundamentals of Database Systems*, 7th Edition.
3. draw.io (diagrams.net) — [https://app.diagrams.net/](https://app.diagrams.net/)
4. HireVue — AI-driven Video Interview Platform — [https://www.hirevue.com/](https://www.hirevue.com/)
5. Karat — Technical Interview Platform — [https://karat.com/](https://karat.com/)
6. Interviewing.io — Anonymous Technical Interviews — [https://interviewing.io/](https://interviewing.io/)
7. Common European Framework of Reference for Languages (CEFR) — [https://www.coe.int/en/web/common-european-framework-reference-languages](https://www.coe.int/en/web/common-european-framework-reference-languages)
8. ChatGPT (OpenAI) — Used for conceptual design exploration and SQL validation — [https://chat.openai.com/](https://chat.openai.com/)
