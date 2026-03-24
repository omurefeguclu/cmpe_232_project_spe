# 02 — Varlık Yönetimi (CRUD Sayfaları)

> **Ders Zorunluluğu:** Her entity için ayrı sayfalar: Listeleme, Oluşturma, Düzenleme, Silme.  
> İlişkili entity seçimlerinde **dropdown** kullanılacak (text box YASAK).  
> İlişkili kayıt olsa dahi entity silinebilmeli.  
> **Silme onayı:** Ayrı onay sayfası yok — silme formu/butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir.

---

## 2.1 User (Üst Sınıf — Concept Hierarchy Root)

### Listeleme (`/Users/Index`)
- [ ] Tüm kullanıcıların listesi gösteriliyor
- [ ] Kolonlar: `Id`, `Email`, `CreatedAt`, `UpdatedAt`
- [ ] Her satırda: **Edit**, **Delete**, **Details** linkleri mevcut

### Oluşturma (`/Users/Create`)
- [ ] Form alanları: `Email`, `PasswordHash`
- `CreatedAt` ve `UpdatedAt` DB seviyesinde otomatik set edilir — formda readonly göster, uygulama set etmez
- [ ] Kayıt sonrası Index sayfasına yönlendirme

### Düzenleme (`/Users/Edit/{id}`)
- [ ] Mevcut değerler forma dolu geliyor
- [ ] `Email`, `PasswordHash` güncellenebiliyor
- [ ] Kayıt sonrası Index sayfasına yönlendirme

### Silme (`/Users/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kullanıcıyı silmek istediğinize emin misiniz?')"` ile tetiklenir
- [ ] Silindiğinde CASCADE FK ile `CandidateUser`, `CompanyOwnerUser`, `InterviewerUser` de silinir
- [ ] Silme sonrası Index sayfasına yönlendirme

---

## 2.2 CandidateUser (Sub-type)

### Listeleme (`/CandidateUsers/Index`)
- [ ] Tüm adayların listesi
- [ ] Kolonlar: `UserId`, `Email` (User join ile), `ResumeUrl`, `GitHubProfile`, `UpdatedAt`
- [ ] Her satırda: **Edit**, **Delete**, **Details** linkleri

### Oluşturma (`/CandidateUsers/Create`)
- [ ] `UserId` alanı yapılandırılmış: **Önce `User` oluşturulacak**, ardından `UserId` dropdown'dan seçilecek
  - [ ] Dropdown: sadece henüz başka bir sub-type'a atanmamış `User`lar listeleniyor
- [ ] Alanlar: `UserId` (dropdown), `ResumeUrl`, `GitHubProfile`

### Düzenleme (`/CandidateUsers/Edit/{id}`)
- [ ] `ResumeUrl` ve `GitHubProfile` güncellenebiliyor
- [ ] `UserId` değiştirilemez (readonly göster)

### Silme (`/CandidateUsers/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir
- [ ] Silindiğinde CASCADE ile ilgili `JobApplication`, `CandidateSkills`, `CandidateForeignLanguages` silinir

---

## 2.3 CompanyOwnerUser (Sub-type)

### Listeleme (`/CompanyOwnerUsers/Index`)
- [ ] Kolonlar: `UserId`, `Email` (User join), `VerificationTaxNumber`, `UpdatedAt`
- [ ] Her satırda Edit / Delete / Details

### Oluşturma (`/CompanyOwnerUsers/Create`)
- [ ] `UserId` dropdown (henüz sub-type'a atanmamış User'lar)
- [ ] Alanlar: `UserId` (dropdown), `VerificationTaxNumber`

### Düzenleme (`/CompanyOwnerUsers/Edit/{id}`)
- [ ] `VerificationTaxNumber` güncellenebiliyor

### Silme (`/CompanyOwnerUsers/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir
- [ ] Silindiğinde CASCADE ile ilgili `Company` kayıtları silinir

---

## 2.4 InterviewerUser (Sub-type)

### Listeleme (`/InterviewerUsers/Index`)
- [ ] Kolonlar: `UserId`, `Email` (User join), `Department`, `Title`, `UpdatedAt`

### Oluşturma (`/InterviewerUsers/Create`)
- [ ] `UserId` dropdown
- [ ] Alanlar: `UserId` (dropdown), `Department`, `Title`

### Düzenleme (`/InterviewerUsers/Edit/{id}`)
- [ ] `Department` ve `Title` güncellenebiliyor

### Silme (`/InterviewerUsers/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir
- [ ] **DİKKAT:** `Interviews.InterviewerId` FK'ı NO ACTION → silmeden önce ilgili `Interviews` silinmeli veya kullanıcıya uyarı gösterilmeli

---

## 2.5 JobSector

### Listeleme (`/JobSectors/Index`)
- [ ] Kolonlar: `Id`, `SectorName`, `CreatedAt`
- [ ] Her satırda Edit / Delete

