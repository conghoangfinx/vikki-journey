#!/bin/bash

# Kiểm tra SSH Tunnel
echo "🔍 Kiểm tra SSH tunnel trên cổng 8002..."
if lsof -i :8002 >/dev/null; then
  echo "✅ SSH tunnel đã được thiết lập!"
else
  echo "🚀 Thiết lập SSH tunnel đến 10.0.119.12:17000 qua bastion...."
  ssh -f -N -L 8002:10.0.119.12:17000 bastion-01.nonprod.galaxyfinx.in
  sleep 2  # Đợi kết nối ổn định
  if lsof -i :8002 >/dev/null; then
    echo "✅ SSH tunnel thiết lập thành công!"
  else
    echo "❌ Không thể thiết lập SSH tunnel! Dừng script."
    exit 1
  fi
fi
