#!/bin/bash

#########################################################
##                 Ahmet Korkmaz                       ##
##                  21360859072                        ##
##   Linux Araclari ve Kabuk Programlama Proje Odevi   ##
#########################################################


# Dosya yolları
DEPO_CSV="depo.csv"
KULLANICI_CSV="kullanici.csv"
LOG_CSV="log.csv"

# Varsayılan yönetici hesabı için MD5 şifresi (şifre: admin123)
ADMIN_PASS="0192023a7bbd73250516f069df18b500"

# Fonksiyonlar
hata_kaydet() {
    local hata_no=$1
    local hata_mesaj=$2
    local kullanici=$3
    local urun_bilgisi=$4
    echo "$hata_no,$(date '+%Y-%m-%d %H:%M:%S'),$kullanici,$hata_mesaj,$urun_bilgisi" >> "$LOG_CSV"
}

dosya_kontrol() {
    # CSV dosyalarının varlığını kontrol et
    [ ! -f "$DEPO_CSV" ] && echo "urun_no,urun_adi,stok_miktari,birim_fiyati,kategori" > "$DEPO_CSV"
    [ ! -f "$KULLANICI_CSV" ] && echo "no,adi,soyadi,rol,parola,durum" > "$KULLANICI_CSV"
    [ ! -f "$LOG_CSV" ] && echo "hata_no,zaman,kullanici,hata_mesaj,urun_bilgisi" > "$LOG_CSV"
    
    # Varsayılan admin kullanıcısı yoksa ekle
    if ! grep -q "1,admin,admin,yonetici" "$KULLANICI_CSV"; then
        echo "1,admin,admin,yonetici,$ADMIN_PASS,aktif" >> "$KULLANICI_CSV"
    fi
}

giris_yap() {
    local kullanici_adi
    local parola
    local deneme=0
    
    while [ $deneme -lt 3 ]; do
        credentials=$(zenity --forms --title="Giriş" \
            --text="Kullanıcı bilgilerinizi giriniz" \
            --add-entry="Kullanıcı Adı" \
            --add-password="Parola")
        
        if [ $? -ne 0 ]; then
            exit 0
        fi
        
        kullanici_adi=$(echo "$credentials" | cut -d'|' -f1)
        parola=$(echo "$credentials" | cut -d'|' -f2)
        parola_md5=$(echo -n "$parola" | md5sum | cut -d' ' -f1)
        
        # Kullanıcı kontrolü
        if grep -q "$kullanici_adi.*$parola_md5" "$KULLANICI_CSV"; then
            if grep -q "$kullanici_adi.*aktif" "$KULLANICI_CSV"; then
                return 0
            else
                zenity --error --title="Hata" --text="Hesabınız kilitli. Yönetici ile iletişime geçin."
                hata_kaydet "1001" "Kilitli hesap girişi denemesi" "$kullanici_adi" "-"
                return 1
            fi
        fi
        
        ((deneme++))
        zenity --error --title="Hata" --text="Hatalı kullanıcı adı veya parola! Kalan deneme: $((3-deneme))"
    done
    
    # 3 başarısız deneme sonrası hesabı kilitle
    sed -i "s/\(^.*$kullanici_adi.*\)aktif/\1kilitli/" "$KULLANICI_CSV"
    hata_kaydet "1002" "Hesap kilitlendi - 3 başarısız deneme" "$kullanici_adi" "-"
    zenity --error --title="Hata" --text="Hesabınız kilitlendi. Yönetici ile iletişime geçin."
    return 1
}

