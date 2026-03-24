-- ==========================================
-- 1. Veritabanını Oluşturma ve Kullanma
-- ==========================================
CREATE DATABASE RecruitmentDB;
GO
USE RecruitmentDB;
GO

-- ==========================================
-- TABLO: [User]
-- Yapı: CONCEPT HIERARCHY (Super-type / Üst Sınıf)
-- İlişkiler: CandidateUser (1:1), CompanyOwnerUser (1:1), InterviewerUser (1:1)
-- Açıklama: Tüm kullanıcı rollerinin ortak alanlarını tutan üst sınıf tablosudur.
--           TPT (Table-Per-Type) mapping ile alt sınıflara ayrılır.
-- ==========================================
CREATE TABLE [User] (
    Id INT IDENTITY(1,1) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_User PRIMARY KEY (Id)
);
GO

-- ==========================================
-- TABLO: CandidateUser
-- Yapı: CONCEPT HIERARCHY (Sub-type / Alt Sınıf)
-- İlişkiler: User (1:1), JobApplication (1:N), CandidateSkills (1:N), CandidateForeignLanguages (1:N)
-- Açıklama: İş adaylarına özel alanları tutar. User tablosundan miras alır.
-- ==========================================
CREATE TABLE CandidateUser (
    UserId INT NOT NULL,
    ResumeUrl VARCHAR(500) NULL,
    GitHubProfile VARCHAR(255) NULL,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_CandidateUser PRIMARY KEY (UserId),
    CONSTRAINT FK_CandidateUser_User FOREIGN KEY (UserId) REFERENCES [User](Id) ON DELETE CASCADE
);
GO

-- ==========================================
-- TABLO: CompanyOwnerUser
-- Yapı: CONCEPT HIERARCHY (Sub-type / Alt Sınıf)
-- İlişkiler: User (1:1), Company (1:N)
-- Açıklama: Şirket sahiplerine özel alanları tutar. User tablosundan miras alır.
-- ==========================================
CREATE TABLE CompanyOwnerUser (
    UserId INT NOT NULL,
    VerificationTaxNumber VARCHAR(50) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_CompanyOwnerUser PRIMARY KEY (UserId),
    CONSTRAINT FK_CompanyOwnerUser_User FOREIGN KEY (UserId) REFERENCES [User](Id) ON DELETE CASCADE
);
GO

-- ==========================================
-- TABLO: InterviewerUser
-- Yapı: CONCEPT HIERARCHY (Sub-type / Alt Sınıf)
-- İlişkiler: User (1:1), Interviews (1:N)
-- Açıklama: Bağımsız mülakatçılara özel alanları tutar. User tablosundan miras alır.
-- ==========================================
CREATE TABLE InterviewerUser (
    UserId INT NOT NULL,
    Department VARCHAR(100) NOT NULL,
    Title VARCHAR(100) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_InterviewerUser PRIMARY KEY (UserId),
    CONSTRAINT FK_InterviewerUser_User FOREIGN KEY (UserId) REFERENCES [User](Id) ON DELETE CASCADE
);
GO

-- ==========================================
-- TABLO: JobSector
-- Yapı: ENTITY
-- İlişkiler: Company (1:N)
-- Açıklama: İş sektörlerini tanımlayan bağımsız varlık tablosudur (Teknoloji, Finans, Sağlık vb.).
-- ==========================================
CREATE TABLE JobSector (
    Id INT IDENTITY(1,1) NOT NULL,
    SectorName VARCHAR(150) NOT NULL UNIQUE,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_JobSector PRIMARY KEY (Id)
);
GO

