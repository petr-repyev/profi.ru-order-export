#!/bin/bash

# Client User Agent
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36"

# AUTH TOKEN
TOKEN=$1

# TMP dir
mkdir -p tmp

echo 'Loggin in ...'

# # # # # # # # # # # # # # # # # # # # #
#
# LOGIN 
# 
curl -o tmp/login.html -L -s 'https://profi.ru/backoffice/bill.php?f=profi_bill_mbo_ios&bo_tkn='$TOKEN \
  -H 'authority: profi.ru' \
  -H 'sec-ch-ua: "Chromium";v="94", "Google Chrome";v="94", ";Not A Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'dnt: 1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'sec-fetch-site: none' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-user: ?1' \
  -H 'sec-fetch-dest: document' \
  -H 'accept-language: en-GB,en;q=0.9' \
  -c tmp/cookie.txt \
  --compressed

# Logged in?
if grep -q 'bo-bill-form__input' tmp/login.html; then
    echo OK
else
    echo Login failed. Exit
    exit
fi


# # # # # # # # # # # # # # # # # # # # #
#
# Output CSV file
# 
echo 'O_ID;O_STATUS;O_S_ATTENTION;O_S_STATUS_TEXT;O_S_STATUS_ID;O_CHAT;O_CLIENT;O_PHONE;O_EMAIL;O_REPUTATION;O_ISAVAIL;O_CATEGORY;O_REGION;O_DESCRIPTION;O_STOIMOST;O_NAME;O_VIEWED;O_EXPIRIENCED;O_REVIEWS;O_ZPRICE;C_EXPIRIENCED;C_VERIFIED' > out.csv



# # # # # # # # # # # # # # # # # # # # #
#
# Bills
# 
echo Looking for input source ...
if [ -z "$2" ]
then

  echo "No input specified, checking bills ..."

  curl -o tmp/bills.html -L -s 'https://profi.ru/backoffice/a.php?bills' \
    -H 'authority: profi.ru' \
    -H 'cache-control: max-age=0' \
    -H 'sec-ch-ua: "Chromium";v="94", "Google Chrome";v="94", ";Not A Brand";v="99"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "macOS"' \
    -H 'dnt: 1' \
    -H 'upgrade-insecure-requests: 1' \
    -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36' \
    -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
    -H 'sec-fetch-site: same-origin' \
    -H 'sec-fetch-mode: navigate' \
    -H 'sec-fetch-user: ?1' \
    -H 'sec-fetch-dest: document' \
    -H 'referer: https://profi.ru/backoffice/bill.php' \
    -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8,ru;q=0.7' \
    -b tmp/cookie.txt \
    --compressed

  # Checking HTML format
  echo Checking HTML ...

  if grep -q 'CommonTB1' tmp/bills.html; then
      echo  "OK"
  else
      echo Bills page format error. Exit
      exit
  fi

  xmllint --html --xpath "//*[@id='CommonTB1']/tr/td/i/a" tmp/bills.html | grep -oE "[0-9]+" > tmp/bills-id.html

  sort -u tmp/bills-id.html > tmp/bills-id-uniq.html

else
  sort -u $2 > tmp/bills-id-uniq.html
fi

echo 'Parsing ids ...'

while read -r line;
do

printf .

# GetOrder
ORDER=$(curl -L -s 'https://profi.ru/backoffice/api/' \
  -H 'authority: profi.ru' \
  -H 'sec-ch-ua: "Chromium";v="94", "Google Chrome";v="94", ";Not A Brand";v="99"' \
  -H 'accept: application/json' \
  -H 'dnt: 1' \
  -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundary5fzYpASrPl4ABuqe' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'origin: https://profi.ru' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8,ru;q=0.7' \
  --data-raw $'------WebKitFormBoundary5fzYpASrPl4ABuqe\r\nContent-Disposition: form-data; name="request"\r\n\r\n{"meta":{"method":"getOrder","ui_type":"WEB","ui_app":"WEBBO","ui_ver":"1","ui_os":"0.0"},"data":{"order_id":"'$line$'"}}\r\n------WebKitFormBoundary5fzYpASrPl4ABuqe--\r\n' \
  -b tmp/cookie.txt \
 --compressed)

