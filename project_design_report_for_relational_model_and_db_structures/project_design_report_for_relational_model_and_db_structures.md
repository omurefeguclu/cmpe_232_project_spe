# Project Design Report — Relational Model and Database Structures

**Project:** Interview-as-a-Service (IaaS) Platform
**Database:** RecruitmentDB (MSSQL)

---

## I. Introduction

This design report delves into the core concepts of the Relational Model and the database structures that form the foundation of the RecruitmentDB system for the Interview-as-a-Service (IaaS) platform. The primary goal of the application is to seamlessly connect companies, job-seeking candidates, and independent interviewers.

The database design adopts a structured relational approach using Table-Per-Type (TPT) inheritance mapping for user role management, separating common identity fields into a super-type `[User]` table from role-specific attributes held in sub-type tables, thereby reducing redundancy. It also implements advanced referential integrity mechanisms while accommodating complex relationships including aggregations and many-to-many associations in line with relational principles. Where MSSQL's multiple cascade path restriction prevents the use of declarative `ON DELETE CASCADE`, manual cascade triggers are employed as a controlled workaround.

---

## II. Relational Model

### a. Definition

The relational model of this project relies on a centralized `[User]` schema that acts as a super-type for all user identities within the platform. Sub-types include `CandidateUser`, `CompanyOwnerUser`, and `InterviewerUser`, each sharing the same primary key as the `[User]` row they extend (TPT pattern). Real-world entities such as `Company`, `JobPosting`, `Skill`, and `ForeignLanguage` are explicitly modeled as independent strong entities.

Complex behaviors derived from Many-to-Many interactions — such as candidates applying to job postings and interviewers evaluating applications — are mapped to dedicated junction/aggregation tables (`JobApplication`, `Interviews`) that also carry state information (e.g., `ApplicationStatus`, interview `Status` and `Score`). High consistency is maintained by strictly enforcing Primary Keys, Foreign Keys, Unique constraints, Check constraints, and by leveraging AFTER UPDATE triggers for audit trail management and AFTER DELETE triggers to manually handle cascades that MSSQL's engine cannot resolve due to multiple cascade path limitations.

### b. Database Schema

The schema contains **13 relational tables** mapping the conceptual Entity-Relationship (ER) model:

- **[User]**: Stores universal authentication credentials (email, password hash) shared across all user roles.
- **CandidateUser**: Extends `[User]` with candidate-specific profile details (resume URL, GitHub profile).
- **CompanyOwnerUser**: Extends `[User]` with a company owner's tax verification number.
- **InterviewerUser**: Extends `[User]` with professional attributes (department, title).
- **JobSector**: A reference catalog categorizing companies by industry sector.
- **Company**: Represents organizations registered on the platform, each belonging to one owner and one sector.
- **JobPosting**: Represents job advertisements published by a company. Modeled as a **dependent entity** — it cannot exist without its parent `Company` (enforced via `ON DELETE CASCADE` on the FK). Note: Although sometimes described informally as a "weak entity" due to its existential dependency, `JobPosting` has its own surrogate `IDENTITY` primary key and therefore does not qualify as a classic weak entity in strict ER terminology (a true weak entity uses a partial key derived from its owner).
- **Skill**: A reference catalog of technical and professional skills (e.g., Java, SQL, React).
- **CandidateSkills**: M:N association table resolving the relationship between candidates and their skills, with a proficiency level attribute.
- **ForeignLanguage**: A reference catalog of spoken languages.
- **CandidateForeignLanguages**: M:N association table resolving candidate language proficiencies.
- **JobApplication**: Aggregation table representing a candidate applying to a specific job posting. Also serves as the anchor entity to which interview records are attached.
- **Interviews**: Links a `JobApplication` to an `InterviewerUser`, recording the scheduled date, status, score, and notes of a conducted interview.

#### 1) Relationships

- **One-to-One / TPT Inheritance (Super-type → Sub-type):** Every `CandidateUser`, `CompanyOwnerUser`, and `InterviewerUser` record shares its Primary Key with a `[User]` record (`UserId` = `[User].Id`), establishing a strict 1:1 specialization relationship enforced by a Foreign Key with `ON DELETE CASCADE`. Deleting a `[User]` row automatically removes the corresponding sub-type row.

