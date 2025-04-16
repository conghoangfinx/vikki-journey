#!/bin/bash

echo "🔍 Đang tìm SSH tunnel trên cổng 8001..."
PID=$(lsof -ti tcp:8001)

if [ -n "$PID" ]; then
  echo "🛑 Đang ngắt kết nối SSH tunnel (PID: $PID)..."
  kill "$PID"
  sleep 1
  if lsof -i :8001 >/dev/null; then
    echo "❌ Không thể ngắt tunnel!"
  else
    echo "✅ Đã ngắt SSH tunnel thành công!"
  fi
else
  echo "ℹ️ Không tìm thấy SSH tunnel nào trên cổng 8001."
fi

