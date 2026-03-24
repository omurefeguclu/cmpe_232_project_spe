# Project Design Report — ER Model

**Project:** Interview-as-a-Service (IaaS) Platform  
**Database:** RecruitmentDB (MSSQL)

---

## I. Introduction

This report documents the Entity-Relationship (ER) model design for the **Interview-as-a-Service (IaaS)** platform — a marketplace that connects independent HR professionals with companies seeking talent. The platform supports three user roles (candidates, company owners, and independent interviewers), enabling a complete end-to-end recruitment workflow: from job posting publication, through candidate application, to interview scheduling and evaluation.

The database is designed with the following guiding principles:

- **Role-based user hierarchy** using a Concept Hierarchy (ISA / TPT mapping) so that shared user fields are not duplicated across role-specific tables.
- **Existential dependency** expressed through a Weak Entity for job postings, which cannot exist without their owning company.
- **Aggregation** to treat the Candidate↔JobPosting M:N relationship (`JobApplication`) as a first-class entity so that interviews can be linked to a specific application rather than loosely to a candidate or posting.
- **M:N Associations** with descriptive attributes for candidate skills and foreign language proficiencies.
- **Derived attributes** (`ApplicationCount` on `JobPosting`, `AverageScore` on `JobApplication`) to express values that are logically computable from other data in the schema, making common read queries simpler without changing the underlying source of truth.
- **Referential integrity and uniqueness constraints** to enforce real-world business rules (one application per candidate per posting, one skill/language entry per candidate, etc.).

The schema consists of **9 entities**, **7 relationships**, and **4 complex structures**, satisfying and exceeding the minimum requirements (≥6 relations, ≥4 relationships, ≥2 complex structures).

---

## II. Entity-Relationship Model

### a. Definition

The RecruitmentDB schema models a recruitment marketplace with three types of actors — **candidates**, **company owners**, and **independent interviewers** — who are all represented as specializations of a common `User` super-type. The general flow of the system is as follows:

1. All platform participants register as a `User`. Each user then specializes into one of three sub-types through an ISA relationship: `CandidateUser`, `CompanyOwnerUser`, or `InterviewerUser`.
2. A `CompanyOwnerUser` creates one or more `Company` entities. Each `Company` is associated with a `JobSector` and can publish multiple `JobPosting` records (which are weak entities, dependent on the company for existence).
3. A `CandidateUser` enriches their profile by associating themselves with `Skill` entities (via the `HasSkill` M:N relationship, implemented as `CandidateSkills`) and `ForeignLanguage` entities (via the `Speaks` M:N relationship, implemented as `CandidateForeignLanguages`). Each association carries a `ProficiencyLevel` attribute.
4. A `CandidateUser` applies to a `JobPosting` through the `AppliesTo` relationship. Because this application object is itself a meaningful entity in the workflow (it has a lifecycle status and becomes the anchor for future interviews), it is **aggregated** into `JobApplication`.
5. An `InterviewerUser` is then assigned to evaluate a specific `JobApplication` via the `Evaluates` relationship, producing an `Interviews` record that tracks the scheduled date, status, score, and notes.

This design ensures that every interview can be traced back to a specific candidate–posting pair, and that all historical data survives independently across the system.

---

### b. Components

#### Entities

