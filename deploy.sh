#!/bin/bash
set -e

echo "=== Hookah Mixes Deploy ==="

# Install dependencies
echo "[1/5] Устанавливаю зависимости..."
apt-get update -qq
apt-get install -y -qq python3-pip python3-venv postgresql-client > /dev/null 2>&1

# Setup project
APP_DIR="/opt/hookah-mixes"
echo "[2/5] Настраиваю проект в $APP_DIR..."
mkdir -p $APP_DIR
cp -r /tmp/hookah-mixes/* $APP_DIR/
cd $APP_DIR

python3 -m venv venv
source venv/bin/activate
pip install -q -r requirements.txt

# Init database
echo "[3/5] Инициализирую базу данных..."
PGPASSWORD=hookah123 psql -h localhost -U hookah -d hookah_db -f schema.sql 2>/dev/null || {
    echo "  Таблицы уже существуют или ошибка — пропускаю..."
}

# Create systemd service
echo "[4/5] Создаю systemd сервис..."
cat > /etc/systemd/system/hookah-mixes.service << 'EOF'
[Unit]
Description=Hookah Mixes Web App
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hookah-mixes
Environment=PATH=/opt/hookah-mixes/venv/bin:/usr/bin
ExecStart=/opt/hookah-mixes/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8080
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hookah-mixes
systemctl restart hookah-mixes

echo "[5/5] Готово!"
echo ""
echo "========================================="
echo "  Сайт доступен: http://$(hostname -I | awk '{print $1}'):8080"
echo "========================================="
echo ""
echo "Управление:"
echo "  systemctl status hookah-mixes"
echo "  systemctl restart hookah-mixes"
echo "  journalctl -u hookah-mixes -f"
