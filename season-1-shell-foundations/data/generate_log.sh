#!/bin/bash
# Генератор реалистичного access.log для Episode 03

OUTPUT="access.log"
> "$OUTPUT"

echo "Generating realistic access.log..."

# Массивы для генерации
LEGIT_IPS=("192.168.1.100" "10.0.0.50" "172.16.5.20" "203.0.113.45" "198.51.100.88")
ATTACK_IPS=("185.220.101.47" "91.234.56.78" "45.155.205.67" "198.18.44.133" "194.55.87.92" "159.89.123.45" "104.244.72.115" "37.187.96.66" "185.100.87.41" "195.123.244.167")
PATHS=("/index.html" "/about.html" "/contact.html" "/api/users" "/api/auth" "/static/css/main.css" "/static/js/app.js" "/images/logo.png")
ATTACK_PATHS=("/admin/login.php" "/wp-admin/" "/phpmyadmin/" "/admin.php" "/login.php' OR '1'='1" "/api/users?id=1' UNION SELECT password" "/../../etc/passwd" "/.env" "/config.php")
USER_AGENTS=("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" "curl/7.68.0" "python-requests/2.25.1")
ATTACK_AGENTS=("sqlmap/1.5.2" "Nikto/2.1.6" "nmap NSE" "masscan/1.0" "' OR '1'='1" "curl/7.58.0 (scanner)")

# Функция генерации timestamp
generate_timestamp() {
    local hour=$1
    local minute=$((RANDOM % 60))
    local second=$((RANDOM % 60))
    printf "[04/Oct/2025:%02d:%02d:%02d +0000]" "$hour" "$minute" "$second"
}

# Генерируем легитимный трафик (3000 строк)
echo "Adding legitimate traffic..."
for i in {1..3000}; do
    IP="${LEGIT_IPS[$((RANDOM % ${#LEGIT_IPS[@]}))]}"
    PATH="${PATHS[$((RANDOM % ${#PATHS[@]}))]}"
    STATUS=$((RANDOM % 10 < 9 ? 200 : 404))
    SIZE=$((RANDOM % 5000 + 500))
    AGENT="${USER_AGENTS[$((RANDOM % ${#USER_AGENTS[@]}))]}"
    HOUR=$((RANDOM % 24))
    TS=$(generate_timestamp $HOUR)
    
    echo "$IP - - $TS \"GET $PATH HTTP/1.1\" $STATUS $SIZE \"-\" \"$AGENT\"" >> "$OUTPUT"
done

# SQL Injection attempts (03:00-04:00)
echo "Adding SQL injection attacks..."
for i in {1..300}; do
    IP="${ATTACK_IPS[$((RANDOM % ${#ATTACK_IPS[@]}))]}"
    PATH="${ATTACK_PATHS[$((RANDOM % ${#ATTACK_PATHS[@]}))]}"
    STATUS=$((RANDOM % 10 < 8 ? 403 : 500))
    SIZE=$((RANDOM % 2000 + 100))
    AGENT="${ATTACK_AGENTS[$((RANDOM % ${#ATTACK_AGENTS[@]}))]}"
    HOUR=3
    TS=$(generate_timestamp $HOUR)
    
    echo "$IP - - $TS \"POST $PATH HTTP/1.1\" $STATUS $SIZE \"-\" \"$AGENT\"" >> "$OUTPUT"
done

# Port scanning - Tor exit node (03:00-04:00)
echo "Adding port scanning from Tor..."
SCAN_IP="185.220.101.47"
for i in {1..500}; do
    PATH="${PATHS[$((RANDOM % ${#PATHS[@]}))]}"
    STATUS=404
    SIZE=0
    AGENT="nmap NSE"
    HOUR=3
    TS=$(generate_timestamp $HOUR)
    
    echo "$SCAN_IP - - $TS \"GET $PATH HTTP/1.1\" $STATUS $SIZE \"-\" \"$AGENT\"" >> "$OUTPUT"
done

# Brute-force attempts (03:30-04:30)
echo "Adding brute-force attempts..."
for i in {1..400}; do
    IP="${ATTACK_IPS[$((RANDOM % 3))]}"
    PATH="/admin/login.php"
    STATUS=401
    SIZE=256
    AGENT="curl/7.58.0 (scanner)"
    HOUR=$((3 + RANDOM % 2))
    TS=$(generate_timestamp $HOUR)
    
    echo "$IP - - $TS \"POST $PATH HTTP/1.1\" $STATUS $SIZE \"-\" \"$AGENT\"" >> "$OUTPUT"
done

# DDoS traffic (03:47 - как указано в сюжете)
echo "Adding DDoS pattern..."
for i in {1..200}; do
    IP="${ATTACK_IPS[$((RANDOM % ${#ATTACK_IPS[@]}))]}"
    PATH="/index.html"
    STATUS=503
    SIZE=0
    AGENT="Mozilla/5.0 (Windows NT 6.1)"
    TS="[04/Oct/2025:03:47:$((i % 60)) +0000]"
    
    echo "$IP - - $TS \"GET $PATH HTTP/1.1\" $STATUS $SIZE \"-\" \"$AGENT\"" >> "$OUTPUT"
done

echo "✓ Generated access.log"
echo "✓ Attack window: 03:00-05:00 (4 Oct 2025)"
echo "✓ Primary attacker: 185.220.101.47 (Tor exit node)"
echo "✓ Run: grep '185.220.101.47' access.log | head"