- **One-to-Many — CompanyOwnerUser to Company:** A single company owner may register multiple companies, but each company belongs to exactly one owner. Enforced via `FK_Company_CompanyOwner` (`CompanyOwnerId` → `CompanyOwnerUser.UserId`) with `ON DELETE CASCADE`.

- **One-to-Many — JobSector to Company:** A sector groups many companies, but each company belongs to exactly one sector. Enforced via `FK_Company_JobSector` (`JobSectorId` → `JobSector.Id`) with `ON DELETE NO ACTION` (a sector cannot be deleted while companies reference it).

- **One-to-Many — Company to JobPosting:** A company can publish many job postings; each posting belongs to exactly one company. Enforced via `FK_JobPosting_Company` (`CompanyId` → `Company.Id`) with `ON DELETE CASCADE`.

- **Many-to-Many — CandidateUser ↔ Skill:** Resolved through the `CandidateSkills` table. A candidate may list many skills; a skill may be held by many candidates. A `UNIQUE` constraint on `(CandidateId, SkillId)` prevents duplicate entries.

- **Many-to-Many — CandidateUser ↔ ForeignLanguage:** Resolved through the `CandidateForeignLanguages` table. A candidate may be proficient in multiple languages; a language may appear on many candidates' profiles. A `UNIQUE` constraint on `(CandidateId, ForeignLanguageId)` prevents duplicates.

