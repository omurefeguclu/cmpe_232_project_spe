# 03 — İş Süreci: Başvuru & Mülakat Akışı

> Bu sayfa, projenin ana iş akışını (business flow) özetler.  
> CRUD sayfaları bunları implicitly destekler; buradaki gereksinimler **state machine** ve **veri tutarlılığı** açısından önemlidir.

---

## 3.1 Başvuru Süreci

### BR-31: Aday Başvurusu Oluşturma
- [ ] Bir `CandidateUser`, herhangi bir `JobPosting`'e başvurabilir
- [ ] Aynı `CandidateId` + `JobPostingId` kombinasyonu için ikinci başvuru **engellenmelidir**
  - DB'de `UNIQUE CONSTRAINT (CandidateId, JobPostingId)` zaten var
  - Uygulama katmanında try-catch ile anlamlı hata mesajı gösterilmeli: *"Bu aday bu ilana zaten başvurmuş."*
- [ ] Yeni başvurunun `ApplicationStatus`'u default olarak `Pending` gelir

### BR-32: Başvuru Durumu Güncelleme
- [ ] `ApplicationStatus` yalnızca şu değerleri alabilir: `Pending`, `In Review`, `Accepted`, `Rejected`
- [ ] Edit sayfasında bu değerler **dropdown** ile seçilir
- [ ] Herhangi bir durumdan herhangi bir duruma geçiş serbesttir (sunum için yeterlidir)

### BR-33: Başvuruya Bağlı Mülakat Sayısı (Türetilmiş Bilgi)
- [ ] JobApplication detay sayfasında (`/JobApplications/Details/{id}`) o başvuruya ait mülakat listesi gösterilir
- [ ] Bu liste için LINQ: `context.Interviews.Where(i => i.ApplicationId == id).ToList()`

---

## 3.2 Mülakat Süreci (State Machine)

### BR-34: Mülakat Oluşturma
- [ ] Bir `Interviews` kaydı yalnızca mevcut bir `JobApplication`'a bağlı oluşturulabilir
- [ ] `InterviewerId` mevcut bir `InterviewerUser`'dan seçilir (dropdown)
- [ ] `ScheduledDate` gelecekteki bir tarih olmalı (opsiyonel validasyon)
- [ ] Yeni oluşturulan mülakatın `Status`'u default `Scheduled`

### BR-35: Mülakat Durumu State Machine
- [ ] `Status` değerleri: `Scheduled` → `Completed` veya `Cancelled`
- [ ] `Completed` durumuna geçildiğinde `Score` (0–100) ve `Notes` girilebilir
- [ ] `Cancelled` durumundaki bir mülakat tekrar `Scheduled`'a alınabilir (sunum için yeterli)

### BR-36: Mülakatçı Silme Engeli
- [ ] Bir `InterviewerUser`'ın bağlı `Interviews` kaydı varsa, silinmeden önce uyarı verilmeli
- [ ] Uygulama, silmeden önce `context.Interviews.Any(i => i.InterviewerId == userId)` ile kontrol yapar
- [ ] Eğer bağlı mülakat varsa hata mesajı: *"Bu mülakatçıya atanmış mülakatlar bulunuyor. Önce mülakatları silin."*

---

## 3.3 Cascade Delete Kuralları

| Silinen Entity | Otomatik Silinen Entity'ler | Mekanizma |
|---|---|---|
| `User` | `CandidateUser`, `CompanyOwnerUser`, `InterviewerUser` | FK CASCADE |
| `CandidateUser` | `JobApplication`, `CandidateSkills`, `CandidateForeignLanguages` | FK CASCADE |
| `CompanyOwnerUser` | `Company` | FK CASCADE |
| `Company` | `JobPosting` | FK CASCADE |
| `JobPosting` | `JobApplication` | **Trigger** (`trg_JobPosting_CascadeDeleteApplications`) |
| `JobApplication` | `Interviews` | FK CASCADE |
| `Skill` | `CandidateSkills` | FK CASCADE |
| `ForeignLanguage` | `CandidateForeignLanguages` | FK CASCADE |
| `InterviewerUser` | ❌ Interviews silinmez (NO ACTION FK) | Manuel kontrol gerekli |

- [ ] Yukarıdaki tüm cascade senaryoları uygulamada test edildi

---

## 3.4 Türetilmiş Nitelikler (Derived Attributes) ve ViewModel'ler

> Projede veritabanında fiziksel olarak tutulmayan fakat iş akışında (`Business Flow`) gösterilmesi gereken **Derived Attribute**'lar mevcuttur. Raporlamalarda veya ekran detaylarında bu hesaplamaları View'a `ViewBag` yerine **ViewModel** kalıbı kullanarak göndermek best practice'tir.

### BR-37: JobPosting Detayında ApplicationCount
- [ ] `JobPostingViewModel` oluşturulacak.
- [ ] İçerisinde ilanın verilerine ek olarak `public int ApplicationCount { get; set; }` alanı yer alacak.
- [ ] Controller'da bu değer doğrudan Entity'nin (örn: `posting`) navigation property'si üzerinden hesaplanacak: `ApplicationCount = posting.JobApplications.Count`
- [ ] İlan detay sayfasında (`/JobPostings/Details/{id}`) "Bu ilana X kişi başvurdu" şeklinde gösterilecek.

### BR-38: JobApplication Detayında AverageScore
- [ ] `JobApplicationViewModel` oluşturulacak.
- [ ] İçerisinde başvurunun verilerine ek olarak `public double? AverageScore { get; set; }` alanı yer alacak.
- [ ] Controller'da bu değer navigation property üzerinden mülakat sonuçlarından (`Interviews`) hesaplanacak: `AverageScore = application.Interviews.Where(i => i.Score != null).Average(i => (double?)i.Score)`
- [ ] Başvuru detay sayfasında (`/JobApplications/Details/{id}`) "Adayın Ortalama Mülakat Skoru: Y" şeklinde gösterilecek.
