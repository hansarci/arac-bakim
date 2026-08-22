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
- **Veri saklama** — şimdilik cihaz içi (SharedPreferences). İleride Firebase'e taşımak istersen `lib/services/storage_service.dart` dosyasını Firestore çağrılarıyla değiştirmen yeterli, diğer hiçbir ekranı değiştirmene gerek yok.

## GitHub Actions ile APK üretme (yerel Flutter SDK gerekmez)

1. Bu klasörün içeriğini bir GitHub reposuna yükle (repo boşsa doğrudan bu dosyaları push'la).
2. GitHub'da repo sayfasında **Actions** sekmesine git.
3. "Build APK" workflow'unu göreceksin — otomatik olarak `main` dalına her push'ta çalışır, istersen **Run workflow** butonuyla da elle tetikleyebilirsin.
4. Derleme bitince (birkaç dakika sürer) workflow sayfasının altında **Artifacts** kısmında `arac-bakim-apk` dosyasını indirebilirsin — içinde `app-release.apk` var.
5. APK'yı telefonuna aktarıp kurabilirsin (bilinmeyen kaynaklardan yükleme izni gerekebilir).

## Firebase eklemek istersen

Şu an bu uygulama tamamen cihaz içinde çalışıyor, internet/Firebase gerektirmiyor. İleride
Kutur M3 / Orjanda'daki gibi Firebase'e bağlamak istersen:

1. Firebase konsolundan bir proje oluştur, Android uygulaması ekle (`applicationId: com.turhan.aracbakim`).
2. İndirdiğin `google-services.json` dosyasını `android/app/` klasörüne koy.
3. `android/build.gradle` ve `android/app/build.gradle` dosyalarına Google Services plugin'ini ekle.
4. `lib/services/storage_service.dart` içindeki `loadVehicles`/`saveVehicles` fonksiyonlarını Firestore okuma/yazma ile değiştir.

Bu adımları istediğinde birlikte yaparız.

## Paket adı / uygulama adı değiştirmek istersen

- Uygulama adı: `android/app/src/main/AndroidManifest.xml` içindeki `android:label`
- Paket adı (applicationId): `android/app/build.gradle` içindeki `namespace` ve `applicationId`,
  ayrıca `android/app/src/main/kotlin/com/turhan/aracbakim/MainActivity.kt` dosyasının klasör yolu ve `package` satırı

## Bakım kuralı eklemek istersen (Triger dışında)

`lib/utils/maintenance_rules.dart` dosyasındaki `maintenanceRules` listesine yeni bir satır eklemen yeterli:

```dart
MaintenanceRule(id: 'fren_balata', keywords: ['fren balata', 'balata'], interval: 40000, label: 'Fren balata değişimi'),
```