### Oluşturma (`/JobSectors/Create`)
- [ ] Alanlar: `SectorName`
- [ ] Benzersizlik: aynı isimde sektör eklenemiyor (DB UNIQUE constraint)

### Düzenleme (`/JobSectors/Edit/{id}`)
- [ ] `SectorName` güncellenebiliyor

### Silme (`/JobSectors/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir
- [ ] Sektöre bağlı şirket varsa silinebilmeli (ders koşulu: ilişkili kayıt olsa dahi silinmeli) — bu durumda `Company.JobSectorId` NULL olur veya önce şirketler silinir. `FK_Company_JobSector` için NO ACTION → uyarı gösterebilirsin.

---

## 2.6 Company

### Listeleme (`/Companies/Index`)
- [ ] Kolonlar: `Id`, `CompanyName`, `Owner Email` (join), `SectorName` (join), `UpdatedAt`
- [ ] Her satırda Edit / Delete

### Oluşturma (`/Companies/Create`)
- [ ] `CompanyOwnerId` → **dropdown** (CompanyOwnerUser listesi, Email ile göster)
- [ ] `JobSectorId` → **dropdown** (JobSector listesi, SectorName ile göster)
- [ ] Alanlar: `CompanyName`, `CompanyOwnerId` (dropdown), `JobSectorId` (dropdown)

### Düzenleme (`/Companies/Edit/{id}`)
- [ ] Tüm alanlar güncellenebiliyor
- [ ] dropdown'lar form açıldığında mevcut değeri seçili gösteriyor

### Silme (`/Companies/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir
- [ ] Silindiğinde CASCADE FK ile bağlı `JobPosting`ler silinir

---

## 2.7 JobPosting (Weak Entity)

### Listeleme (`/JobPostings/Index`)
- [ ] Kolonlar: `Id`, `Title`, `CompanyName` (join), `CreatedAt`
- [ ] Her satırda Edit / Delete / Details

### Oluşturma (`/JobPostings/Create`)
- [ ] `CompanyId` → **dropdown** (Company listesi, CompanyName ile göster)
- [ ] Alanlar: `Title`, `Description`, `CompanyId` (dropdown)

### Düzenleme (`/JobPostings/Edit/{id}`)
- [ ] `Title` ve `Description` güncellenebiliyor
- [ ] `CompanyId` dropdown ile değiştirilebiliyor

### Silme (`/JobPostings/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir
- [ ] Trigger (`trg_JobPosting_CascadeDeleteApplications`) çalışır → bağlı `JobApplication`lar silinir

---

## 2.8 Skill

### Listeleme (`/Skills/Index`)
- [ ] Kolonlar: `Id`, `SkillName`, `CreatedAt`

### Oluşturma (`/Skills/Create`)
- [ ] Alan: `SkillName`

### Düzenleme (`/Skills/Edit/{id}`)
- [ ] `SkillName` güncellenebiliyor

### Silme (`/Skills/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir; bağlı `CandidateSkills` CASCADE ile silinir

---

## 2.9 CandidateSkills (M:N Association)

### Listeleme (`/CandidateSkills/Index`)
- [ ] Kolonlar: `Id`, `Candidate Email` (join), `SkillName` (join), `ProficiencyLevel`

### Oluşturma (`/CandidateSkills/Create`)
- [ ] `CandidateId` → **dropdown** (CandidateUser listesi, Email ile göster)
- [ ] `SkillId` → **dropdown** (Skill listesi)
- [ ] `ProficiencyLevel` → **dropdown** seçenekleri: `Beginner`, `Intermediate`, `Advanced`, `Expert`

### Düzenleme (`/CandidateSkills/Edit/{id}`)
- [ ] `ProficiencyLevel` değiştirilebiliyor (dropdown)

### Silme (`/CandidateSkills/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir

---

## 2.10 ForeignLanguage

### Listeleme (`/ForeignLanguages/Index`)
- [ ] Kolonlar: `Id`, `LanguageName`, `CreatedAt`

### Oluşturma (`/ForeignLanguages/Create`)
- [ ] Alan: `LanguageName`

### Düzenleme (`/ForeignLanguages/Edit/{id}`)
- [ ] `LanguageName` güncellenebiliyor

### Silme (`/ForeignLanguages/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir; bağlı `CandidateForeignLanguages` CASCADE ile silinir

---

## 2.11 CandidateForeignLanguages (M:N Association)

### Listeleme (`/CandidateForeignLanguages/Index`)
- [ ] Kolonlar: `Id`, `Candidate Email` (join), `LanguageName` (join), `ProficiencyLevel`

### Oluşturma (`/CandidateForeignLanguages/Create`)
- [ ] `CandidateId` → **dropdown** (CandidateUser, Email ile göster)
- [ ] `ForeignLanguageId` → **dropdown** (ForeignLanguage listesi)
- [ ] `ProficiencyLevel` → **dropdown** seçenekleri: `A1`, `A2`, `B1`, `B2`, `C1`, `C2`