CLIENT=$(curl -L -s 'https://profi.ru/backoffice/api/' \
  -H 'authority: profi.ru' \
  -H 'sec-ch-ua: "Chromium";v="94", "Google Chrome";v="94", ";Not A Brand";v="99"' \
  -H 'accept: application/json' \
  -H 'dnt: 1' \
  -H 'content-type: multipart/form-data; boundary=----WebKitFormBoundaryhPSABO7gUXnBG7K9' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'origin: https://profi.ru' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-dest: empty' \
  -H 'referer: https://profi.ru/backoffice/r.php?id='$line \
  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8,ru;q=0.7' \
  -b tmp/cookie.txt \
  --data-raw $'------WebKitFormBoundaryhPSABO7gUXnBG7K9\r\nContent-Disposition: form-data; name="request"\r\n\r\n{"meta":{"method":"getKlientInfo","ui_type":"WEB","ui_app":"WEBBO","ui_ver":"1","ui_os":"0.0"},"data":{"order_id":"'$line$'"}}\r\n------WebKitFormBoundaryhPSABO7gUXnBG7K9--\r\n' \
  --compressed)


# PARSING JSON

# ORDER
O_ID=$(echo $ORDER      | jq ".data.order.id")
O_CLNT=$(echo $ORDER    | jq ".data.order.name")
O_PHN=$(echo $ORDER     | jq ".data.order.phone")
O_EML=$(echo $ORDER     | jq ".data.order.email")
O_REP=$(echo $ORDER     | jq ".data.order.repute")
O_ISAVAIL=$(echo $ORDER | jq ".data.order.is_client_info_available")
O_CAT=$(echo $ORDER     | jq ".data.order.original_subjects")
O_REGION=$(echo $ORDER  | jq ".data.order.region")
O_DESC=$(echo $ORDER    | jq ".data.order.aim")
O_STOIM=$(echo $ORDER   | jq ".data.order.full_view.stoim.stoim")
O_NAME=$(echo $ORDER    | jq ".data.order.subjects")
O_VIEW=$(echo $ORDER    | jq ".data.order.view")
O_EXP=$(echo $ORDER     | jq ".data.order.opyt")
O_REV=$(echo $ORDER     | jq ".data.order.otzyv")
O_ZPRICE=$(echo $ORDER  | jq ".data.order.zprice")
O_CHAT=$(echo $ORDER  | jq ".data.order.full_view.report")
O_STATUS=$(echo $ORDER  | jq ".data.order.full_view.history[0]?.txt")
O_PHONES=$(echo $ORDER  | jq ".data.order.full_view.phones")
O_S_ATTENTION=$(echo $ORDER     | jq ".data.order.full_view.status.attention")
O_S_STATUS_TEXT=$(echo $ORDER   | jq ".data.order.full_view.status.s4status")
O_S_STATUS_ID=$(echo $ORDER     | jq ".data.order.full_view.status.status")


# CLIENT
C_EXP=$(echo $CLIENT | jq ".data.title")
C_VRFD=$(echo $CLIENT | jq -r ".data.contacts[]?.title")

echo $O_ID \
';'$O_STATUS \
';'$O_S_ATTENTION \
';'$O_S_STATUS_TEXT \
';'$O_S_STATUS_ID \
';'$O_CHAT \
';'$O_CLNT \
';'$O_PHN \
';'$O_EML \
';'$O_REP \
';'$O_ISAVAIL \
';'$O_CAT \
';'$O_REGION \
';'$O_DESC \
';'$O_STOIM \
';'$O_NAME \
';'$O_VIEW \
';'$O_EXP \
';'$O_REV \
';'$O_ZPRICE \
';'$C_EXP \
';"'$C_VRFD'"' >> out.csv

sleep 1

done < tmp/bills-id-uniq.html

rm -rf tmp

printf "\nDone\n"