urun_ekle() {
    if ! yetki_kontrol "yonetici"; then
        zenity --error --title="Hata" --text="Bu işlem için yetkiniz yok!"
        return 1
    fi
    
    local form_data
    form_data=$(zenity --forms --title="Ürün Ekle" \
        --text="Ürün bilgilerini giriniz" \
        --add-entry="Ürün Adı" \
        --add-entry="Stok Miktarı" \
        --add-entry="Birim Fiyatı" \
        --add-entry="Kategori")
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local urun_adi=$(echo "$form_data" | cut -d'|' -f1)
    local stok_miktari=$(echo "$form_data" | cut -d'|' -f2)
    local birim_fiyati=$(echo "$form_data" | cut -d'|' -f3)
    local kategori=$(echo "$form_data" | cut -d'|' -f4)
    
    # Veri doğrulama
    if [[ ! "$stok_miktari" =~ ^[0-9]+$ ]] || [[ ! "$birim_fiyati" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        zenity --error --title="Hata" --text="Stok miktarı ve birim fiyatı sayısal olmalıdır!"
        hata_kaydet "2001" "Geçersiz sayısal değer" "$AKTIF_KULLANICI" "$urun_adi"
        return 1
    fi
    
    if [[ "$urun_adi" =~ [[:space:]] ]] || [[ "$kategori" =~ [[:space:]] ]]; then
        zenity --error --title="Hata" --text="Ürün adı ve kategori boşluk içermemelidir!"
        hata_kaydet "2002" "Geçersiz karakter" "$AKTIF_KULLANICI" "$urun_adi"
        return 1
    fi
    
    # Ürün adı kontrolü
    if grep -q "^[^,]*,$urun_adi," "$DEPO_CSV"; then
        zenity --error --title="Hata" \
            --text="Bu ürün adıyla başka bir kayıt bulunmaktadır. Lütfen farklı bir ad giriniz."
        hata_kaydet "2003" "Tekrar eden ürün adı" "$AKTIF_KULLANICI" "$urun_adi"
        return 1
    fi
    
    # Yeni ürün numarası oluştur
    local urun_no=1
    if [ -f "$DEPO_CSV" ]; then
        urun_no=$(tail -n +2 "$DEPO_CSV" | cut -d',' -f1 | sort -n | tail -n1)
        ((urun_no++))
    fi
    
    # İlerleme çubuğu
    (
    echo "10"; sleep 0.5
    echo "# Ürün kaydediliyor..."; sleep 0.5
    echo "50"; sleep 0.5
    echo "$urun_no,$urun_adi,$stok_miktari,$birim_fiyati,$kategori" >> "$DEPO_CSV"
    echo "90"; sleep 0.5
    echo "# Tamamlandı!"; sleep 0.5
    echo "100"
    ) | zenity --progress \
        --title="Ürün Ekleniyor" \
        --text="İşlem başlatılıyor..." \
        --percentage=0 \
        --auto-close
    
    zenity --info --title="Başarılı" --text="Ürün başarıyla eklendi!"
}

urun_listele() {
    if [ ! -f "$DEPO_CSV" ]; then
        zenity --error --title="Hata" --text="Ürün listesi bulunamadı!"
        return 1
    fi
    
    local liste="Ürün Listesi:\n\n"
    liste+="No   | Ürün Adı | Stok | Birim Fiyatı | Kategori\n"
    liste+="----------------------------------------\n"
    
    while IFS=, read -r no ad stok fiyat kat; do
        [ "$no" = "urun_no" ] && continue
        liste+="$no | $ad | $stok | $fiyat TL | $kat\n"
    done < "$DEPO_CSV"
    
    echo -e "$liste" | zenity --text-info \
        --title="Ürün Listesi" \
        --width=500 \
        --height=400
}

urun_guncelle() {
    if ! yetki_kontrol "yonetici"; then
        zenity --error --title="Hata" --text="Bu işlem için yetkiniz yok!"
        return 1
    fi
    
    local urun_adi=$(zenity --entry \
        --title="Ürün Güncelle" \
        --text="Güncellenecek ürünün adını giriniz:")
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    if ! grep -q "^[^,]*,$urun_adi," "$DEPO_CSV"; then
        zenity --error --title="Hata" --text="Ürün bulunamadı!"
        return 1
    fi
    
    local eski_bilgiler=$(grep "^[^,]*,$urun_adi," "$DEPO_CSV")
    local eski_no=$(echo "$eski_bilgiler" | cut -d',' -f1)
    local eski_stok=$(echo "$eski_bilgiler" | cut -d',' -f3)
    local eski_fiyat=$(echo "$eski_bilgiler" | cut -d',' -f4)
    local eski_kat=$(echo "$eski_bilgiler" | cut -d',' -f5)
    
    local form_data
    form_data=$(zenity --forms --title="Ürün Güncelle" \
        --text="Yeni bilgileri giriniz" \
        --add-entry="Stok Miktarı [$eski_stok]" \
        --add-entry="Birim Fiyatı [$eski_fiyat]" \
        --add-entry="Kategori [$eski_kat]")
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local yeni_stok=$(echo "$form_data" | cut -d'|' -f1)
    local yeni_fiyat=$(echo "$form_data" | cut -d'|' -f2)
    local yeni_kat=$(echo "$form_data" | cut -d'|' -f3)
    
    # Boş alanlar için eski değerleri kullan
    [ -z "$yeni_stok" ] && yeni_stok=$eski_stok
    [ -z "$yeni_fiyat" ] && yeni_fiyat=$eski_fiyat
    [ -z "$yeni_kat" ] && yeni_kat=$eski_kat
    
    # Veri doğrulama
    if [[ ! "$yeni_stok" =~ ^[0-9]+$ ]] || [[ ! "$yeni_fiyat" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]]; then
        zenity --error --title="Hata" --text="Stok miktarı ve birim fiyatı sayısal olmalıdır!"
        hata_kaydet "3001" "Geçersiz sayısal değer" "$AKTIF_KULLANICI" "$urun_adi"
        return 1
    fi
    
    # İlerleme çubuğu
    (
    echo "10"; sleep 0.5
    echo "# Ürün güncelleniyor..."; sleep 0.5
    echo "50"; sleep 0.5
    sed -i "s/^$eski_no,$urun_adi,$eski_stok,$eski_fiyat,$eski_kat/$eski_no,$urun_adi,$yeni_stok,$yeni_fiyat,$yeni_kat/" "$DEPO_CSV"
    echo "90"; sleep 0.5
    echo "# Tamamlandı!"; sleep 0.5
    echo "100"
    ) | zenity --progress \
        --title="Ürün Güncelleniyor" \
        --text="İşlem başlatılıyor..." \
        --percentage=0 \
        --auto-close
    
    zenity --info --title="Başarılı" --text="Ürün başarıyla güncellendi!"
}

urun_sil() {
    if ! yetki_kontrol "yonetici"; then
        zenity --error --title="Hata" --text="Bu işlem için yetkiniz yok!"
        return 1
    fi
    
    local urun_adi=$(zenity --entry \
        --title="Ürün Sil" \
        --text="Silinecek ürünün adını giriniz:")
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    if ! grep -q "^[^,]*,$urun_adi," "$DEPO_CSV"; then
        zenity --error --title="Hata" --text="Ürün bulunamadı!"
        return 1
    fi
    
    if ! zenity --question \
        --title="Onay" \
        --text="'$urun_adi' ürününü silmek istediğinizden emin misiniz?"; then
        return 1
    fi
    
    # İlerleme çubuğu
    (
    echo "10"; sleep 0.5
    echo "# Ürün siliniyor..."; sleep 0.5
    echo "50"; sleep 0.5
    sed -i "/^[^,]*,$urun_adi,/d" "$DEPO_CSV"
    echo "90"; sleep 0.5
    echo "# Tamamlandı!"; sleep 0.5
    echo "100"
    ) | zenity --progress \
        --title="Ürün Siliniyor" \
        --text="İşlem başlatılıyor..." \
        --percentage=0 \
        --auto-close
    
    zenity --info --title="Başarılı" --text="Ürün başarıyla silindi!"
}

rapor_al() {
    local secim=$(zenity --list \
        --title="Rapor Al" \
        --text="Rapor türünü seçiniz:" \
        --radiolist \
        --column="Seç" \
        --column="Rapor" \
        TRUE "Stokta Azalan Ürünler" \
        FALSE "En Yüksek Stok Miktarına Sahip Ürünler")
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    case "$secim" in
        "Stokta Azalan Ürünler")
            local esik=$(zenity --entry \
                --title="Stok Eşiği" \
                --text="Minimum stok eşiğini giriniz:")
            
            [ $? -ne 0 ] && return 1
            
            local rapor="Stok Miktarı $esik'in Altında Olan Ürünler:\n\n"
            rapor+="Ürün Adı | Stok | Birim Fiyatı | Kategori\n"
            rapor+="----------------------------------------\n"
            
            while IFS=, read -r no ad stok fiyat kat; do
                [ "$no" = "urun_no" ] && continue
                if [ "$stok" -lt "$esik" ]; then
                    rapor+="$ad | $stok | $fiyat TL | $kat\n"
                fi
            done < "$DEPO_CSV"
            ;;
            
        "En Yüksek Stok Miktarına Sahip Ürünler")
            local esik=$(zenity --entry \
                --title="Stok Eşiği" \
                --text="Minimum stok eşiğini giriniz:")
            
            [ $? -ne 0 ] && return 1
            
            local rapor="Stok Miktarı $esik'in Üzerinde Olan Ürünler:\n\n"
            rapor+="Ürün Adı | Stok | Birim Fiyatı | Kategori\n"
            rapor+="----------------------------------------\n"
            
            while IFS=, read -r no ad stok fiyat kat; do
                [ "$no" = "urun_no" ] && continue
                if [ "$stok" -gt "$esik" ]; then
                    rapor+="$ad | $stok | $fiyat TL | $kat\n"
                fi
            done < "$DEPO_CSV"
            ;;
    esac
    
    echo -e "$rapor" | zenity --text-info \
        --title="Rapor Sonuçları" \
        --width=500 \
        --height=400
}

