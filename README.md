# 🚀 Keenetic & Debian Home Server Setup

Bu depo, bir Debian sunucu üzerinde çalışan Docker/Dockge altyapısını ve Keenetic router'lar için özel olarak derlenmiş hafifletilmiş Cloudflared (MIPS/UPX) tünel kurulumunu içerir.

## 🌟 Neler Var?
1. **Cloudflared Çapraz Derleme Fabrikası:** MIPS mimarisine sahip router'lar (Keenetic vb.) için Go 1.26 ile en güncel Cloudflared sürümünü derler ve **UPX** ile 40MB'dan 8MB'a sıkıştırır.
2. **Keenetic Init Betiği:** Cloudflared'in elektrik kesintilerinde (NTP saati ve WAN gelmeden önce) sorunsuz başlamasını sağlayan `S99cloudflared` betiği.

## 🛠️ Nasıl Kullanılır?

### 1. Cloudflared Derleme (Keenetic İçin)
`cloudflared-keenetic-builder` klasöründeki compose dosyasını Dockge veya Portainer üzerinden çalıştırın. MIPSLE ve MIPS mimarisi için derlenmiş ve preslenmiş dosya `derlenenler` klasörüne çıkacaktır.

Derleme sonunda `derlenenler/SHA256SUMS` dosyası oluşturulur ve MIPS/MIPSLE dosyalarının SHA256 doğrulama çıktıları terminale yazdırılır.

Compose akışı Dockge üzerinde birden fazla stack ile çakışmaması için sabit container adı kullanmaz. UPX paketi Debian Bookworm ana deposunda bulunamazsa otomatik olarak `upx-ucl` ve `bookworm-backports` üzerinden kurulum denenir.

### 2. Keenetic'e Kurulum
Çıkan dosyayı modemin `/opt/home/` dizinine atın. `S99cloudflared` betiğini `/opt/etc/init.d/` içine kopyalayıp `chmod +x` ile yetki verin.

## ⚠️ Uyarı
Compose dosyalarındaki şifreleri, alan adlarını ve token kısımlarını kendi sisteminize göre değiştirmeyi unutmayın!