### Düzenleme (`/CandidateForeignLanguages/Edit/{id}`)
- [ ] `ProficiencyLevel` değiştirilebiliyor

### Silme (`/CandidateForeignLanguages/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir

---

## 2.12 JobApplication (Aggregation)

### Listeleme (`/JobApplications/Index`)
- [ ] Kolonlar: `Id`, `Candidate Email` (join), `Job Title` (join), `ApplicationStatus`, `CreatedAt`

### Oluşturma (`/JobApplications/Create`)
- [ ] `CandidateId` → **dropdown** (CandidateUser, Email ile göster)
- [ ] `JobPostingId` → **dropdown** (JobPosting listesi, Title ile göster)
- [ ] `ApplicationStatus` → **dropdown**: `Pending`, `In Review`, `Accepted`, `Rejected`
- [ ] **Benzersizlik kontrolü:** Aynı aday aynı ilana ikinci kez başvuramaz (DB UNIQUE constraint — hata mesajı göster)

### Düzenleme (`/JobApplications/Edit/{id}`)
- [ ] `ApplicationStatus` değiştirilebiliyor (dropdown)
- [ ] `CandidateId` ve `JobPostingId` readonly

### Silme (`/JobApplications/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir; CASCADE FK ile bağlı `Interviews` silinir

---

## 2.13 Interviews (Aggregation Bağlantısı — State Machine)

### Listeleme (`/Interviews/Index`)
- [ ] Kolonlar: `Id`, `Application` (Candidate + Job, join), `Interviewer` (Email, join), `ScheduledDate`, `Status`, `Score`

### Oluşturma (`/Interviews/Create`)
- [ ] `ApplicationId` → **dropdown** (JobApplication listesi — Candidate Email + Job Title formatında göster)
- [ ] `InterviewerId` → **dropdown** (InterviewerUser listesi, Email + Title ile göster)
- [ ] `ScheduledDate` — date/datetime picker
- [ ] `Status` → **dropdown**: `Scheduled`, `Completed`, `Cancelled`
- [ ] `Score` — opsiyonel sayısal alan (0–100)
- [ ] `Notes` — opsiyonel metin alanı

### Düzenleme (`/Interviews/Edit/{id}`)
- [ ] `Status` dropdown ile güncellenebiliyor (State Machine: Scheduled → Completed / Cancelled)
- [ ] `Score` ve `Notes` güncellenebiliyor
- [ ] `ScheduledDate` güncellenebiliyor

### Silme (`/Interviews/Delete/{id}`)
- [ ] Silme butonu `onclick="return confirm('Bu kaydı silmek istediğinize emin misiniz?')"` ile tetiklenir

---

## 2.14 Kayıt Ekranları (Registration)

> Üç rol için kullanıcı dostu kayıt sayfaları. Her biri tek form submit'inde hem `User` hem ilgili sub-type kaydını oluşturur.

### Aday Kaydı (`/Register/Candidate`)
- [ ] **ViewModel:** `RegisterCandidateViewModel`
  - `Email` (zorunlu)
  - `Password` (zorunlu)
  - `ResumeUrl` (opsiyonel)
  - `GitHubProfile` (opsiyonel)
- [ ] Controller action `[HttpPost]`:
  1. Önce `User` kaydı oluştur (Email, PasswordHash)
  2. `SCOPE_IDENTITY()` ile dönen `Id`'yi `CandidateUser.UserId` olarak kullan
  3. `CandidateUser` kaydını oluştur
  4. Başarıda `/CandidateUsers/Index`'e yönlendir
- [ ] E-posta zaten kayıtlıysa hata mesajı göster

### Şirket Sahibi Kaydı (`/Register/CompanyOwner`)
- [ ] **ViewModel:** `RegisterCompanyOwnerViewModel`
  - `Email` (zorunlu)
  - `Password` (zorunlu)
  - `VerificationTaxNumber` (zorunlu)
- [ ] Controller action `[HttpPost]`:
  1. `User` kaydı oluştur
  2. `CompanyOwnerUser` kaydı oluştur
  3. Başarıda `/CompanyOwnerUsers/Index`'e yönlendir
- [ ] E-posta zaten kayıtlıysa hata mesajı göster

### Mülakatçı Kaydı (`/Register/Interviewer`)
- [ ] **ViewModel:** `RegisterInterviewerViewModel`
  - `Email` (zorunlu)
  - `Password` (zorunlu)
  - `Department` (zorunlu)
  - `Title` (zorunlu)
- [ ] Controller action `[HttpPost]`:
  1. `User` kaydı oluştur
  2. `InterviewerUser` kaydı oluştur
  3. Başarıda `/InterviewerUsers/Index`'e yönlendir
- [ ] E-posta zaten kayıtlıysa hata mesajı göster

### Kayıt Sayfaları Nav Linki
- [ ] `_Layout.cshtml`'de "Kayıt Ol" dropdown menüsü eklendi: Aday / Şirket Sahibi / Mülakatçı