kullanici_yonetimi() {
    if ! yetki_kontrol "yonetici"; then
        zenity --error --title="Hata" --text="Bu işlem için yetkiniz yok!"
        return 1
    fi
    
    local secim=$(zenity --list \
        --title="Kullanıcı Yönetimi" \
        --text="İşlem seçiniz:" \
        --column="İşlem" \
        "Yeni Kullanıcı Ekle" \
        "Kullanıcıları Listele" \
        "Kullanıcı Güncelle" \
        "Kullanıcı Sil")
    
    case "$secim" in
        "Yeni Kullanıcı Ekle")
            local form_data
            form_data=$(zenity --forms --title="Kullanıcı Ekle" \
                --text="Kullanıcı bilgilerini giriniz" \
                --add-entry="Adı" \
                --add-entry="Soyadı" \
                --add-entry="Kullanıcı Adı" \
                --add-password="Parola" \
                --add-list="Rol" \
                --list-values="kullanici|yonetici")
            
            [ $? -ne 0 ] && return 1
            
            local adi=$(echo "$form_data" | cut -d'|' -f1)
            local soyadi=$(echo "$form_data" | cut -d'|' -f2)
            local kul_adi=$(echo "$form_data" | cut -d'|' -f3)
            local parola=$(echo "$form_data" | cut -d'|' -f4)
            local rol=$(echo "$form_data" | cut -d'|' -f5)
            
            local parola_md5=$(echo -n "$parola" | md5sum | cut -d' ' -f1)
            
            # Kullanıcı no oluştur
            local kul_no=1
            if [ -f "$KULLANICI_CSV" ]; then
                kul_no=$(tail -n +2 "$KULLANICI_CSV" | cut -d',' -f1 | sort -n | tail -n1)
                ((kul_no++))
            fi
            
            echo "$kul_no,$adi,$soyadi,$rol,$parola_md5,aktif" >> "$KULLANICI_CSV"
            zenity --info --title="Başarılı" --text="Kullanıcı başarıyla eklendi!"
            ;;
            
        "Kullanıcıları Listele")
            local liste="Kullanıcı Listesi:\n\n"
            liste+="No | Adı | Soyadı | Rol | Durum\n"
            liste+="----------------------------------------\n"
            
            while IFS=, read -r no ad soyad rol parola durum; do
                [ "$no" = "no" ] && continue
                liste+="$no | $ad | $soyad | $rol | $durum\n"
            done < "$KULLANICI_CSV"
            
            echo -e "$liste" | zenity --text-info \
                --title="Kullanıcı Listesi" \
                --width=500 \
                --height=400
            ;;
            
        "Kullanıcı Güncelle")
            local kul_adi=$(zenity --entry \
                --title="Kullanıcı Güncelle" \
                --text="Güncellenecek kullanıcının adını giriniz:")
            
            [ $? -ne 0 ] && return 1
            
            if ! grep -q "^[^,]*,$kul_adi," "$KULLANICI_CSV"; then
                zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
                return 1
            fi
            
            local form_data
            form_data=$(zenity --forms --title="Kullanıcı Güncelle" \
                --text="Yeni bilgileri giriniz (Boş bırakılan alanlar değişmeyecektir)" \
                --add-entry="Yeni Adı" \
                --add-entry="Yeni Soyadı" \
                --add-password="Yeni Parola" \
                --add-list="Yeni Rol" \
                --list-values="kullanici|yonetici")
            
            [ $? -ne 0 ] && return 1
            
            local yeni_ad=$(echo "$form_data" | cut -d'|' -f1)
            local yeni_soyad=$(echo "$form_data" | cut -d'|' -f2)
            local yeni_parola=$(echo "$form_data" | cut -d'|' -f3)
            local yeni_rol=$(echo "$form_data" | cut -d'|' -f4)
            
            # Eski bilgileri al
            local eski_bilgiler=$(grep "^[^,]*,$kul_adi," "$KULLANICI_CSV")
            local kul_no=$(echo "$eski_bilgiler" | cut -d',' -f1)
            local eski_ad=$(echo "$eski_bilgiler" | cut -d',' -f2)
            local eski_soyad=$(echo "$eski_bilgiler" | cut -d',' -f3)
            local eski_rol=$(echo "$eski_bilgiler" | cut -d',' -f4)
            local eski_parola=$(echo "$eski_bilgiler" | cut -d',' -f5)
            local durum=$(echo "$eski_bilgiler" | cut -d',' -f6)
            
            # Boş alanlar için eski değerleri kullan
            [ -z "$yeni_ad" ] && yeni_ad=$eski_ad
            [ -z "$yeni_soyad" ] && yeni_soyad=$eski_soyad
            [ -z "$yeni_rol" ] && yeni_rol=$eski_rol
            
            if [ -n "$yeni_parola" ]; then
                yeni_parola_md5=$(echo -n "$yeni_parola" | md5sum | cut -d' ' -f1)
            else
                yeni_parola_md5=$eski_parola
            fi
            
            sed -i "s/^$kul_no,$kul_adi,$eski_soyad,$eski_rol,$eski_parola,$durum/$kul_no,$yeni_ad,$yeni_soyad,$yeni_rol,$yeni_parola_md5,$durum/" "$KULLANICI_CSV"
            
            zenity --info --title="Başarılı" --text="Kullanıcı başarıyla güncellendi!"
            ;;
            
        "Kullanıcı Sil")
            local kul_adi=$(zenity --entry \
                --title="Kullanıcı Sil" \
                --text="Silinecek kullanıcının adını giriniz:")
            
            [ $? -ne 0 ] && return 1
            
            if ! grep -q "^[^,]*,$kul_adi," "$KULLANICI_CSV"; then
                zenity --error --title="Hata" --text="Kullanıcı bulunamadı!"
                return 1
            fi
            
            if ! zenity --question \
                --title="Onay" \
                --text="'$kul_adi' kullanıcısını silmek istediğinizden emin misiniz?"; then
                return 1
            fi
            
            sed -i "/^[^,]*,$kul_adi,/d" "$KULLANICI_CSV"
            zenity --info --title="Başarılı" --text="Kullanıcı başarıyla silindi!"
            ;;
    esac
}

