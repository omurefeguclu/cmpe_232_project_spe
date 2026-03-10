# ER Diyagramı Çizim Rehberi (draw.io)

Bu rehber, `database.sql` dosyasındaki tabloları **ER (Entity-Relationship) diyagramına** dönüştürmek için adım adım bir kılavuzdur. ER bilginiz sıfır olsa bile bu adımları takip ederek diyagramı çizebilirsiniz.

---

## Ön Bilgi: ER Diyagramında Kullanılan Şekiller

Diyagramda 5 temel şekil kullanacaksınız. Bunları draw.io'da sol paneldeki **General** kategorisinden bulabilirsiniz:

| Şekil | Ne İçin Kullanılır | draw.io Karşılığı |
|---|---|---|
| **Dikdörtgen** | Normal Entity (Varlık) | `Rectangle` |
| **Çift Kenarlı Dikdörtgen** | Weak Entity (Zayıf Varlık) | İç içe 2 `Rectangle` (biri küçük biri büyük) |
| **Elips (Oval)** | Attribute (Özellik/Alan) | `Ellipse` |
| **Baklava Dilimi (Eşkenar Dörtgen)** | Relationship (İlişki) | `Diamond` |
| **Üçgen** | Concept Hierarchy (ISA / Miras) | `Triangle` |

### Attribute (Özellik) Çeşitleri
- **Normal attribute:** Düz kenarlı elips → `Ellipse`
- **Primary Key (PK):** Elips içindeki yazının **altı çizili** olmalı
- **Multivalued attribute:** Çift kenarlı elips (iç içe 2 elips)
- **Derived attribute:** Kesikli kenarlı elips (dashed border)

---

## ADIM 1: draw.io'yu Açın

