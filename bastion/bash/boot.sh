#!/bin/bash
echo start boot.sh

# BOOT_FILE_NAME環境変数を取得
boot_file_name=$BOOT_FILE_NAME
combined_string="/bastion/bash/${boot_file_name}.sh"

chmod +x $combined_string
$combined_string


echo end boot.sh