| # | Entity | Type | Primary Key | Description |
|---|---|---|---|---|
| 1 | `User` | Super-type (Concept Hierarchy) | `Id` (INT, IDENTITY) | Stores common authentication data for all users: `Email` (UNIQUE), `PasswordHash`, `CreatedAt`, `UpdatedAt`. The root of the TPT hierarchy. |
| 2 | `CandidateUser` | Sub-type (ISA) | `UserId` (FK → User.Id) | Extends `User` for job-seeking candidates. Additional attributes: `ResumeUrl`, `GitHubProfile`. UserId is both the PK and FK, inheriting identity from `User`. |
| 3 | `CompanyOwnerUser` | Sub-type (ISA) | `UserId` (FK → User.Id) | Extends `User` for company representatives. Additional attribute: `VerificationTaxNumber` (used for identity verification). |
| 4 | `InterviewerUser` | Sub-type (ISA) | `UserId` (FK → User.Id) | Extends `User` for independent interviewers. Additional attributes: `Department`, `Title` (define the interviewer's area of expertise). |
| 5 | `JobSector` | Strong Entity | `Id` (INT, IDENTITY) | Categorizes companies by industry (e.g., Technology, Finance, Healthcare). Attributes: `SectorName` (UNIQUE), `CreatedAt`. |
| 6 | `Company` | Entity | `Id` (INT, IDENTITY) | Represents registered companies on the platform. Attributes: `CompanyName`, `CreatedAt`, `UpdatedAt`. Foreign keys: `CompanyOwnerId` → `CompanyOwnerUser`, `JobSectorId` → `JobSector`. |
| 7 | `JobPosting` | **Weak Entity** | `Id` (partial key) + `CompanyId` (identifying FK) | Job listings published by companies. Attributes: `Title`, `Description`, `CreatedAt`, `UpdatedAt`. Derived attribute: `ApplicationCount` (total number of applications received). Cannot exist without an owning `Company`. |
| 8 | `Skill` | Strong Entity | `Id` (INT, IDENTITY) | Represents a defined technical or professional skill (e.g., Java, SQL, React). Attributes: `SkillName` (UNIQUE), `CreatedAt`. |
| 9 | `ForeignLanguage` | Strong Entity | `Id` (INT, IDENTITY) | Represents a defined foreign language (e.g., English, German, French). Attributes: `LanguageName` (UNIQUE), `CreatedAt`. |

**Why this structure?**  
The ISA / TPT approach avoids storing NULL-heavy rows in a single wide user table. Each sub-type table only carries fields relevant to that role. `JobPosting` is a Weak Entity because a posting has no meaning outside the context of its publishing company — if the company is deleted, the posting must also be deleted. `JobSector`, `Skill`, and `ForeignLanguage` are independent reference entities that provide controlled vocabularies to the system.

---

#### Relationships

| # | Relationship Name | Entities Involved | Implementation | Description |
|---|---|---|---|---|
| 1 | **ISA** | `User` → `CandidateUser`, `CompanyOwnerUser`, `InterviewerUser` | Concept Hierarchy (TPT) | Each `User` can specialize into exactly one sub-type. The sub-type table holds the role-specific attributes and shares its `UserId` PK with the parent. |
| 2 | **Owns** | `CompanyOwnerUser` → `Company` | FK `Company.CompanyOwnerId` | A company owner can own one or more companies (1:N). A company must have exactly one owner. |
| 3 | **BelongsTo** | `JobSector` → `Company` | FK `Company.JobSectorId` | A company is categorized under exactly one job sector (N:1 from Company's perspective). A sector can have many companies. |
| 4 | **Posts** | `Company` → `JobPosting` | FK `JobPosting.CompanyId` (Identifying Relationship) | A company can publish many job postings. This is the **identifying relationship** for the `JobPosting` weak entity — a posting's existence depends on its parent company. |
| 5 | **HasSkill** | `CandidateUser` ↔ `Skill` | `CandidateSkills` (association table) | M:N relationship. A candidate can have many skills; a skill can belong to many candidates. The relationship carries a `ProficiencyLevel` attribute (Beginner, Intermediate, Advanced, Expert). Unique constraint prevents duplicate entries. |
| 6 | **Speaks** | `CandidateUser` ↔ `ForeignLanguage` | `CandidateForeignLanguages` (association table) | M:N relationship. A candidate can speak many languages; a language can be associated with many candidates. Carries a CEFR `ProficiencyLevel` attribute (A1–C2). Unique constraint prevents duplicates. |
| 7 | **AppliesTo / Evaluates** | `CandidateUser` ↔ `JobPosting` → `InterviewerUser` | `JobApplication` (Aggregation) + `Interviews` | Two-part relationship. `AppliesTo` (M:N) captures the application of a candidate to a posting, producing a `JobApplication` record with `ApplicationStatus`. This record is then **aggregated** and connected to `InterviewerUser` via the `Evaluates` relationship, producing an `Interviews` record with `ScheduledDate`, `Status`, `Score`, and `Notes`. |

**Why this structure?**  
The `HasSkill` and `Speaks` relationships are implemented as association tables rather than being collapsed into the candidate entity, because both are genuine M:N relationships with their own descriptive attribute (`ProficiencyLevel`). The `AppliesTo` / `Evaluates` split uses **Aggregation** because an interview is not simply a ternary relationship between a candidate, a posting, and an interviewer — it is specifically attached to a *particular application object*, which has its own lifecycle. Aggregating `JobApplication` makes this connection explicit and traceable.

---

#### Attributes Summary

| Entity / Relationship | Attribute | Key Type | Notes |
|---|---|---|---|
| `User` | `Id` | PK (IDENTITY) | Auto-increment |
| `User` | `Email` | — | UNIQUE |
| `User` | `PasswordHash` | — | — |
| `User` | `CreatedAt`, `UpdatedAt` | — | Default: GETDATE(); UpdatedAt auto-updated by trigger |
| `CandidateUser` | `UserId` | PK, FK | Identifying FK to User |
| `CandidateUser` | `ResumeUrl`, `GitHubProfile` | — | Nullable |
| `CompanyOwnerUser` | `UserId` | PK, FK | Identifying FK to User |
| `CompanyOwnerUser` | `VerificationTaxNumber` | — | Required |
| `InterviewerUser` | `UserId` | PK, FK | Identifying FK to User |
| `InterviewerUser` | `Department`, `Title` | — | Required |
| `JobSector` | `Id` | PK (IDENTITY) | — |
| `JobSector` | `SectorName` | — | UNIQUE |
| `Company` | `Id` | PK (IDENTITY) | — |
| `Company` | `CompanyOwnerId` | FK | → CompanyOwnerUser |
| `Company` | `JobSectorId` | FK | → JobSector |
| `Company` | `CompanyName` | — | — |
| `JobPosting` | `Id` | Partial Key (IDENTITY) | Weak entity — identity depends on CompanyId |
| `JobPosting` | `CompanyId` | Identifying FK | → Company (CASCADE DELETE) |
| `JobPosting` | `Title`, `Description` | — | — |
| `Skill` | `Id` | PK (IDENTITY) | — |
| `Skill` | `SkillName` | — | UNIQUE |
| `ForeignLanguage` | `Id` | PK (IDENTITY) | — |
| `ForeignLanguage` | `LanguageName` | — | UNIQUE |
| `CandidateSkills` | `CandidateId`, `SkillId` | Composite PK, FK | Prevents duplicate candidate–skill pairs |
| `CandidateSkills` | `ProficiencyLevel` | — | Beginner / Intermediate / Advanced / Expert |
| `CandidateForeignLanguages` | `CandidateId`, `ForeignLanguageId` | Composite PK, FK | Prevents duplicate candidate–language pairs |
| `CandidateForeignLanguages` | `ProficiencyLevel` | — | CEFR: A1 / A2 / B1 / B2 / C1 / C2 |
| `JobApplication` (Aggregation) | `CandidateId`, `JobPostingId` | Composite PK, FK | One application per candidate per posting |
| `JobApplication` | `ApplicationStatus` | — | Pending / In Review / Accepted / Rejected |
| `JobApplication` | `AverageScore` *(derived)* | — | `AVG(Interviews.Score)` WHERE `ApplicationId = Id` |
| `JobPosting` | `ApplicationCount` *(derived)* | — | `COUNT(JobApplication)` WHERE `JobPostingId = Id` |
| `Interviews` | `Id` | PK (IDENTITY) | — |
| `Interviews` | `ApplicationId` | FK | → JobApplication (CASCADE DELETE) |
| `Interviews` | `InterviewerId` | FK | → InterviewerUser (no CASCADE — avoids multiple cascade paths) |
| `Interviews` | `ScheduledDate` | — | DATE attribute |
| `Interviews` | `Status` | — | Scheduled / Completed / Cancelled |
| `Interviews` | `Score` | — | Nullable integer |
| `Interviews` | `Notes` | — | Nullable free-text |

---

#### Derived Attributes

Derived attributes are values that can be **computed from other data already present in the database**. In the ER diagram they are drawn as **dashed-border ellipses** attached to their entity. They are not stored as physical columns in the schema.

| Derived Attribute | Entity | Derivation Formula | Storage Strategy |
|---|---|---|---|
| `ApplicationCount` | `JobPosting` | `COUNT(*) FROM JobApplication WHERE JobPostingId = JobPosting.Id` | **Not stored** — computed on query (commented out in schema) |
| `AverageScore` | `JobApplication` | `AVG(Score) FROM Interviews WHERE ApplicationId = JobApplication.Id AND Score IS NOT NULL` | **Not stored** — computed on query (commented out in schema) |

---

### c. Cardinality and Modality

The table below defines the cardinality (how many instances can participate) and modality (whether participation is mandatory or optional) for each relationship.

| Relationship | Entity A | Cardinality (A:B) | Entity B | Modality A | Modality B | Notes |
|---|---|---|---|---|---|---|
| **ISA** | `User` | 1:1 | `CandidateUser` | Mandatory (if role = Candidate) | Mandatory | Each sub-type must have a parent User row |
| **ISA** | `User` | 1:1 | `CompanyOwnerUser` | Mandatory (if role = Owner) | Mandatory | Same ISA constraint |
| **ISA** | `User` | 1:1 | `InterviewerUser` | Mandatory (if role = Interviewer) | Mandatory | Same ISA constraint |
| **Owns** | `CompanyOwnerUser` | 1:N | `Company` | Optional (owner may not yet have a company) | Mandatory (every company must have an owner) | An owner can create multiple companies; a company cannot exist without an owner |
| **BelongsTo** | `JobSector` | 1:N | `Company` | Optional (a sector may have no companies yet) | Mandatory (every company must belong to a sector) | A sector categorizes many companies |
| **Posts** | `Company` | 1:N | `JobPosting` | Optional (a company may have no postings yet) | **Mandatory** (identifying relationship — a weak entity requires its owner) | Deletion of Company cascades to all its JobPostings |
| **HasSkill** | `CandidateUser` | M:N | `Skill` | Optional (a candidate may have no skills listed) | Optional (a skill may not yet be associated with any candidate) | Association table `CandidateSkills`; `ProficiencyLevel` attribute on the relationship |
| **Speaks** | `CandidateUser` | M:N | `ForeignLanguage` | Optional | Optional | Association table `CandidateForeignLanguages`; `ProficiencyLevel` attribute on the relationship |
| **AppliesTo** | `CandidateUser` | M:N | `JobPosting` | Optional (a candidate may not have applied yet) | Optional (a posting may have no applicants yet) | Aggregation: the resulting `JobApplication` entity carries `ApplicationStatus` and is the anchor for interviews |
| **Evaluates** | `JobApplication` (aggregation) | M:N | `InterviewerUser` | Optional (an application may not yet have an interview) | Optional (an interviewer may not yet be assigned to any application) | Relationship table `Interviews`; carries `ScheduledDate`, `Status`, `Score`, `Notes` |

**Cardinality notation summary:**
- `1:1` — Exactly one instance on each side (ISA relationship between User and sub-type).
- `1:N` — One instance on the left participates with many on the right (Company → JobPosting, CompanyOwnerUser → Company, JobSector → Company).
- `M:N` — Many-to-many; requires an association table. Used for HasSkill, Speaks, AppliesTo, and Evaluates.

**Modality (participation constraint) notes:**
- **Mandatory (total participation):** Every `Company` must have an owner (`CompanyOwnerId NOT NULL`) and a sector (`JobSectorId NOT NULL`). Every `JobPosting` must belong to a `Company` (`CompanyId NOT NULL`, CASCADE DELETE). Every `CandidateSkills` record must reference a valid candidate and skill (`NOT NULL` FKs). Every `Interviews` record must be tied to a `JobApplication` (`NOT NULL`).
- **Optional (partial participation):** A `CompanyOwnerUser` need not have created any companies yet. A `Skill` or `ForeignLanguage` may exist in the system without any candidate having listed it. A `CandidateUser` may not have submitted any applications. An `InterviewerUser` may not yet have been assigned an interview.

---

## III. Final ER Schema

> **Note:** The ER diagram must be drawn using a dedicated ER diagramming tool (e.g., [draw.io](https://app.diagrams.net/), [ERDPlus](https://erdplus.com/), [dbdiagram.io](https://dbdiagram.io/), [Lucidchart](https://www.lucidchart.com/)). Insert a screenshot of the completed diagram here.

The diagram must include the following ER notation elements:

- **Rectangle** — for normal entities (`User`, `JobSector`, `Company`, `Skill`, `ForeignLanguage`, and ISA sub-type entities).
- **Double-bordered rectangle** — for the weak entity (`JobPosting`).
- **Triangle (ISA)** — for the concept hierarchy between `User` and its three sub-types.
- **Diamond** — for each relationship (`Owns`, `BelongsTo`, `Posts`, `HasSkill`, `Speaks`, `AppliesTo`, `Evaluates`).
- **Double-bordered diamond** — for the identifying relationship `Posts` (Company ↔ JobPosting weak entity).
- **Ellipse** — for attributes; underlined text inside ellipses denotes primary/partial keys; **dashed-border ellipse** for derived attributes (`ApplicationCount` on `JobPosting` and `AverageScore` on `JobApplication`).
- **Aggregation box** — a large rectangle enclosing the `CandidateUser`, `AppliesTo` diamond, and `JobPosting` entities/relationships, representing the `JobApplication` aggregation.

**Suggested layout:**

```
                          [User]
                            |
                          [ISA]
                     /     |      \
         [CandidateUser] [CompanyOwnerUser] [InterviewerUser]
              |   |              |                  |
        [HasSkill] |          [Owns]            [Evaluates]
         [Speaks]  |               \                |
                   |             [Company]    (from Aggregation box)
                   |            /       \
                [AppliesTo]  [Posts]  [BelongsTo]
              (AGGREGATION)     |          |
                   |        [JobPosting] [JobSector]
                [Evaluates]
```

*(Replace this text block with the actual screenshot of your ER diagram.)*

Extra free sites to draw the ER Diagram:
- https://www.drawio.com/
- https://www.quickdatabasediagrams.com/
- https://dbdiagram.io/
- https://www.lucidchart.com/

---

## IV. References

1. Microsoft SQL Server Documentation — https://learn.microsoft.com/en-us/sql/sql-server/
2. Elmasri, R. & Navathe, S. B., *Fundamentals of Database Systems*, 7th Edition — Entity-Relationship Model chapter.
3. draw.io (diagrams.net) — https://app.diagrams.net/
4. HireVue — AI-driven Video Interview Platform — https://www.hirevue.com/
5. Karat — Technical Interview Platform — https://karat.com/
6. Interviewing.io — Anonymous Technical Interviews — https://interviewing.io/
7. Common European Framework of Reference for Languages (CEFR) — https://www.coe.int/en/web/common-european-framework-reference-languages
8. ChatGPT (OpenAI) — Used for conceptual design exploration and SQL validation — https://chat.openai.com/