1. Tarayıcınızda [draw.io](https://app.diagrams.net/) adresini açın
2. **"Create New Diagram"** → **"Blank Diagram"** seçin
3. Dosya adını `RecruitmentDB_ER_Diagram` yapın

---

## ADIM 2: Concept Hierarchy (User Hiyerarşisi) Çizimi

Bu projede `User` bir **Super-type**, alt sınıflar (`CandidateUser`, `CompanyOwnerUser`, `InterviewerUser`) ise **Sub-type**'tır. Bu yapıyı çizmek için:

### 2.1 — User Entity'si (Üst Sınıf)
1. Bir **dikdörtgen** çizin, içine **User** yazın
2. Etrafına şu attribute elipslerini bağlayın:
   - `Id` (PK — altı çizili)
   - `Email`
   - `PasswordHash`
   - `CreatedAt`
   - `UpdatedAt`

### 2.2 — ISA Üçgeni
1. User dikdörtgeninin **altına** bir **üçgen** çizin
2. Üçgenin içine **ISA** yazın
3. User dikdörtgeninden üçgene bir **çizgi** çekin

### 2.3 — Alt Sınıf Entity'leri
Üçgenin altından 3 ayrı çizgi çekip şu dikdörtgenleri ekleyin:

**CandidateUser:**
- Attribute'lar: `ResumeUrl`, `GitHubProfile`, `CreatedAt`, `UpdatedAt`

**CompanyOwnerUser:**
- Attribute'lar: `VerificationTaxNumber`, `CreatedAt`, `UpdatedAt`

**InterviewerUser:**
- Attribute'lar: `Department`, `Title`, `CreatedAt`, `UpdatedAt`

> **Not:** Alt sınıflarda `UserId` çizilmez çünkü PK üst sınıftan miras alınır. ISA ilişkisi bunu zaten ifade eder.

---

## ADIM 3: Bağımsız Entity'leri Çizin

Her biri için bir **dikdörtgen** çizip attribute elipslerini bağlayın:

### 3.1 — JobSector
- `Id` (PK — altı çizili)
- `SectorName`
- `CreatedAt`

### 3.2 — Skill
- `Id` (PK — altı çizili)
- `SkillName`
- `CreatedAt`

### 3.3 — ForeignLanguage
- `Id` (PK — altı çizili)
- `LanguageName`
- `CreatedAt`

---

## ADIM 4: Company ve JobPosting Entity'lerini Çizin

### 4.1 — Company (Normal Entity)
Bir **dikdörtgen** içine **Company** yazın. Attribute'ları:
- `Id` (PK — altı çizili)
- `CompanyName`
- `CreatedAt`
- `UpdatedAt`

### 4.2 — JobPosting (Weak Entity)
**İç içe iki dikdörtgen** çizin (dış dikdörtgen biraz büyük, iç dikdörtgen biraz küçük). İçine **JobPosting** yazın. Attribute'ları:
- `Id` (PK — altı çizili, **kesikli çizgiyle**)  ← weak entity'nin partial key'i
- `Title`
- `Description`
- `CreatedAt`
- `UpdatedAt`

---

## ADIM 5: İlişkileri (Relationship) Çizin

Her ilişki için bir **baklava dilimi (diamond)** çizin, içine ilişki adını yazın, her iki entity'ye çizgi çekin ve çizgilerin üstüne kardinaliteyi yazın.

### 5.1 — CompanyOwnerUser ↔ Company
```
CompanyOwnerUser ----(1)---- [Owns] ----(N)---- Company
```
- Baklava: **Owns**
- CompanyOwnerUser tarafı: **1**
- Company tarafı: **N**

### 5.2 — JobSector ↔ Company
```
JobSector ----(1)---- [BelongsTo] ----(N)---- Company
```
- Baklava: **BelongsTo**
- JobSector tarafı: **1**
- Company tarafı: **N**

### 5.3 — Company ↔ JobPosting (Weak Entity İlişkisi)
```
Company ====(1)==== [[Posts]] ====(N)==== JobPosting
```
- **Çift kenarlı baklava** (iç içe iki diamond) ve **kalın çizgiler** kullanın → Weak entity ilişkisini gösterir
- Company tarafı: **1**
- JobPosting tarafı: **N**

### 5.4 — CandidateUser ↔ Skill (M:N → Aggregation)
```
CandidateUser ----(M)---- [HasSkill] ----(N)---- Skill
```
- Baklava: **HasSkill**
- Bu bir **aggregation** olduğu için baklavanın etrafına **büyük bir dikdörtgen** daha çizin (baklava + çizgileri kapsayan)
- Baklava'ya `ProficiencyLevel` attribute elipsi bağlayın (ilişkinin kendi attribute'u)

### 5.5 — CandidateUser ↔ ForeignLanguage (M:N → Aggregation)
```
CandidateUser ----(M)---- [Speaks] ----(N)---- ForeignLanguage
```
- Baklava: **Speaks**
- Bu da bir **aggregation** → baklavanın etrafına büyük dikdörtgen çizin
- Baklava'ya `ProficiencyLevel` attribute elipsi bağlayın

### 5.6 — CandidateUser ↔ JobPosting (M:N → Aggregation)
```
CandidateUser ----(M)---- [AppliesTo] ----(N)---- JobPosting
```
- Baklava: **AppliesTo**
- Bu da bir **aggregation** → baklavanın etrafına büyük dikdörtgen çizin
- Bu aggregation'ın kendi attribute'ları:
  - `ApplicationStatus`
  - `CreatedAt`
  - `UpdatedAt`

### 5.7 — JobApplication ↔ InterviewerUser (M:N → Aggregation)
Bu ilişki, bir başvuru sürecine mülakatçı atanmasını temsil eder:

```
JobApplication (AppliesTo aggr.) ----(M)---- [Evaluates] ----(N)---- InterviewerUser
```
- Baklava: **Evaluates**
- Bu bir **aggregation** → baklavanın etrafına büyük dik dörtgen çizin
- JobApplication tarafı: **M**
- InterviewerUser tarafı: **N**
- Baklava'ya şu attribute elipslerini bağlayın:
  - `ScheduledDate`
  - `Status`
  - `Score`
  - `Notes`
  - `CreatedAt`
  - `UpdatedAt`

