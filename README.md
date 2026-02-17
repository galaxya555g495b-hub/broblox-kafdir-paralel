# broblox-kafdir-paralel

Kapasite ve paralel işleme odaklı örnek yapılandırma + planlama deposu.

## 🚀 Özellikler

- **Kapasite parametreleri**: `MAX_CAPACITY`, `PARALLEL_WORKERS`, `QUEUE_LIMIT`, `AUTO_SCALE`.
- **Profil bazlı çalışma**: `dev`, `staging`, `prod` için ayrı ayar örnekleri.
- **Kapasite planlama aracı (CLI)**: Trafik ve işlem süresine göre önerilen worker sayısını hesaplar.
- **Roblox Studio LocalScript (tek dosya)**: Arayüz + hesaplama tek script içinde çalışır.
- **Admin paneli**: Tek panel içinde arama destekli **150 admin kodu** listesi.

## 1) Kapasite Yapılandırması

Örnek dosya: `config/capacity.example.yaml`

| Parametre | Açıklama | Öneri |
|---|---|---|
| `max_capacity` | Sistemin aynı anda işleyebileceği toplam iş adedi | Trafik artışına göre artırın |
| `parallel_workers` | Eşzamanlı çalışan worker sayısı | CPU çekirdeği ve IO tipine göre ayarlayın |
| `queue_limit` | Kuyrukta bekleyebilecek maksimum iş sayısı | Ani trafik artışlarında koruma sağlar |
| `auto_scale.enabled` | Otomatik ölçekleme aktif/pasif | Üretimde `true` önerilir |
| `auto_scale.max_workers` | Otomatik ölçeklemede çıkılabilecek üst worker limiti | Altyapı sınırına göre belirleyin |

## 2) Kapasite Planlama Aracı (CLI)

```bash
python3 scripts/capacity_planner.py \
  --requests-per-minute 4800 \
  --avg-job-ms 220 \
  --target-utilization 0.70
```

## 3) Roblox Studio Tek LocalScript Kullanımı

Dosya: `CapacityPlanner.client.lua`

Kurulum:

1. Roblox Studio'da **StarterPlayer > StarterPlayerScripts** açın.
2. Yeni bir **LocalScript** oluşturun.
3. `CapacityPlanner.client.lua` içeriğini komple bu tek LocalScript içine yapıştırın.
4. Play'e basın; panel ekranda açılır.

Panel içeriği:

- **Kapasite Planlayıcı**: RPM, Average job(ms), utilization ve burst girdileriyle hesaplama.
- **Admin Kod Paneli**: `ADM-<AKSIYON>-L<SEVIYE>` formatında toplam 150 kod.
- **Arama kutusu**: Kod/isim/açıklamaya göre filtreleme.
- **Kod seçimi**: Liste satırına tıklayınca seçilen kod üstte gösterilir.

Admin kod seti 15 aksiyon x 10 seviye olarak üretilir:

`KICK, BAN, MUTE, UNMUTE, FREEZE, UNFREEZE, HEAL, GOD, UNGOD, SPEED, JUMP, TP, BRING, GIVE, ANNOUNCE`

## 4) Hızlı Başlangıç

1. Örnek kapasite dosyasını kopyalayın:
   ```bash
   cp config/capacity.example.yaml config/capacity.yaml
   ```
2. Profil seçin (`dev/staging/prod`) ve değerleri ihtiyaca göre güncelleyin.
3. CLI ile ilk tahmini alın.
4. Roblox LocalScript panelinde hem kapasite hesaplarını hem admin kodlarını kullanın.

---

Bu repo, kapasite artışını sadece sayı güncellemesi olarak değil; planlama + gözlemleme + ölçekleme döngüsü olarak ele alır.
