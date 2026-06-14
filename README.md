# Keenetic Cloudflared MIPS Builder

Keenetic ve benzeri MIPS tabanlı router'larda Cloudflare Tunnel çalıştırmak için hazırlanmış küçük bir build ve kurulum deposu.

Bu proje, upstream `cloudflare/cloudflared` kaynak kodunu Docker içinde derler, MIPS/MIPSLE binary üretir, UPX ile küçültür, SHA256 checksum oluşturur ve Keenetic/Entware ortamında boot sonrası otomatik başlatma için `S99cloudflared` init betiği sağlar.

## Neden Var?

Cloudflare Tunnel self-hosting ve Zero Trust erişimi için yaygın kullanılıyor, ancak düşük güçlü MIPS router'larda resmi kurulum yolu her zaman pratik değil. Bu depo özellikle şu ihtiyacı çözer:

- Keenetic router üzerinde ayrı bir sunucuya gerek kalmadan `cloudflared` çalıştırma
- Tekrarlanabilir Docker tabanlı MIPS/MIPSLE build akışı
- Router depolaması için UPX ile küçültülmüş binary
- Üretilen dosyalar için `SHA256SUMS` doğrulama dosyası
- WAN ve NTP gecikmelerine dayanacak init script

## Test Edilen Cihaz

- Keenetic Hopper DSL (KN-3610) TR
- `uname -a` mimarisi: `mips GNU/Linux`
- Test edilen çalışan binary: `cloudflared-mips`

`cloudflared-mipsle` de üretilir; farklı Keenetic/router modelleri için gerekebilir.

## Dosyalar

- `compose.yaml`: Cloudflared MIPS/MIPSLE build akışı
- `S99cloudflared`: Keenetic/Entware init script
- `scripts/deploy-keenetic.sh`: Derlenen binary'yi Keenetic cihaza SSH üzerinden yükleme script'i
- `cloudflared.token.example`: Token dosyası örneği
- `cloudflared`: Örnek/önceki test binary dosyası

## Build

Dockge, Portainer veya Docker Compose ile çalıştırın:

```sh
docker compose run --rm compiler
```

Build sonunda `derlenenler/` dizininde şu dosyalar oluşur:

```text
cloudflared-mips
cloudflared-mipsle
SHA256SUMS
```

Compose akışı:

- `golang:1.26-bookworm` imajı kullanır
- `git` ve `ca-certificates` paketlerini kurar
- UPX için önce `upx`, sonra `upx-ucl`, gerekirse `bookworm-backports` dener
- `cloudflare/cloudflared` deposunu `--depth 1` ile indirir
- `CGO_ENABLED=0` ve `-trimpath` ile cross-compile yapar
- UPX sonrası SHA256 checksum oluşturur

## Keenetic Kurulum

KN-3610 için `cloudflared-mips` dosyasını modemde script'in beklediği isme koyun:

```sh
cp /opt/home/cloudflared-mips /opt/home/cloudflared
chmod +x /opt/home/cloudflared
```

Token dosyasını hazırlayın. `cloudflared.token.example` dosyasını örnek alıp gerçek token'i modem üzerinde `/opt/etc/cloudflared.token` dosyasına yazın:

```sh
vi /opt/etc/cloudflared.token
chmod 600 /opt/etc/cloudflared.token
```

Init script'i yerleştirin ve çalıştırılabilir yapın:

```sh
cp S99cloudflared /opt/etc/init.d/S99cloudflared
chmod +x /opt/etc/init.d/S99cloudflared
```

Servisi başlatın ve kontrol edin:

```sh
/opt/etc/init.d/S99cloudflared start
/opt/etc/init.d/S99cloudflared status
tail -n 50 /opt/var/log/cloudflared.log
```

## Otomatik Deploy

Keenetic SSH servisi doğrudan Linux shell yerine `(config)>` CLI açtığı için klasik `scp` her cihazda çalışmayabilir. Bu nedenle deploy script'i dosyayı `ssh` üzerinden `exec sh` ile aktarır.

Varsayılan kullanım:

```sh
./scripts/deploy-keenetic.sh
```

Farklı host, kullanıcı veya binary için:

```sh
MODEM_HOST=192.168.1.1 \
MODEM_USER=admin \
BINARY=derlenenler/cloudflared-mips \
./scripts/deploy-keenetic.sh
```

Script'in yaptığı işlem:

- Binary'yi `/opt/home/cloudflared.new` olarak yükler
- Yerel ve modem üzerindeki SHA256 değerlerini karşılaştırır
- `S99cloudflared` servisini durdurur
- Eski binary'yi `/opt/home/cloudflared.bak` olarak yedekler
- Yeni binary'yi `/opt/home/cloudflared` olarak taşır
- Servisi tekrar başlatır ve status çıktısını gösterir

## Güvenlik Notları

- Gerçek Cloudflare tunnel token'ini repoya commit etmeyin.
- `cloudflared.token` dosyasını modem üzerinde mümkünse `chmod 600` ile saklayın.
- Üretilen binary'leri modem üzerine atmadan önce `SHA256SUMS` ile doğrulayın.
- Bu proje Cloudflare veya Keenetic tarafından resmi olarak sağlanan bir paket değildir.

## Bakım Notları

`S99cloudflared` betiği:

- PATH'i Entware/Keenetic ortamlarına göre ayarlar
- NTP zamanı oturmadan TLS hatası almamak için bekler
- WAN bağlantısını ping ile kontrol eder
- Stale PID dosyasını temizler
- Token dosyasındaki Windows satır sonlarını temizler
- Logları `/opt/var/log/cloudflared.log` dosyasına yazar

## Lisans

Bu depo MIT lisansı ile yayınlanır. Cloudflared kendi upstream lisansı ve koşulları ile Cloudflare tarafından geliştirilmektedir.
