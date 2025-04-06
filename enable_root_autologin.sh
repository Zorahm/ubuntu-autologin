#!/bin/bash

# Проверка, запущен ли скрипт с правами root
if [ "$EUID" -ne 0 ]; then
  echo "Этот скрипт нужно запускать с правами root (sudo)."
  exit 1
fi

# Создание директории, если она не существует
GETTY_DIR="/etc/systemd/system/getty@tty1.service.d"
if [ ! -d "$GETTY_DIR" ]; then
  mkdir -p "$GETTY_DIR"
  echo "Создана директория $GETTY_DIR"
fi

# Создание или перезапись файла autologin.conf
AUTOLOGIN_FILE="$GETTY_DIR/autologin.conf"
cat << EOF > "$AUTOLOGIN_FILE"
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOF

echo "Файл $AUTOLOGIN_FILE создан или обновлён."

# Перезагрузка конфигурации systemd
systemctl daemon-reload
echo "Конфигурация systemd обновлена."

# Сообщение о завершении
echo "Настройка автоматического входа для root завершена."
echo "Перезагрузите сервер командой 'sudo reboot', чтобы применить изменения."