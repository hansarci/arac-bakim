# Araç Bakım — Flutter Projesi

Bu proje, HTML mockup'ta tasarladığımız araç bakım takip uygulamasının tam Flutter karşılığıdır.
Yerel bilgisayarında Flutter SDK kurulu olmasa bile, GitHub Actions üzerinden APK üretebilirsin.

## Neler var

- **Araçlarım listesi** — kayıtlı araçlar, güncel km/saat, "son işlem kategorisi", gelecek muayene tarihi (geçmişse kırmızı)
- **Araç detay sayfası** — istatistikler, kalem bazlı bakım uyarıları (Triger için 90.000 km kuralı), sadece bakım geçmişi listesi kayan yapı
- **Yeni Araç Ekle** sheet'i — araç tipi dropdown, km/saat toggle, periyodik muayene tekrarı (1/2/3 yıl), son muayene tarihi
- **Yeni İşlem Ekle** tam ekran sayfası — Enter'a bastıkça etikete dönüşen "Yapılan İşlem(ler)" alanı, opsiyonel çoklu kategori etiketleri
- **Muayeneyi onaylama** — detay sayfasındaki muayene kutusuna dokunup "bugün yaptırdım" diyerek tarihi güncelleme
- **Bildirimler** — muayene tarihine 7 gün kala (veya tarih geçtiyse) cihaza yerel bildirim
- **Veri saklama** — Firebase Firestore'da, Orman Muhasebe'deki gibi kullanıcı girişi (auth) yok — bu uygulamayı sadece sen kullanacaksın. Yazmalar "gönder ve unut" (fire-and-forget) çalışır ve Firestore'un cihaz içi önbelleği açık, yani sahada internet olmasa bile uygulama beklemeden çalışmaya devam eder, bağlantı gelince kendiliğinden senkronize olur.

## ⚠️ Önce Firebase kurulumu — bu olmadan APK derlenmez

Bu proje artık Firebase Firestore'a bağlı çalışıyor. GitHub Actions'ın APK'yı derleyebilmesi için önce senin bir Firebase projesi oluşturup `google-services.json` dosyasını repoya eklemen gerekiyor (bu dosya sana özel olduğu için zip'in içine koyulmadı).

1. [Firebase Console](https://console.firebase.google.com/)'a git, **"Add project"** ile yeni bir proje oluştur (istediğin ismi verebilirsin, örn. "arac-bakim").
2. Proje açıldıktan sonra **Android ikonuna** tıklayıp uygulama ekle:
   - **Android package name:** `com.turhan.aracbakim` (birebir bu, başka bir şey yazma)
   - Uygulama takma adı boş bırakılabilir, "Register app"e bas
3. **"Download google-services.json"** ile dosyayı indir.
4. GitHub reponda **`android/app/`** klasörünün içine bu dosyayı yükle (Add file → Upload files, sadece bu tek dosyayı sürükle).
5. Firebase konsolunda sol menüden **Build → Firestore Database**'e git, **"Create database"** ile bir veritabanı oluştur (konum olarak `eur3` (Avrupa) veya sana en yakın bölgeyi seç). "Start in production mode" seçebilirsin — güvenlik kuralları zaten bu projede hazır (`firestore.rules` dosyası), konsoldaki **Rules** sekmesine gidip o dosyanın içeriğini yapıştırıp **Publish**'e basman yeterli.

Bu kurulum bitince GitHub Actions'a gidip workflow'u tekrar çalıştır (**Run workflow** veya yeni bir commit) — bu sefer derleme başarılı olacak ve veriler artık Firestore'da saklanacak.

## GitHub Actions ile APK üretme (yerel Flutter SDK gerekmez)

1. Bu klasörün içeriğini bir GitHub reposuna yükle (repo boşsa doğrudan bu dosyaları push'la).
2. Yukarıdaki **Firebase kurulumu** adımlarını tamamla (`google-services.json` dosyasını eklemeden derleme başarısız olur).
3. GitHub'da repo sayfasında **Actions** sekmesine git.
4. "Build APK" workflow'unu göreceksin — otomatik olarak `main` dalına her push'ta çalışır, istersen **Run workflow** butonuyla da elle tetikleyebilirsin.
5. Derleme bitince (birkaç dakika sürer) workflow sayfasının altında **Artifacts** kısmında `arac-bakim-apk` dosyasını indirebilirsin — içinde `app-release.apk` var.
6. APK'yı telefonuna aktarıp kurabilirsin (bilinmeyen kaynaklardan yükleme izni gerekebilir).

## Verileri farklı bir cihazda görmek istersen

Auth olmadığı için tüm cihazlar zaten aynı tek Firestore belgesini paylaşıyor — yani telefon değiştirsen veya uygulamayı silip tekrar kursan bile veriler kaybolmaz, aynı yerden devam eder. (Bu aynı zamanda projeyi bulan başka biri de aynı belgeye yazabilir demek — Orman Muhasebe'de de bilerek bu şekilde bırakıldı çünkü uygulamayı sadece sen kullanıyorsun. İleride gerçek bir hesap sistemi istersen söyle, ekleriz.)

## Paket adı / uygulama adı değiştirmek istersen

- Uygulama adı: `android/app/src/main/AndroidManifest.xml` içindeki `android:label`
- Paket adı (applicationId): `android/app/build.gradle` içindeki `namespace` ve `applicationId`,
  ayrıca `android/app/src/main/kotlin/com/turhan/aracbakim/MainActivity.kt` dosyasının klasör yolu ve `package` satırı

## Bakım kuralı eklemek istersen (Triger dışında)

`lib/utils/maintenance_rules.dart` dosyasındaki `maintenanceRules` listesine yeni bir satır eklemen yeterli:

```dart
MaintenanceRule(id: 'fren_balata', keywords: ['fren balata', 'balata'], interval: 40000, label: 'Fren balata değişimi'),
```
