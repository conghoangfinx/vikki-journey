#!/bin/bash

# Đảm bảo đường dẫn đúng đến thư mục JMeter
cd /Users/conghoang/apache-jmeter-5.6.3-backup/bin

# Kiểm tra và cấp quyền cho jmeter.sh
chmod +x jmeter.sh

# Tạo thư mục báo cáo vào Desktop và xóa thư mục báo cáo nếu có
REPORT_FOLDER="/Users/conghoang/Desktop/report_folder"
LOGS_FOLDER="/Users/conghoang/Desktop/logs"
RESULTS_FOLDER="/Users/conghoang/Desktop/results"

# Xóa thư mục báo cáo nếu đã tồn tại và tạo lại thư mục trống
if [ -d "$REPORT_FOLDER" ]; then
  rm -rf "$REPORT_FOLDER"
fi
mkdir -p "$REPORT_FOLDER"

# Đảm bảo đường dẫn log file đúng
mkdir -p "$LOGS_FOLDER"
mkdir -p "$RESULTS_FOLDER"

chmod -R 777 "$REPORT_FOLDER"
chmod -R 777 "$LOGS_FOLDER"

# Xóa tệp kết quả cũ nếu tồn tại
if [ -f "$RESULTS_FOLDER/results.jtl" ]; then
  rm -f "$RESULTS_FOLDER/results.jtl"
fi

# Chạy JMeter với các tham số đầy đủ và chính xác trong nền
./jmeter.sh -n -t /Users/conghoang/Desktop/vikki-journey/Test_Whitelist_Auto_Unlink/vikki-journey-conghoang-qa-test-whitelist.jmx -l "$RESULTS_FOLDER/results.jtl" -e -o "$REPORT_FOLDER" -j "$LOGS_FOLDER/jmeter.log" &

# Theo dõi log trong thời gian thực
tail -f "$LOGS_FOLDER/jmeter.log"
