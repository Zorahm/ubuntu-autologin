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

echo "Файл $AUTOLOGIN_FILE создан или обновлен."

# Перезагрузка конфигурации systemd
systemctl daemon-reload
echo "Конфигурация systemd обновлена."

# Проверка, установлен ли SSH-клиент
if ! command -v ssh >/dev/null 2>&1; then
  echo "SSH-клиент не установлен. Устанавливаем openssh-client..."
  apt update && apt install -y openssh-client
fi

# Проверка, установлен ли и запущен ли SSH-сервер
if ! systemctl is-active ssh >/dev/null 2>&1; then
  echo "SSH-сервер не запущен. Устанавливаем и запускаем openssh-server..."
  apt update && apt install -y openssh-server
  systemctl enable ssh
  systemctl start ssh
fi

# Тест SSH-подключения к localhost
echo "Проверка SSH-подключения к localhost для root..."
ssh -o BatchMode=yes -o ConnectTimeout=5 root@localhost 'echo "SSH работает: подключение к localhost успешно!"' || {
  echo "Ошибка: не удалось подключиться по SSH к localhost."
  echo "Проверьте, разрешен ли вход для root в /etc/ssh/sshd_config (PermitRootLogin yes)."
  exit 1
}

# Сообщение о завершении
echo "Настройка автоматического входа для root завершена."
echo "SSH-подключение к localhost проверено успешно."
echo "Перезагрузите сервер командой 'sudo reboot', чтобы применить автологин."