---

## ADIM 6: Kardinalite Notasyonu

Çizgilerin üzerine yazacağınız sayılar:

| Notasyon | Anlamı |
|---|---|
| **1** | Tam olarak bir tane |
| **N** veya **M** | Birden fazla (çok) |
| **1..N** | En az bir, en fazla çok |

---

## ADIM 7: draw.io İpuçları

### Çift Kenarlı Dikdörtgen (Weak Entity) Nasıl Yapılır
1. Büyük bir `Rectangle` çizin
2. İçine biraz daha küçük bir `Rectangle` daha çizin
3. İkisini de seçip **Group** yapın (`Ctrl+G`)
4. İçteki dikdörtgenin içine entity adını yazın

### Çift Kenarlı Baklava (Weak Relationship) Nasıl Yapılır
1. Büyük bir `Diamond` çizin
2. İçine daha küçük bir `Diamond` çizin
3. Gruplayın

### ISA Üçgeni Nasıl Yapılır
1. Sol panelden `Triangle` şeklini sürükleyin
2. İçine **ISA** yazın
3. Üst köşeden User'a, alt kenardan 3 alt sınıfa çizgi çekin

### Aggregation Dikdörtgeni Nasıl Yapılır
1. Önce M:N ilişkisini normal çizin (2 entity + baklava + çizgiler)
2. Sonra baklavanın ve ona bağlı çizgilerin **tamamını kapsayan** büyük bir dikdörtgen çizin
3. Bu dikdörtgeni **arka plana gönderin**: Sağ tık → **Edit Style** → `fillColor=none` yazarak sadece kenarlık kalmasını sağlayın

### Altı Çizili Yazı (Primary Key) Nasıl Yapılır
1. Elipsin içine PK adını yazın
2. Yazıyı seçin → **Format** panelinde **Underline (U)** butonuna tıklayın

---

## ADIM 8: Önerilen Yerleşim Düzeni

Diyagramın okunabilir olması için şu düzen önerilir:

```
                    [User]
                      |
                    [ISA]
                   /  |  \
     [CandidateUser] [CompanyOwnerUser] [InterviewerUser]
           |                |                    |
     [HasSkill]          [Owns]            [Evaluates]
     [Speaks]              |                    |
     [AppliesTo]       [Company]          (Ternary'ye)
           \             /    \
            \           /      \
         [JobPosting] [JobSector]
              |
         [AppliesTo] ← aggregation
              |
         [Evaluates] ← ternary relationship
```

> **İpucu:** Entity'leri önce kabaca yukarıdaki düzene göre yerleştirin, sonra ilişkileri çizin. En son attribute'ları ekleyin. Böylece daha düzenli olur.

---

## Özet: Tablo → ER Şekil Eşleşmesi

| SQL Tablosu | ER Şekli | Yapı Türü |
|---|---|---|
| `User` | Dikdörtgen + ISA üçgeni | Concept Hierarchy (Super-type) |
| `CandidateUser` | Dikdörtgen (ISA altında) | Concept Hierarchy (Sub-type) |
| `CompanyOwnerUser` | Dikdörtgen (ISA altında) | Concept Hierarchy (Sub-type) |
| `InterviewerUser` | Dikdörtgen (ISA altında) | Concept Hierarchy (Sub-type) |
| `JobSector` | Dikdörtgen | Entity |
| `Company` | Dikdörtgen | Entity |
| `JobPosting` | Çift kenarlı dikdörtgen | Weak Entity |
| `Skill` | Dikdörtgen | Entity |
| `ForeignLanguage` | Dikdörtgen | Entity |
| `CandidateSkills` | Baklava + kapsayan dikdörtgen | Aggregation |
| `CandidateForeignLanguages` | Baklava + kapsayan dikdörtgen | Aggregation |
| `JobApplication` | Baklava + kapsayan dikdörtgen | Aggregation |
| `Interviews` | Baklava + kapsayan dik dörtgen | Aggregation |
