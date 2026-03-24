# IaaS Platform — Functional Business Requirements Checklist
## CMPE 232 Database Systems — Spring 2026

> **Durum:** `.NET ASP.NET MVC` + `Entity Framework (EDMX)` + `LINQ` + `MSSQL 2022`  
> Her madde tamamlandığında `[ ]` → `[x]` yap.

---

## 📋 Genel Bakış

| # | Konu | Dosya |
|---|------|-------|
| 1 | Proje Kurulum & Altyapı | [01_setup.md](01_setup.md) |
| 2 | Varlık Yönetimi — CRUD Sayfaları | [02_entity_crud.md](02_entity_crud.md) |
| 3 | İş Süreci — Başvuru & Mülakat Akışı | [03_business_flow.md](03_business_flow.md) |
| 4 | Ana Sayfa — İstatistik Grafikleri | [04_homepage_stats.md](04_homepage_stats.md) |
| 5 | Veritabanı Sorguları (LINQ) | [05_linq_queries.md](05_linq_queries.md) |

---

## ✅ Tüm Requirement'ların Özet Listesi

### 🔧 Kurulum & Mimari
- [x] Data Katmanı (.NET 4.8): `RecruitmentDB` oluşturulmuş, EDMX generate edilmiş
- [ ] Business Katmanı (.NET 10): İş mantığı katmanı oluşturulmuş
- [ ] Web Katmanı (.NET 10): ASP.NET MVC/Web API projesi oluşturulmuş
- [ ] Katmanlar arası Entity Framework DbContext entegrasyonu tamamlanmış

### 📄 Her Entity için CRUD Sayfaları
- [ ] **User** — List / Create / Edit / Delete
- [ ] **CandidateUser** — List / Create / Edit / Delete
- [ ] **CompanyOwnerUser** — List / Create / Edit / Delete
- [ ] **InterviewerUser** — List / Create / Edit / Delete
- [ ] **JobSector** — List / Create / Edit / Delete
- [ ] **Company** — List / Create / Edit / Delete
- [ ] **JobPosting** — List / Create / Edit / Delete
- [ ] **Skill** — List / Create / Edit / Delete
- [ ] **CandidateSkills** — List / Create / Edit / Delete
- [ ] **ForeignLanguage** — List / Create / Edit / Delete
- [ ] **CandidateForeignLanguages** — List / Create / Edit / Delete
- [ ] **JobApplication** — List / Create / Edit / Delete
- [ ] **Interviews** — List / Create / Edit / Delete
- [ ] **Silme Onayı** — Tüm silme butonlarında JS `confirm()` dialogu kullanıldı (ayrı onay sayfası yok)

### 👤 Kullanıcı Kayıt Ekranları (Registration)
- [ ] Aday Kaydı (`/Register/Candidate`) — Tek submit'te `User` + `CandidateUser`
- [ ] Şirket Sahibi Kaydı (`/Register/CompanyOwner`) — Tek submit'te `User` + `CompanyOwnerUser`
- [ ] Mülakatçı Kaydı (`/Register/Interviewer`) — Tek submit'te `User` + `InterviewerUser`

### 🔗 İlişkili Entity'lerde Dropdown Zorunluluğu
- [ ] Company → CompanyOwnerUser seçimi **dropdown** ile
- [ ] Company → JobSector seçimi **dropdown** ile
- [ ] JobPosting → Company seçimi **dropdown** ile
- [ ] CandidateSkills → CandidateUser seçimi **dropdown** ile
- [ ] CandidateSkills → Skill seçimi **dropdown** ile
- [ ] CandidateForeignLanguages → CandidateUser seçimi **dropdown** ile
- [ ] CandidateForeignLanguages → ForeignLanguage seçimi **dropdown** ile
- [ ] JobApplication → CandidateUser seçimi **dropdown** ile
- [ ] JobApplication → JobPosting seçimi **dropdown** ile
- [ ] Interviews → JobApplication seçimi **dropdown** ile
- [ ] Interviews → InterviewerUser seçimi **dropdown** ile

### 🗑️ Cascade Delete & Mülakat Akışı
- [ ] Company silindiğinde → bağlı JobPosting'ler silinir (trigger ile)
- [ ] User silindiğinde → bağlı sub-type kayıtları silinir (CASCADE FK)
- [ ] JobApplication silindiğinde → bağlı Interviews silinir (CASCADE FK)
- [ ] **Türetilmiş Alan:** `JobPostingViewModel` oluşturuldu, `ApplicationCount` hesaplanıp detay sayfasında gösteriliyor
- [ ] **Türetilmiş Alan:** `JobApplicationViewModel` oluşturuldu, `AverageScore` (mülakat ortalaması) detay sayfasında gösteriliyor

### 📊 Ana Sayfa İstatistikleri
- [ ] Toplam kullanıcı sayısı (rol bazlı)
- [ ] Toplam aktif iş ilanı sayısı
- [ ] Toplam başvuru sayısı (statüs bazlı dağılım)
- [ ] Toplam mülakat sayısı (statüs bazlı dağılım)
- [ ] En çok başvurulan sektörler (GROUP BY + COUNT)
- [ ] En yüksek ortalama skor alan ilk 5 ilan

### 🔍 LINQ Sorguları (Ders Zorunluluğu)
- [ ] SELECT ile listeleme (tüm CRUD'larda kullanılıyor)
- [ ] INSERT (Create işlemleri)
- [ ] UPDATE (Edit işlemleri)
- [ ] DELETE (Delete işlemleri)
- [ ] GROUP BY + COUNT (istatistik sayfası)
- [ ] AVG (mülakat skorları)
- [ ] WHERE + EXISTS (filtreleme)
- [ ] JOIN / Include (ilişkili entity navigation)
- [ ] AGGREGATION (istatistik grafikleri)