program_yonetimi() {
    if ! yetki_kontrol "yonetici"; then
        zenity --error --title="Hata" --text="Bu işlem için yetkiniz yok!"
        return 1
    fi
    
    local secim=$(zenity --list \
        --title="Program Yönetimi" \
        --text="İşlem seçiniz:" \
        --column="İşlem" \
        "Diskteki Alanı Göster" \
        "Diske Yedekle" \
        "Hata Kayıtlarını Göster")
    
    case "$secim" in
        "Diskteki Alanı Göster")
            local boyut=$(du -ch "$DEPO_CSV" "$KULLANICI_CSV" "$LOG_CSV" | grep total)
            zenity --info \
                --title="Disk Kullanımı" \
                --text="Toplam kullanılan alan: $boyut"
            ;;
            
        "Diske Yedekle")
            local tarih=$(date +%Y%m%d_%H%M%S)
            local yedek_dizin="yedek_$tarih"
            
            mkdir -p "$yedek_dizin"
            cp "$DEPO_CSV" "$KULLANICI_CSV" "$yedek_dizin/"
            
            zenity --info \
                --title="Yedekleme" \
                --text="Dosyalar '$yedek_dizin' dizinine yedeklendi."
            ;;
            
        "Hata Kayıtlarını Göster")
            if [ ! -f "$LOG_CSV" ]; then
                zenity --error --title="Hata" --text="Hata kayıt dosyası bulunamadı!"
                return 1
            fi
            
            local kayitlar="Hata Kayıtları:\n\n"
            kayitlar+="No | Zaman | Kullanıcı | Hata | Ürün\n"
            kayitlar+="----------------------------------------\n"
            
            while IFS=, read -r no zaman kul hata urun; do
                [ "$no" = "hata_no" ] && continue
                kayitlar+="$no | $zaman | $kul | $hata | $urun\n"
            done < "$LOG_CSV"
            
            echo -e "$kayitlar" | zenity --text-info \
                --title="Hata Kayıtları" \
                --width=700 \
                --height=500
            ;;
    esac
}