- **Aggregation — CandidateUser + JobPosting → JobApplication:** The `JobApplication` table is the physical realization of a candidate applying to a specific job posting, combining an M:N link into a concrete, state-tracked entity. `FK_JobApplication_Candidate` uses `ON DELETE CASCADE`; `FK_JobApplication_JobPosting` uses `ON DELETE NO ACTION` (cascade is handled manually by the `trg_JobPosting_CascadeDeleteApplications` trigger to avoid MSSQL's multiple cascade path error).

- **Aggregation Connection — JobApplication + InterviewerUser → Interviews:** The `Interviews` table connects an interviewer to a specific `JobApplication`. `FK_Interviews_JobApplication` uses `ON DELETE CASCADE`. `FK_Interviews_Interviewer` (`InterviewerId` → `InterviewerUser.UserId`) intentionally uses `ON DELETE NO ACTION`: because the path `[User] → InterviewerUser → Interviews` combined with the path `[User] → CandidateUser → JobApplication → Interviews` creates a multiple cascade path that MSSQL disallows. As a result, an `InterviewerUser` cannot be deleted while active `Interviews` records reference them; the application layer must reassign or cancel interviews before removing an interviewer.

#### 2) Normalization

The database schema has been normalized to **Third Normal Form (3NF)** to minimize redundancy and dependency issues.

- **1NF:** Every table has a defined Primary Key guaranteeing row uniqueness. There are no repeating groups — multi-valued attributes such as skills and languages are extracted into dedicated M:N association tables (`CandidateSkills`, `CandidateForeignLanguages`). All column domains are atomic (single-valued per cell).

- **2NF:** All non-key attributes are fully functionally dependent on the entire Primary Key. In association tables with composite natural keys (e.g., `(CandidateId, SkillId)`), a surrogate `IDENTITY` PK is used instead, and a `UNIQUE` constraint enforces the natural composite uniqueness separately. This eliminates any risk of partial dependency on a subset of the key.

- **3NF:** There are no transitive dependencies. For example, sector name is not stored inside `Company`; instead, a Foreign Key (`JobSectorId`) references the `JobSector` entity, which owns `SectorName`. Similarly, computed values such as `ApplicationCount` (derived as `COUNT(*)` over `JobApplication`) and `AverageScore` (derived as `AVG(Score)` over `Interviews`) are intentionally excluded as physical columns and are computed dynamically at query time, maintaining 3NF compliance and avoiding update anomalies.

---

## III. Database Structures

A comprehensive overview of the database structures employed in RecruitmentDB is provided below.

### Table Structures

---

**1. [User]**
- **Columns:** `Id` (INT), `Email` (VARCHAR(255)), `PasswordHash` (VARCHAR(255)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_User` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - UNIQUE (`Email`)
  - NOT NULL: `Email`, `PasswordHash`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`
- **Note:** `Email` uniqueness is enforced at the database level via both the UNIQUE constraint and the implicit non-clustered index it creates.

---

**2. CandidateUser**
- **Columns:** `UserId` (INT), `ResumeUrl` (VARCHAR(500)), `GitHubProfile` (VARCHAR(255)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_CandidateUser` PRIMARY KEY (`UserId`)
  - `FK_CandidateUser_User` FOREIGN KEY (`UserId`) → `[User](Id)` ON DELETE CASCADE
  - NOT NULL: `UserId`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`
  - NULLABLE: `ResumeUrl`, `GitHubProfile` (optional profile fields)

---

**3. CompanyOwnerUser**
- **Columns:** `UserId` (INT), `VerificationTaxNumber` (VARCHAR(50)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_CompanyOwnerUser` PRIMARY KEY (`UserId`)
  - `FK_CompanyOwnerUser_User` FOREIGN KEY (`UserId`) → `[User](Id)` ON DELETE CASCADE
  - NOT NULL: `UserId`, `VerificationTaxNumber`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`
- **Design Note:** `VerificationTaxNumber` is not currently enforced as UNIQUE at the database level. In a production environment, a UNIQUE constraint should be added to prevent duplicate registrations under the same tax identity.

---

**4. InterviewerUser**
- **Columns:** `UserId` (INT), `Department` (VARCHAR(100)), `Title` (VARCHAR(100)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_InterviewerUser` PRIMARY KEY (`UserId`)
  - `FK_InterviewerUser_User` FOREIGN KEY (`UserId`) → `[User](Id)` ON DELETE CASCADE
  - NOT NULL: `UserId`, `Department`, `Title`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`

---

**5. JobSector**
- **Columns:** `Id` (INT), `SectorName` (VARCHAR(150)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_JobSector` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - UNIQUE (`SectorName`)
  - NOT NULL: `SectorName`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`

---

**6. Company**
- **Columns:** `Id` (INT), `CompanyOwnerId` (INT), `JobSectorId` (INT), `CompanyName` (VARCHAR(255)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_Company` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - `FK_Company_CompanyOwner` FOREIGN KEY (`CompanyOwnerId`) → `CompanyOwnerUser(UserId)` ON DELETE CASCADE
  - `FK_Company_JobSector` FOREIGN KEY (`JobSectorId`) → `JobSector(Id)` ON DELETE NO ACTION (a sector cannot be deleted while companies are assigned to it)
  - NOT NULL: `CompanyOwnerId`, `JobSectorId`, `CompanyName`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`

---

**7. JobPosting**
- **Columns:** `Id` (INT), `CompanyId` (INT), `Title` (VARCHAR(200)), `Description` (NVARCHAR(MAX)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_JobPosting` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - `FK_JobPosting_Company` FOREIGN KEY (`CompanyId`) → `Company(Id)` ON DELETE CASCADE
  - NOT NULL: `CompanyId`, `Title`, `Description`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`
- **Design Note:** `Description` uses `NVARCHAR(MAX)` (rather than `VARCHAR`) to support full Unicode character sets for multilingual job descriptions. `ApplicationCount` is intentionally omitted as a physical column (it is a derived attribute computed as `COUNT(*) FROM JobApplication WHERE JobPostingId = Id`).

---

**8. Skill**
- **Columns:** `Id` (INT), `SkillName` (VARCHAR(150)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_Skill` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - UNIQUE (`SkillName`)
  - NOT NULL: `SkillName`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`

---

**9. CandidateSkills**
- **Columns:** `Id` (INT), `CandidateId` (INT), `SkillId` (INT), `ProficiencyLevel` (VARCHAR(50)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_CandidateSkills` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - `FK_CandidateSkills_Candidate` FOREIGN KEY (`CandidateId`) → `CandidateUser(UserId)` ON DELETE CASCADE
  - `FK_CandidateSkills_Skill` FOREIGN KEY (`SkillId`) → `Skill(Id)` ON DELETE CASCADE
  - `UQ_Candidate_Skill` UNIQUE (`CandidateId`, `SkillId`)
  - NOT NULL: `CandidateId`, `SkillId`, `ProficiencyLevel`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `'Beginner'` on `ProficiencyLevel`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`
- **Design Note:** Allowed values for `ProficiencyLevel` are `'Beginner'`, `'Intermediate'`, `'Advanced'`, and `'Expert'`. A CHECK constraint (e.g., `CHECK (ProficiencyLevel IN ('Beginner','Intermediate','Advanced','Expert'))`) is not included in the current schema but would further enforce domain integrity at the database level.

---

**10. ForeignLanguage**
- **Columns:** `Id` (INT), `LanguageName` (VARCHAR(100)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_ForeignLanguage` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - UNIQUE (`LanguageName`)
  - NOT NULL: `LanguageName`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`

---

**11. CandidateForeignLanguages**
- **Columns:** `Id` (INT), `CandidateId` (INT), `ForeignLanguageId` (INT), `ProficiencyLevel` (VARCHAR(50)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_CandidateForeignLanguages` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - `FK_CandidateForeignLanguages_Candidate` FOREIGN KEY (`CandidateId`) → `CandidateUser(UserId)` ON DELETE CASCADE
  - `FK_CandidateForeignLanguages_Language` FOREIGN KEY (`ForeignLanguageId`) → `ForeignLanguage(Id)` ON DELETE CASCADE
  - `UQ_Candidate_Language` UNIQUE (`CandidateId`, `ForeignLanguageId`)
  - NOT NULL: `CandidateId`, `ForeignLanguageId`, `ProficiencyLevel`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `'A1'` on `ProficiencyLevel`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`
- **Design Note:** Allowed values for `ProficiencyLevel` follow the CEFR standard: `'A1'`, `'A2'`, `'B1'`, `'B2'`, `'C1'`, `'C2'`. A CHECK constraint would enforce this at the database level but is not currently present in the schema.

---

**12. JobApplication**
- **Columns:** `Id` (INT), `CandidateId` (INT), `JobPostingId` (INT), `ApplicationStatus` (VARCHAR(50)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_JobApplication` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - `FK_JobApplication_Candidate` FOREIGN KEY (`CandidateId`) → `CandidateUser(UserId)` ON DELETE CASCADE
  - `FK_JobApplication_JobPosting` FOREIGN KEY (`JobPostingId`) → `JobPosting(Id)` ON DELETE NO ACTION — cascade is handled instead by the `trg_JobPosting_CascadeDeleteApplications` trigger (see Triggers section)
  - `UQ_Candidate_Job` UNIQUE (`CandidateId`, `JobPostingId`) — a candidate may apply to the same posting only once
  - NOT NULL: `CandidateId`, `JobPostingId`, `ApplicationStatus`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `'Pending'` on `ApplicationStatus`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`
- **Design Note:** Allowed values for `ApplicationStatus` are `'Pending'`, `'Accepted'`, and `'Rejected'`. A CHECK constraint would enforce this domain at the database level but is not currently present. `AverageScore` is a derived attribute (computed as `AVG(Score)` over linked `Interviews` rows) and is intentionally excluded as a physical column.

---

**13. Interviews**
- **Columns:** `Id` (INT), `ApplicationId` (INT), `InterviewerId` (INT), `ScheduledDate` (DATETIME), `Status` (VARCHAR(50)), `Score` (INT), `Notes` (NVARCHAR(MAX)), `CreatedAt` (DATETIME), `UpdatedAt` (DATETIME).
- **Constraints:**
  - `PK_Interviews` PRIMARY KEY (`Id`) — IDENTITY(1,1)
  - `FK_Interviews_JobApplication` FOREIGN KEY (`ApplicationId`) → `JobApplication(Id)` ON DELETE CASCADE
  - `FK_Interviews_Interviewer` FOREIGN KEY (`InterviewerId`) → `InterviewerUser(UserId)` ON DELETE NO ACTION — an `InterviewerUser` record cannot be deleted while active `Interviews` rows reference it; the application layer must resolve this dependency first
  - NOT NULL: `ApplicationId`, `InterviewerId`, `ScheduledDate`, `Status`, `CreatedAt`, `UpdatedAt`
  - DEFAULT `'Scheduled'` on `Status`
  - DEFAULT `GETDATE()` on `CreatedAt` and `UpdatedAt`
  - NULLABLE: `Score`, `Notes` (not available until the interview is completed)
- **Design Note:** Allowed values for `Status` are `'Scheduled'`, `'Completed'`, and `'Cancelled'`. `Score` is intended to range from 0 to 100; a CHECK constraint (`CHECK (Score BETWEEN 0 AND 100)`) would enforce this but is not currently present in the schema. `Notes` uses `NVARCHAR(MAX)` to support Unicode content in interview feedback.

---

### Indices

MSSQL automatically creates a **clustered index** on every `PRIMARY KEY` column (e.g., `[User].Id`, `Company.Id`), providing optimal performance for primary key lookups and range scans. In addition, every `UNIQUE` constraint implicitly creates a **non-clustered unique index**, enforcing uniqueness while also accelerating exact-match queries on those columns. The following unique non-clustered indices are therefore present:

| Index (via UNIQUE constraint) | Table |
|---|---|
| `Email` | `[User]` |
| `SectorName` | `JobSector` |
| `SkillName` | `Skill` |
| `LanguageName` | `ForeignLanguage` |
| `UQ_Candidate_Skill` (`CandidateId`, `SkillId`) | `CandidateSkills` |
| `UQ_Candidate_Language` (`CandidateId`, `ForeignLanguageId`) | `CandidateForeignLanguages` |
| `UQ_Candidate_Job` (`CandidateId`, `JobPostingId`) | `JobApplication` |

No additional explicit `CREATE INDEX` statements are present in the current schema. For further performance optimization in production, non-unique non-clustered indices on frequently filtered Foreign Key columns (e.g., `JobApplication.JobPostingId`, `Interviews.ApplicationId`) would be recommended.

---

### Views

There are no explicit SQL `VIEW` objects created in `database.sql`. The project uses Entity Framework with `.edmx` ORM mapping, through which computed values (such as `ApplicationCount` aggregated per `JobPosting`, or `AverageScore` averaged per `JobApplication`) are derived dynamically via LINQ queries at the application layer. This approach provides equivalent functionality to database views while retaining 3NF compliance in the physical schema and allowing EF's change-tracking and query optimization to operate effectively.

---

### Triggers

A total of **17 triggers** are implemented across RecruitmentDB to enforce database integrity and provide an automatic audit trail.

#### Audit Trail — UpdatedAt Timestamp Triggers (AFTER UPDATE)

These triggers fire `AFTER UPDATE` on their respective tables and set `UpdatedAt = GETDATE()` for the affected rows, using the `Inserted` pseudo-table to identify which rows were modified. MSSQL's default setting for `RECURSIVE_TRIGGERS` is `OFF` at the database level, which prevents these self-referencing UPDATE triggers from entering infinite recursion.

| Trigger | Table |
|---|---|
| `trg_User_UpdateModificationTime` | `[User]` |
| `trg_CandidateUser_UpdateModificationTime` | `CandidateUser` |
| `trg_CompanyOwnerUser_UpdateModificationTime` | `CompanyOwnerUser` |
| `trg_InterviewerUser_UpdateModificationTime` | `InterviewerUser` |
| `trg_JobSector_UpdateModificationTime` | `JobSector` |
| `trg_Skill_UpdateModificationTime` | `Skill` |
| `trg_ForeignLanguage_UpdateModificationTime` | `ForeignLanguage` |
| `trg_Company_UpdateModificationTime` | `Company` |
| `trg_JobPosting_UpdateModificationTime` | `JobPosting` |
| `trg_CandidateSkills_UpdateModificationTime` | `CandidateSkills` |
| `trg_CandidateForeignLanguages_UpdateModificationTime` | `CandidateForeignLanguages` |
| `trg_JobApplication_UpdateModificationTime` | `JobApplication` |
| `trg_Interviews_UpdateModificationTime` | `Interviews` |

#### Polymorphic Propagation Triggers (AFTER UPDATE)

When a sub-type user table is updated, these triggers also update the `UpdatedAt` field on the parent `[User]` row, ensuring the super-type always reflects the latest modification time regardless of which sub-type was changed.

| Trigger | Table | Action |
|---|---|---|
| `trg_CandidateUser_UpdateUserModificationTime` | `CandidateUser` | Updates `[User].UpdatedAt` for matching `UserId` |
| `trg_CompanyOwnerUser_UpdateUserModificationTime` | `CompanyOwnerUser` | Updates `[User].UpdatedAt` for matching `UserId` |
| `trg_InterviewerUser_UpdateUserModificationTime` | `InterviewerUser` | Updates `[User].UpdatedAt` for matching `UserId` |

#### Cascade Workaround Trigger (AFTER DELETE)

| Trigger | Table | Purpose |
|---|---|---|
| `trg_JobPosting_CascadeDeleteApplications` | `JobPosting` | On deletion of a `JobPosting` row, manually deletes all `JobApplication` rows where `JobPostingId` matches the deleted posting's `Id`. This manual cascade is required because MSSQL blocks automatic `ON DELETE CASCADE` on `FK_JobApplication_JobPosting` — the cascade path `[User] → CompanyOwnerUser → Company → JobPosting → JobApplication` combined with `[User] → CandidateUser → JobApplication` would create multiple cascade paths to the same table, which MSSQL disallows. |

---

## IV. UI Design

The UI design of the Entity Framework-backed platform is centered on providing an intuitive, role-aware experience for candidates, company owners, interviewers, and system administrators. Instead of exposing raw database mechanics (such as free-form SQL execution or raw query builders), the application abstracts these into user-friendly graphical interfaces, presenting data in ways that map cleanly to the underlying relational entities.

### 1. Authentication & Onboarding

**Login / Registration Page:** The entry point of the platform. It handles user authentication and role selection (Candidate, Company Owner, or Interviewer). The form dynamically adapts to the selected role—for example, exposing the `VerificationTaxNumber` field exclusively when registering as a Company Owner.

### 2. Role-Based Dashboards (Start Pages)

After login, users are routed to highly customized dashboards serving as their command centers:
- **Candidate Hub:** Displays a feed of recommended job postings, active applications, and their current `ApplicationStatus`.
- **Company Panel:** Shows an overview of registered companies under the owner, active job postings, and high-level application metrics.
- **Interviewer Action Board:** A timeline-centric dashboard listing upcoming and recently completed `Interviews`, sorted by `ScheduledDate`.

### 3. Profile & Account Management

**Manage Account:** Accessible by all roles. Candidates update their `ResumeUrl`, `GitHubProfile`, skills (`CandidateSkills`), and languages (`CandidateForeignLanguages`) via intuitive multi-select dropdowns populated from the system dictionaries. Company Owners update corporate details, and Interviewers update their `Department` and `Title`.

### 4. Core Business Workflows

- **Manage Job Postings (Companies):** An interface for companies to create, edit, and close job postings. Fields like the sector category utilize dropdowns tied to the `JobSector` table.
- **Manage Applications (Companies & Candidates):** A visual pipeline interface. Companies can review applicant profiles and transition the `ApplicationStatus` (`Pending` → `Accepted` / `Rejected`). Candidates use this to track their progress.
- **Interview Evaluation Panel (Interviewers):** A dedicated interface accessed from the Interviewer Action Board. For a specific tracked application, the interviewer can update the `Status` to `Completed` and submit a numeric `Score` alongside rich-text `Notes`.

### 5. Platform Administration & Analytics

- **Admin Control Center:** A secure zone restricted to system administrators. Rather than allowing raw SQL commands, it provides visual DataGrid interfaces to execute CRUD operations on reference catalogs (`JobSector`, `Skill`, `ForeignLanguage`), preventing data fragmentation.
- **Manage Users:** An interface for administrators to supervise the platform ecosystem. Admins can view user details, filter by sub-type roles, or perform hard deletes that trigger safe cascading removals down the entity hierarchy.
- **Visual Analytics Page:** Instead of raw preset queries or SQL terminals, administrators and company owners access pre-built, interactive metric charts (e.g., application volume per sector, average candidate scores). These are powered by parameterized LINQ aggregation queries executed securely in the backend.

---

*UI Design Flow: Login/Registration → Role Dashboard (Start Page) → [Candidate: Manage Account / Apply to Jobs / Track Applications] | [Company Owner: Manage Account / Manage Postings / Review Applicants] | [Interviewer: Manage Account / Conduct Evaluations] | [Admin: Manage Users / Manage Dictionaries / View Analytics]*
