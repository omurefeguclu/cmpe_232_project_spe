# 04 — Ana Sayfa İstatistik Grafikleri

> **Ders Zorunluluğu:** Home page'de veritabanıyla ilgili istatistik grafikleri olmalı.  
> ASP.NET MVC'de Razor View + Chart.js (CDN) veya Google Charts kullanılabilir.  
> Veriler Controller'dan **concrete ViewModel** ile geçirilir (`ViewBag` kullanılmaz).

---

## 4.1 Zorunlu İstatistikler

### STAT-1: Rol Bazlı Kullanıcı Sayıları
- [ ] Grafik türü: **Bar Chart** veya **Pie Chart**
- [ ] Gösterilecek veriler:
  - Toplam `CandidateUser` sayısı
  - Toplam `CompanyOwnerUser` sayısı
  - Toplam `InterviewerUser` sayısı
- [ ] `HomeViewModel.CandidateCount`, `.CompanyOwnerCount`, `.InterviewerCount` alanları kullanılır

### STAT-2: Başvuru Durumu Dağılımı
- [ ] Grafik türü: **Pie Chart** veya **Doughnut Chart**
- [ ] Gösterilecek veriler: Pending / In Review / Accepted / Rejected sayıları
- [ ] `HomeViewModel.ApplicationStatusStats` (`List<StatusCountItem>`) alanı kullanılır

### STAT-3: Mülakat Durumu Dağılımı
- [ ] Grafik türü: **Bar Chart**
- [ ] Gösterilecek veriler: Scheduled / Completed / Cancelled sayıları
- [ ] `HomeViewModel.InterviewStatusStats` (`List<StatusCountItem>`) alanı kullanılır

### STAT-4: Sektör Bazlı İlan Sayıları
- [ ] Grafik türü: **Bar Chart**
- [ ] Gösterilecek veriler: Her sektördeki aktif ilan sayısı
- [ ] `HomeViewModel.PostingsBySector` (`List<StatusCountItem>`) alanı kullanılır

### STAT-5: Toplam Sayılar (Dashboard Kartları)
- [ ] Kart: Toplam İlan Sayısı — `HomeViewModel.TotalPostings`
- [ ] Kart: Toplam Başvuru Sayısı — `HomeViewModel.TotalApplications`
- [ ] Kart: Toplam Mülakat Sayısı — `HomeViewModel.TotalInterviews`
- [ ] Bu sayılar grafik üstünde büyük rakam olarak gösterilir

---

## 4.2 ViewModel Tanımı

`Models/ViewModels/HomeViewModel.cs` dosyası oluşturulacak:

```csharp
// Models/ViewModels/StatusCountItem.cs
public class StatusCountItem
{
    public string Label { get; set; }
    public int Count { get; set; }
}

// Models/ViewModels/HomeViewModel.cs
public class HomeViewModel
{
    // Dashboard kartları
    public int CandidateCount { get; set; }
    public int CompanyOwnerCount { get; set; }
    public int InterviewerCount { get; set; }
    public int TotalPostings { get; set; }
    public int TotalApplications { get; set; }
    public int TotalInterviews { get; set; }

    // Grafik verileri
    public List<StatusCountItem> ApplicationStatusStats { get; set; }
    public List<StatusCountItem> InterviewStatusStats { get; set; }
    public List<StatusCountItem> PostingsBySector { get; set; }
}
```

- [ ] `StatusCountItem` sınıfı oluşturuldu
- [ ] `HomeViewModel` sınıfı oluşturuldu

---

## 4.3 Controller & View Entegrasyonu

### Chart.js Kurulum
- [ ] `_Layout.cshtml`'e CDN eklendi:
  ```html
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  ```

### `HomeController.cs` — `Index()` Action
```csharp
public ActionResult Index()
{
    using (var context = new RecruitmentDBEntities())
    {
        var vm = new HomeViewModel
        {
            CandidateCount    = context.CandidateUser.Count(),
            CompanyOwnerCount = context.CompanyOwnerUser.Count(),
            InterviewerCount  = context.InterviewerUser.Count(),
            TotalPostings     = context.JobPosting.Count(),
            TotalApplications = context.JobApplication.Count(),
            TotalInterviews   = context.Interviews.Count(),

            ApplicationStatusStats = context.JobApplication
                .GroupBy(a => a.ApplicationStatus)
                .Select(g => new StatusCountItem { Label = g.Key, Count = g.Count() })
                .ToList(),

            InterviewStatusStats = context.Interviews
                .GroupBy(i => i.Status)
                .Select(g => new StatusCountItem { Label = g.Key, Count = g.Count() })
                .ToList(),

            PostingsBySector = context.JobPosting
                .GroupBy(jp => jp.Company.JobSector.SectorName)
                .Select(g => new StatusCountItem { Label = g.Key, Count = g.Count() })
                .ToList()
        };
        return View(vm);
    }
}
```
- [ ] Controller'da `HomeViewModel` dolduruluyor ve `View(vm)` ile gönderiliyor

### `Views/Home/Index.cshtml` — View Başlığı
```csharp
@model IaaSPlatform.Models.ViewModels.HomeViewModel
```
- [ ] View'ın en üstünde `@model` direktifi var
- [ ] Model alanlarına `@Model.CandidateCount` şeklinde erişiliyor
- [ ] Chart.js için JSON dönüşümü:
  ```javascript
  var labels = @Html.Raw(Json.Encode(Model.ApplicationStatusStats.Select(x => x.Label)));
  var data   = @Html.Raw(Json.Encode(Model.ApplicationStatusStats.Select(x => x.Count)));
  ```
- [ ] Canvas elementleri ve Chart.js kodu mevcut
