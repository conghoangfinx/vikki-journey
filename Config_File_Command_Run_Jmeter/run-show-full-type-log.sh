#!/bin/bash

# Cấu hình đường dẫn
JMETER_HOME="/Users/conghoang/apache-jmeter-5.6.3-backup-xlsx/bin"
TEST_PLAN="/Users/conghoang/Desktop/vikki-journey/Test_Whitelist_Auto_Unlink/vikki-journey-conghoang-qa-test-whitelist.jmx"
LOGS_FOLDER="/Users/conghoang/Desktop/logs"
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"

# Ghi nhận thời gian bắt đầu
START_TIMESTAMP=$(date +%s)
START_TIME_FORMATTED=$(date -r "$START_TIMESTAMP" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -d "@$START_TIMESTAMP" "+%Y-%m-%d %H:%M:%S")

# Chạy JMeter
cd "$JMETER_HOME" || { echo "❌ Không thể vào thư mục JMeter!"; exit 1; }
chmod +x jmeter.sh
mkdir -p "$LOGS_FOLDER"
LOG_FILE="$LOGS_FOLDER/jmeter.log"

# Bắt đầu theo dõi log theo thời gian thực
tail -f "$LOG_FILE" &  # Thêm lệnh này để xem log thời gian thực
TAIL_PID=$!  # Lưu PID của tail để có thể dừng sau khi test xong

# Chạy JMeter
./jmeter.sh -n -t "$TEST_PLAN" -j "$LOG_FILE" &
JMETER_PID=$!
wait $JMETER_PID
EXIT_CODE=$?

# Dừng theo dõi log khi test kết thúc
kill $TAIL_PID  # Dừng tail khi test xong

# Ghi nhận thời gian kết thúc
END_TIMESTAMP=$(date +%s)
DURATION=$((END_TIMESTAMP - START_TIMESTAMP))
DURATION_FORMATTED=$(printf "%02d:%02d" $((DURATION/60)) $((DURATION%60)))

# Lọc thông tin từ file log
LOG_INFO=$(grep "INFO" "$LOG_FILE" | grep -Ev "Thread is done|Thread finished|Notifying test listeners|summary \+|summary =" | tail -n 10 | awk '{print "- " $0}' | sed ':a;N;$!ba;s/\n/\\n/g')

# Lọc các lỗi thực sự (dòng có chứa [ERROR])
ERROR_LOGS=$(grep "\[ERROR\]" "$LOG_FILE" | tail -n 10)

# Lấy các dòng tiếp theo sau thông báo lỗi để hiển thị thêm chi tiết (Full Response)
ERROR_DETAILS=$(grep -A 5 "\[ERROR\]" "$LOG_FILE" | tail -n 5)

# Kiểm tra nếu có lỗi thực sự
ERROR_FOUND=$(grep "\[ERROR\]" "$LOG_FILE" | wc -l)

# Xác định trạng thái test
if [ "$ERROR_FOUND" -gt 0 ] || [ "$EXIT_CODE" -ne 0 ]; then
    STATUS="❌ *JMeter Test Failed!*"
    COLOR="#ff0000"
else
    STATUS="✅ *JMeter Test Passed!*"
    COLOR="#36a64f"
fi

# Tạo message JSON cho Slack
MESSAGE=$(jq -n --arg status "$STATUS" --arg duration "$DURATION_FORMATTED" --arg startTime "$START_TIME_FORMATTED" --arg logFile "$LOG_FILE" --arg logInfo "$LOG_INFO" --arg errorLogs "$ERROR_LOGS" --arg errorDetails "$ERROR_DETAILS" --arg color "$COLOR" '{
  "attachments": [
    {
      "color": $color,
      "blocks": [
        { "type": "section", "text": { "type": "mrkdwn", "text": "🚀 *JMeter Test Report*" } },
        { "type": "section", "fields": [
            { "type": "mrkdwn", "text": "*Status:* \($status)" },
            { "type": "mrkdwn", "text": "*Start Time:* \($startTime // "N/A")" },
            { "type": "mrkdwn", "text": "*Total Time:* \($duration)" }
        ] },
        { "type": "section", "text": { "type": "mrkdwn", "text": "📄 *JMeter Log File:* \n\($logFile)" } },
        { "type": "section", "text": { "type": "mrkdwn", "text": "📝 *Info Logs:* \n\($logInfo)" } },
        { "type": "section", "text": { "type": "mrkdwn", "text": "❗ *Error Logs:* \n\($errorLogs)" } },
        { "type": "section", "text": { "type": "mrkdwn", "text": "⚠️ *Error Details (Next Lines):* \n\($errorDetails)" } }
      ]
    }
  ]
}')

# Gửi báo cáo tới Slack
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H 'Content-type: application/json' --data "$MESSAGE" "$SLACK_WEBHOOK_URL")

# Kiểm tra phản hồi từ Slack
if [ "$RESPONSE" -ne 200 ]; then
    echo "❌ Gửi thông báo Slack thất bại! Mã lỗi HTTP: $RESPONSE"
else
    echo "✅ Đã gửi thông báo lên Slack thành công!"
fi