-- ==========================================
-- TABLO: Company
-- Yapı: ENTITY
-- İlişkiler: CompanyOwnerUser (N:1), JobSector (N:1), JobPosting (1:N)
-- Açıklama: Platformdaki şirketleri temsil eder. Bir şirket sahibine ve bir sektöre bağlıdır.
-- ==========================================
CREATE TABLE Company (
    Id INT IDENTITY(1,1) NOT NULL,
    CompanyOwnerId INT NOT NULL,
    JobSectorId INT NOT NULL,
    CompanyName VARCHAR(255) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_Company PRIMARY KEY (Id),
    CONSTRAINT FK_Company_CompanyOwner FOREIGN KEY (CompanyOwnerId) REFERENCES CompanyOwnerUser(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_Company_JobSector FOREIGN KEY (JobSectorId) REFERENCES JobSector(Id)
);
GO

-- ==========================================
-- TABLO: JobPosting
-- Yapı: WEAK ENTITY (Company olmadan var olamaz)
-- İlişkiler: Company (N:1), JobApplication (1:N)
-- Açıklama: Şirketlerin yayınladığı iş ilanlarıdır. Şirkete bağımlıdır (Weak Entity).
-- ==========================================
CREATE TABLE JobPosting (
    Id INT IDENTITY(1,1) NOT NULL,
    CompanyId INT NOT NULL,
    Title VARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    -- DERIVED ATTRIBUTE: Calculated as COUNT(*) FROM JobApplication WHERE JobPostingId = Id
    -- (Not stored as a physical column; computed on query)
    -- ApplicationCount INT DEFAULT 0 NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_JobPosting PRIMARY KEY (Id),
    CONSTRAINT FK_JobPosting_Company FOREIGN KEY (CompanyId) REFERENCES Company(Id) ON DELETE CASCADE
);
GO

-- ==========================================
-- TABLO: Skill
-- Yapı: ENTITY
-- İlişkiler: CandidateSkills (1:N)
-- Açıklama: Sistemdeki tanımlı yetenekleri tutan bağımsız varlık tablosudur (Java, SQL, React vb.).
-- ==========================================
CREATE TABLE Skill (
    Id INT IDENTITY(1,1) NOT NULL,
    SkillName VARCHAR(150) NOT NULL UNIQUE,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_Skill PRIMARY KEY (Id)
);
GO

-- ==========================================
-- TABLO: CandidateSkills
-- Yapı: M:N ASSOCIATION (CandidateUser ile Skill arasındaki M:N ilişkiyi çözer)
-- İlişkiler: CandidateUser (N:1), Skill (N:1)
-- Açıklama: Adayların sahip olduğu yetenekleri ve seviyelerini kaydeden ara tablodur.
-- ==========================================
CREATE TABLE CandidateSkills (
    Id INT IDENTITY(1,1) NOT NULL,
    CandidateId INT NOT NULL,
    SkillId INT NOT NULL,
    ProficiencyLevel VARCHAR(50) DEFAULT 'Beginner' NOT NULL, -- Beginner, Intermediate, Advanced, Expert
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_CandidateSkills PRIMARY KEY (Id),
    CONSTRAINT FK_CandidateSkills_Candidate FOREIGN KEY (CandidateId) REFERENCES CandidateUser(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_CandidateSkills_Skill FOREIGN KEY (SkillId) REFERENCES Skill(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_Candidate_Skill UNIQUE (CandidateId, SkillId)
);
GO

-- ==========================================
-- TABLO: ForeignLanguage
-- Yapı: ENTITY
-- İlişkiler: CandidateForeignLanguages (1:N)
-- Açıklama: Sistemdeki tanımlı yabancı dilleri tutan bağımsız varlık tablosudur (İngilizce, Almanca vb.).
-- ==========================================
CREATE TABLE ForeignLanguage (
    Id INT IDENTITY(1,1) NOT NULL,
    LanguageName VARCHAR(100) NOT NULL UNIQUE,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_ForeignLanguage PRIMARY KEY (Id)
);
GO

-- ==========================================
-- TABLO: CandidateForeignLanguages
-- Yapı: M:N ASSOCIATION (CandidateUser ile ForeignLanguage arasındaki M:N ilişkiyi çözer)
-- İlişkiler: CandidateUser (N:1), ForeignLanguage (N:1)
-- Açıklama: Adayların bildiği yabancı dilleri ve seviyelerini kaydeden ara tablodur.
-- ==========================================
CREATE TABLE CandidateForeignLanguages (
    Id INT IDENTITY(1,1) NOT NULL,
    CandidateId INT NOT NULL,
    ForeignLanguageId INT NOT NULL,
    ProficiencyLevel VARCHAR(50) DEFAULT 'A1' NOT NULL, -- A1, A2, B1, B2, C1, C2
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_CandidateForeignLanguages PRIMARY KEY (Id),
    CONSTRAINT FK_CandidateForeignLanguages_Candidate FOREIGN KEY (CandidateId) REFERENCES CandidateUser(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_CandidateForeignLanguages_Language FOREIGN KEY (ForeignLanguageId) REFERENCES ForeignLanguage(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_Candidate_Language UNIQUE (CandidateId, ForeignLanguageId)
);
GO

-- ==========================================
-- TABLO: JobApplication
-- Yapı: WEAK ENTITY + AGGREGATION (CandidateUser ile JobPosting arasındaki M:N ilişkiyi çözer)
-- İlişkiler: CandidateUser (N:1), JobPosting (N:1), Interviews (1:N)
-- Açıklama: Adayların ilanlara yaptığı başvurulardır. Hem aggregation hedefi hem de
--           mülakatların bağlandığı paket yapıdır. Aynı aday aynı ilana 1 kez başvurabilir.
-- ==========================================
CREATE TABLE JobApplication (
    Id INT IDENTITY(1,1) NOT NULL,
    CandidateId INT NOT NULL,
    JobPostingId INT NOT NULL,
    ApplicationStatus VARCHAR(50) DEFAULT 'Pending' NOT NULL,
    -- DERIVED ATTRIBUTE: Calculated as AVG(Score) FROM Interviews WHERE ApplicationId = Id
    -- (Not stored as a physical column; computed on query)
    -- AverageScore FLOAT NULL,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_JobApplication PRIMARY KEY (Id),
    CONSTRAINT FK_JobApplication_Candidate FOREIGN KEY (CandidateId) REFERENCES CandidateUser(UserId) ON DELETE CASCADE,
    -- ON DELETE NO ACTION: User-> CompanyOwnerUser üzerinden bir cycle oluşturduğu için workaround yapılması gerekti. Trigger ekleyerek çözdük.
    CONSTRAINT FK_JobApplication_JobPosting FOREIGN KEY (JobPostingId) REFERENCES JobPosting(Id) ON DELETE NO ACTION,
    CONSTRAINT UQ_Candidate_Job UNIQUE (CandidateId, JobPostingId)
);
GO

-- ==========================================
-- TABLO: Interviews
-- Yapı: AGGREGATION bağlantısı (JobApplication aggregation'ı ile InterviewerUser arasındaki ilişki)
-- İlişkiler: JobApplication (N:1), InterviewerUser (N:1)
-- Açıklama: Bir başvuru sürecine atanan mülakatçının gerçekleştirdiği değerlendirmedir.
--           State Machine mantığıyla (Scheduled -> Completed / Cancelled) ilerler.
--           InterviewerId FK'sında ON DELETE CASCADE kullanılmamıştır çünkü MSSQL'de
--           User -> InterviewerUser -> Interviews ve User -> Candidate -> Application -> Interviews
--           şeklinde multiple cascade path oluşur ve bu MSSQL tarafından engellenmiştir.
-- ==========================================
CREATE TABLE Interviews (
    Id INT IDENTITY(1,1) NOT NULL,
    ApplicationId INT NOT NULL,
    InterviewerId INT NOT NULL,
    ScheduledDate DATETIME NOT NULL,
    Status VARCHAR(50) DEFAULT 'Scheduled' NOT NULL,
    Score INT NULL,
    Notes NVARCHAR(MAX) NULL,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    UpdatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT PK_Interviews PRIMARY KEY (Id),
    CONSTRAINT FK_Interviews_JobApplication FOREIGN KEY (ApplicationId) REFERENCES JobApplication(Id) ON DELETE CASCADE,
    CONSTRAINT FK_Interviews_Interviewer FOREIGN KEY (InterviewerId) REFERENCES InterviewerUser(UserId)
);
GO

-- ==========================================
-- AUTO-SET MODIFICATION TIME (TRIGGERS)
-- ==========================================

-- User tablosu kendi güncellemesi
CREATE TRIGGER trg_User_UpdateModificationTime
ON [User] AFTER UPDATE AS
BEGIN
    UPDATE [User] SET UpdatedAt = GETDATE() FROM Inserted i WHERE [User].Id = i.Id;
END;
GO

-- Alt sınıflar güncellendiğinde üst sınıf User'ın UpdatedAt alanını günceller
CREATE TRIGGER trg_CandidateUser_UpdateUserModificationTime
ON CandidateUser AFTER UPDATE AS
BEGIN
    UPDATE [User] SET UpdatedAt = GETDATE() FROM Inserted i WHERE [User].Id = i.UserId;
END;
GO

CREATE TRIGGER trg_CompanyOwnerUser_UpdateUserModificationTime
ON CompanyOwnerUser AFTER UPDATE AS
BEGIN
    UPDATE [User] SET UpdatedAt = GETDATE() FROM Inserted i WHERE [User].Id = i.UserId;
END;
GO

CREATE TRIGGER trg_InterviewerUser_UpdateUserModificationTime
ON InterviewerUser AFTER UPDATE AS
BEGIN
    UPDATE [User] SET UpdatedAt = GETDATE() FROM Inserted i WHERE [User].Id = i.UserId;
END;
GO

-- Sub-type tabloların kendi UpdatedAt trigger'ları
CREATE TRIGGER trg_CandidateUser_UpdateModificationTime
ON CandidateUser AFTER UPDATE AS
BEGIN
    UPDATE CandidateUser SET UpdatedAt = GETDATE() FROM Inserted i WHERE CandidateUser.UserId = i.UserId;
END;
GO

CREATE TRIGGER trg_CompanyOwnerUser_UpdateModificationTime
ON CompanyOwnerUser AFTER UPDATE AS
BEGIN
    UPDATE CompanyOwnerUser SET UpdatedAt = GETDATE() FROM Inserted i WHERE CompanyOwnerUser.UserId = i.UserId;
END;
GO

CREATE TRIGGER trg_InterviewerUser_UpdateModificationTime
ON InterviewerUser AFTER UPDATE AS
BEGIN
    UPDATE InterviewerUser SET UpdatedAt = GETDATE() FROM Inserted i WHERE InterviewerUser.UserId = i.UserId;
END;
GO

-- Diğer tabloların kendi UpdatedAt trigger'ları
CREATE TRIGGER trg_Company_UpdateModificationTime
ON Company AFTER UPDATE AS
BEGIN
    UPDATE Company SET UpdatedAt = GETDATE() FROM Inserted i WHERE Company.Id = i.Id;
END;
GO

-- JobPosting silindiğinde bağlı JobApplication kayıtlarını siler
-- (MSSQL'de çoklu cascade path yasağını aşmak için FK CASCADE yerine trigger kullanılır)
CREATE TRIGGER trg_JobPosting_CascadeDeleteApplications
ON JobPosting AFTER DELETE AS
BEGIN
    DELETE FROM JobApplication WHERE JobPostingId IN (SELECT Id FROM Deleted);
END;
GO

CREATE TRIGGER trg_JobPosting_UpdateModificationTime
ON JobPosting AFTER UPDATE AS
BEGIN
    UPDATE JobPosting SET UpdatedAt = GETDATE() FROM Inserted i WHERE JobPosting.Id = i.Id;
END;
GO

CREATE TRIGGER trg_CandidateSkills_UpdateModificationTime
ON CandidateSkills AFTER UPDATE AS
BEGIN
    UPDATE CandidateSkills SET UpdatedAt = GETDATE() FROM Inserted i WHERE CandidateSkills.Id = i.Id;
END;
GO

CREATE TRIGGER trg_CandidateForeignLanguages_UpdateModificationTime
ON CandidateForeignLanguages AFTER UPDATE AS
BEGIN
    UPDATE CandidateForeignLanguages SET UpdatedAt = GETDATE() FROM Inserted i WHERE CandidateForeignLanguages.Id = i.Id;
END;
GO

CREATE TRIGGER trg_JobApplication_UpdateModificationTime
ON JobApplication AFTER UPDATE AS
BEGIN
    UPDATE JobApplication SET UpdatedAt = GETDATE() FROM Inserted i WHERE JobApplication.Id = i.Id;
END;
GO

CREATE TRIGGER trg_Interviews_UpdateModificationTime
ON Interviews AFTER UPDATE AS
BEGIN
    UPDATE Interviews SET UpdatedAt = GETDATE() FROM Inserted i WHERE Interviews.Id = i.Id;
END;
GO
