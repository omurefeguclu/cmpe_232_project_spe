# 01 — Proje Kurulum & Altyapı

## ✅ Requirement Checklist

### 1.1 Veritabanı Kurulumu
- [ ] MSSQL 2022 Developer Edition kurulu ve çalışıyor
- [ ] SQL Server Management Studio (SSMS) ile bağlantı sağlandı
- [ ] `database.sql` scripti başarıyla çalıştırıldı (tüm tablolar + trigger'lar oluştu)
- [ ] `RecruitmentDB` veritabanı SSMS'de görünüyor
- [ ] Aşağıdaki tüm tablolar oluşturuluğunu doğrulandı:
  - [ ] `[User]`
  - [ ] `CandidateUser`
  - [ ] `CompanyOwnerUser`
  - [ ] `InterviewerUser`
  - [ ] `JobSector`
  - [ ] `Company`
  - [ ] `JobPosting`
  - [ ] `Skill`
  - [ ] `CandidateSkills`
  - [ ] `ForeignLanguage`
  - [ ] `CandidateForeignLanguages`
  - [ ] `JobApplication`
  - [ ] `Interviews`

### 1.2 Çok Katmanlı .NET Proje Mimarisi Kurulumu

> **Mimarisi:** Data katmanı EF6 EDMX desteklemesi için **.NET Framework 4.8** olarak mevcuttur. İş mantığı (Business) ve Sunum (Web) katmanı **.NET 10** tabanlı olarak sıfırdan geliştirilecektir.

#### Data Katmanı (Mevcut — .NET 4.8)
- [x] Class Library (.NET Framework 4.8) projesi oluşturulmuş
- [x] Entity Framework 6.x NuGet paketi projede mevcut
- [x] **Database-First** EDMX oluşturulmuş ve `RecruitmentDB` tablolarını içeriyor
- [x] `.edmx` dosyası projede bulunuyor (Ders zorunluluğu)

#### Business & Web Katmanları (Yeni — .NET 10)
- [ ] Yeni **.NET 10 Class Library** oluşturuldu (Business Layer)
- [ ] Yeni **.NET 10 ASP.NET MVC (veya Web API + Razor Pages vb.)** projesi oluşturuldu (Web Layer)
- [ ] Web projesi Business projesini referans (Project Reference) olarak aldı
- [ ] Business ve Web projelerinin `.csproj` dosyalarında Data katmanı ile haberleşebilmek için uygun COM/Shim referansları veya servis/API yapılandırması tasarlandı
- [ ] SQL Connection string, Web projesinin `appsettings.json` veya `web.config` (mimari tercihe göre) dosyasında doğru yapılandırıldı
- [ ] Tüm solution build alıyor (Build → No Error)

### 1.3 Seed Data (Opsiyonel ama Sunum için Önemli)
- [ ] En az 3 `JobSector` kaydı eklendi (Teknoloji, Finans, Sağlık gibi)
- [ ] En az 5 `Skill` kaydı eklendi (Java, SQL, React, Python, Project Management gibi)
- [ ] En az 3 `ForeignLanguage` kaydı eklendi (İngilizce, Almanca, Fransızca gibi)
- [ ] En az 2 `User` + `CompanyOwnerUser` çifti eklendi
- [ ] En az 2 `User` + `CandidateUser` çifti eklendi
- [ ] En az 1 `User` + `InterviewerUser` çifti eklendi
- [ ] En az 2 `Company` kaydı eklendi
- [ ] En az 3 `JobPosting` kaydı eklendi
- [ ] En az 2 `JobApplication` kaydı eklendi
- [ ] En az 1 `Interviews` kaydı eklendi
