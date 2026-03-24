# 05 — LINQ Sorguları Zorunlulukları

> **Ders Zorunluluğu:** `Create, Update, Select, Insert, Delete, Aggregation (Group By, Exists…)` operasyonları LINQ ile uygulanmalı.  
> EF + LINQ ile DB'ye erişim zorunlu — raw SQL yazmak yeterli değil.  
> `Include` çağrılarında string yerine **lambda expression** kullanılır (strongly-typed). Bunun için `using System.Data.Entity;` gereklidir.

---

## 5.1 SELECT (Listeleme)

- [ ] Tüm CRUD listelerinde kullanılıyor
- [ ] Örnek — Tüm ilanları şirket adıyla birlikte listele:
  ```csharp
  // Controller: JobPostingsController.cs -> Index()
  // using System.Data.Entity; // lambda Include için gerekli
  var postings = context.JobPosting
      .Include(jp => jp.Company)
      .ToList();
  ```
- [ ] En az 1 yerde **navigation property** ile ilişkili entity çekiliyor (`Include` / `.Company`, `.JobSector` gibi)

## 5.2 INSERT (Create)

- [ ] Tüm Create sayfalarında kullanılıyor
- [ ] Örnek:
  ```csharp
  var posting = new JobPosting { CompanyId = model.CompanyId, Title = model.Title, ... };
  context.JobPosting.Add(posting);
  context.SaveChanges();
  ```
- [ ] `SaveChanges()` çağrısı her create işleminde mevcut

## 5.3 UPDATE (Edit)

- [ ] Tüm Edit sayfalarında kullanılıyor
- [ ] Örnek:
  ```csharp
  var entity = context.JobPosting.Find(id);
  entity.Title = model.Title;
  context.SaveChanges();
  ```
- [ ] `UpdatedAt` trigger tarafından otomatik güncelleniyor (uygulama seviyesinde set etmeye gerek yok)

## 5.4 DELETE

- [ ] Tüm Delete sayfalarında kullanılıyor
- [ ] Örnek:
  ```csharp
  var entity = context.JobPosting.Find(id);
  context.JobPosting.Remove(entity);
  context.SaveChanges();
  ```
- [ ] CASCADE senaryoları DB seviyesinde çözülmüş (trigger + FK CASCADE)

## 5.5 GROUP BY + COUNT (Aggregation)

- [ ] Ana sayfada kullanılıyor (bkz. `04_homepage_stats.md`)
- [ ] Örnek:
  ```csharp
  var sectorStats = context.JobPosting
      .GroupBy(jp => jp.Company.JobSector.SectorName)
      .Select(g => new { Sector = g.Key, Count = g.Count() })
      .ToList();
  ```
- [ ] En az 1 GROUP BY sorgusu uygulamada çalışıyor

## 5.6 AVG (Ortalama Hesaplama)

- [ ] Mülakat listesinde veya detay sayfasında kullanılıyor
- [ ] Örnek — Bir başvurunun ortalama mülakatçı skoru:
  ```csharp
  var avgScore = context.Interviews
      .Where(i => i.ApplicationId == applicationId && i.Score != null)
      .Average(i => (double?)i.Score) ?? 0;
  ```
- [ ] Bu sorgu `JobApplications/Details/{id}` sayfasında kullanılıyor

## 5.7 WHERE + Filtreleme

- [ ] En az 1 yerde filtreli sorgu kullanılıyor
- [ ] Örnek — Belirli statüsteki başvuruları listele:
  ```csharp
  var pending = context.JobApplication
      .Where(a => a.ApplicationStatus == "Pending")
      .ToList();
  ```
- [ ] InterviewerUser kontrol sorgusu:
  ```csharp
  bool hasInterviews = context.Interviews.Any(i => i.InterviewerId == userId);
  ```

## 5.8 EXISTS (Any / All)

- [ ] `InterviewerUser` silinmeden önce mülakatçıya ait bağlı kayıt kontrolü:
  ```csharp
  bool hasPendingInterviews = context.Interviews
      .Any(i => i.InterviewerId == userId);
  if (hasPendingInterviews) { /* hata mesajı */ return; }
  ```
- [ ] Benzersizlik kontrolü (`CandidateSkills` tekrar ekleme önleme):
  ```csharp
  bool alreadyExists = context.CandidateSkills
      .Any(cs => cs.CandidateId == candidateId && cs.SkillId == skillId);
  ```

## 5.9 JOIN (Navigation Properties)

- [ ] ASP.NET MVC'de `Include()` ile eager loading kullanılıyor (`using System.Data.Entity;` eklenmeli)
- [ ] Örnek — Interviews listesi için:
  ```csharp
  var interviews = context.Interviews
      .Include(i => i.JobApplication)
      .Include(i => i.InterviewerUser)
      .Include(i => i.JobApplication.CandidateUser)
      .Include(i => i.JobApplication.JobPosting)
      .ToList();
  ```
- [ ] Liste ekranlarında ilişkili entity bilgileri (Email, CompanyName, SectorName vb.) join ile gösteriliyor

---

## 5.10 Özet Kontrol Tablosu

| LINQ Operasyonu | Kullanıldığı Yer | Durum |
|---|---|---|
| `SELECT / ToList()` | Tüm Index sayfaları | [ ] |
| `INSERT / Add + SaveChanges` | Tüm Create sayfaları | [ ] |
| `UPDATE / Find + SaveChanges` | Tüm Edit sayfaları | [ ] |
| `DELETE / Remove + SaveChanges` | Tüm Delete sayfaları | [ ] |
| `GROUP BY` | HomeController - İstatistikler | [ ] |
| `COUNT()` | HomeController - Dashboard kartları | [ ] |
| `AVG()` | JobApplications Details sayfası | [ ] |
| `WHERE` | Filtreleme / kontrol sorguları | [ ] |
| `ANY (EXISTS)` | InterviewerUser Delete, duplicate check | [ ] |
| `Include (JOIN)` | Tüm liste sayfaları navigation ile | [ ] |