yetki_kontrol() {
    local gerekli_rol=$1
    local kullanici_rol=$(grep "^[^,]*,$AKTIF_KULLANICI," "$KULLANICI_CSV" | cut -d',' -f4)
    
    if [ "$gerekli_rol" = "yonetici" ] && [ "$kullanici_rol" != "yonetici" ]; then
        return 1
    fi
    return 0
}

# Ana menü fonksiyonu
ana_menu() {
    while true; do
        local menu_secim=$(zenity --list \
            --title="Envanter Yönetim Sistemi" \
            --text="Hoş geldiniz, $AKTIF_KULLANICI" \
            --column="İşlem" \
            "Ürün Ekle" \
            "Ürün Listele" \
            "Ürün Güncelle" \
            "Ürün Sil" \
            "Rapor Al" \
            "Kullanıcı Yönetimi" \
            "Program Yönetimi" \
            "Çıkış" --width=800 --height=500)
        
        case "$menu_secim" in
            "Ürün Ekle") urun_ekle ;;
            "Ürün Listele") urun_listele ;;
            "Ürün Güncelle") urun_guncelle ;;
            "Ürün Sil") urun_sil ;;
            "Rapor Al") rapor_al ;;
            "Kullanıcı Yönetimi") kullanici_yonetimi ;;
            "Program Yönetimi") program_yonetimi ;;
            "Çıkış"|"")
                if zenity --question \
                    --title="Çıkış" \
                    --text="Programdan çıkmak istediğinize emin misiniz?"; then
                    exit 0
                fi
                ;;
        esac
    done
}

# Ana program
AKTIF_KULLANICI=""

# Başlangıç kontrolleri
dosya_kontrol

# Giriş yap
if giris_yap; then
    # Aktif kullanıcıyı belirle
    AKTIF_KULLANICI=$(grep "$(echo "$credentials" | cut -d'|' -f1)" "$KULLANICI_CSV" | cut -d',' -f2)
    # Ana menüyü başlat
    ana_menu
fi