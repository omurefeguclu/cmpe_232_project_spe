# Proje Tanımı: Interview-as-a-Service (IaaS) Platformu

## 1. Projenin Vizyonu ve Kapsamı

Bu proje, işe alım süreçlerinde devrim yaratarak **bağımsız İnsan Kaynakları (İK) profesyonellerini** yetenek arayışında olan **şirketlerle** buluşturan yenilikçi bir **Interview-as-a-Service (Hizmet olarak Mülakat)** uygulamasıdır.

Şirketler, platform üzerinden iş ilanları yayınlayarak başvuru toplayabilir ve bu başvuruların teknik veya İK mülakatlarını platformdaki bağımsız mülakatçı uzmanlarına devredebilir. Böylece şirketler operasyonel yükten kurtulurken, adaylar alanında uzman bağımsız kişiler tarafından adil ve şeffaf bir şekilde değerlendirilir.

---

## 2. Kullanıcı Rolleri ve Hiyerarşisi

Projede gelişmiş bir **TPT (Table-Per-Type) Mapping** kullanılarak kullanıcılar hiyerarşik bir veritabanı mimarisiyle tasarlanmıştır. Tüm kullanıcılar **`User`** üst sınıfını (Super-type) miras alır.

| Alt Sınıf (Sub-type) | Açıklama | Özel Nitelikler |
|---|---|---|
| **👩‍💼 InterviewerUser** | Şirketlerin yönlendirdiği adaylarla mülakat gerçekleştiren, belirli alanlarda uzmanlaşmış bağımsız İK profesyonelleri | `Department`, `Title` |
| **🏢 CompanyOwnerUser** | Şirketi platformda temsil eden, ilan yayınlama yetkisine sahip doğrulanmış yetkililer | `VerificationTaxNumber` |
| **👨‍💻 CandidateUser** | Platformdaki ilanlara başvuran ve mülakat süreçlerine dahil olan yetenekler | `ResumeUrl`, `GitHubProfile` |

---

## 3. Temel Varlıklar ve İlişkiler

### Şirket ve Sektör Yapısı
- **JobSector:** İş sektörlerini tanımlayan bağımsız bir varlıktır (Teknoloji, Finans, Sağlık vb.). Her şirket bir sektöre bağlıdır.
- **Company:** Şirket sahiplerinin kontrolündeki firmalardır. Bir sektöre ait olup, altında birden fazla iş ilanı barındırabilir.

### İş İlanları
- **JobPosting (Weak Entity):** Şirketlerin yetenek arayışı için yayınladığı pozisyonlardır. Bir şirket olmadan var olamaz, bu yüzden **Zayıf Varlık** olarak modellenmiştir.

### Aday Profil Zenginleştirme
- **Skill:** Sistemde tanımlı teknik ve profesyonel yeteneklerdir (Java, SQL, React, Proje Yönetimi vb.).
- **CandidateSkills (Aggregation):** Aday ile Yetenek arasındaki M:N ilişkiyi çözen ara tablodur. Adayın her yetenek için sahip olduğu seviyeyi (`ProficiencyLevel`: Beginner → Expert) kaydeder.
- **ForeignLanguage:** Sistemde tanımlı yabancı diller tablosudur (İngilizce, Almanca, Fransızca vb.).
- **CandidateForeignLanguages (Aggregation):** Aday ile Yabancı Dil arasındaki M:N ilişkiyi çözen ara tablodur. Adayın her dildeki yetkinlik seviyesini (`ProficiencyLevel`: A1 → C2) kaydeder.

---

## 4. Başvuru ve Mülakat Süreci

### İş Başvurusu (JobApplication — Weak Entity + Aggregation)
Bir aday (`CandidateUser`) ile bir iş ilanı (`JobPosting`) arasındaki M:N ilişkiyi anlamlı bir iş sürecine dönüştüren ara tablodur. Benzersizlik kuralı sayesinde bir aday aynı ilana sadece bir kez başvurabilir. Durum takibi `ApplicationStatus` üzerinden yapılır (*Pending*, *In Review*, *Accepted*, *Rejected*).

### Mülakat Değerlendirmesi (Interviews — Aggregation)
Projenin kalbini oluşturan bu yapı, **JobApplication** (başvuru) ile **InterviewerUser** (mülakatçı) arasındaki M:N ilişkiyi çözen bir Aggregation tablosudur. Bir Durum Makinesi (State Machine) mantığıyla (*Scheduled → Completed / Cancelled*) ilerler. Mülakatçı, `Score` ve `Notes` alanlarıyla adaya dair değerlendirmesini kaydeder. `ScheduledDate` ise ilişkinin kendi attribute'udur.

---

## 5. Veritabanı Karmaşık Yapılar Özeti

| Karmaşık Yapı | Tablo(lar) |
|---|---|
| **Concept Hierarchy (Super-type / Sub-type)** | `User` → `CandidateUser`, `CompanyOwnerUser`, `InterviewerUser` |
| **Weak Entity** | `JobPosting` (Company'ye bağımlı), `JobApplication` |
| **Aggregation** | `CandidateSkills`, `CandidateForeignLanguages`, `JobApplication` |
| **Aggregation** | `Interviews` (JobApplication + InterviewerUser arasında M:N) |
| **Entity** | `JobSector`, `Skill`, `ForeignLanguage`, `Company` |

---

## 6. Veritabanı Mekanikleri

- **Referential Integrity:** `ON DELETE CASCADE` yapıları sayesinde, üst kayıt silindiğinde bağımlı kayıtlar da otomatik olarak temizlenir. MSSQL'in Multiple Cascade Path kısıtlaması nedeniyle `Interviews.InterviewerId` referansında CASCADE kullanılmamıştır.
- **Otomatik Zaman Damgaları (Triggers):** Tüm ana tablolarda ve alt sınıf tablolarında tanımlanan SQL Trigger'ları, `UpdatedAt` alanını veritabanı seviyesinde otomatik günceller. Alt sınıf tabloları güncellendiğinde üst sınıf `User` tablosunun da `UpdatedAt` alanı güncellenir.
- **Benzersizlik Kuralları (Unique Constraints):** Aynı adayın aynı ilana, aynı yeteneğe veya aynı dile birden fazla kayıt oluşturması engellenmiştir.
