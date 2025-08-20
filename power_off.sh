#!/bin/sh

echo -e "Входные данные:\n
         VM_FILE=$VM_FILE\n
         CLOUDATE_TOKEN=$CLOUDATE_TOKEN\n
         ZABBIX_TOKEN=$ZABBIX_TOKEN\n"

while IFS= read -r vm_ID;
do
  response=$(curl -s -X GET "https://cloudate.digitalleague.ru/api/client/orders/$vm_ID" --header "Content-Type: application/json" --header "Token: $CLOUDATE_TOKEN" | jq -c)

  if [ -z "$response" ]; then
    echo "Не удалось получить информацию о ВМ c id: $vm_ID"
    continue
  fi

  name=$(echo "$response" | jq -r .name)
  ip=$(echo "$response" | jq -r .ip)
  echo -e "\n|==========================| Работам с $name - $ip, vm_ID: $vm_ID |==========================|"
  
  echo "Выключаем ВМ"
  power_off=$(curl -s -X PUT "https://cloudate.digitalleague.ru/api/client/orders/$vm_ID" \
    --header "Content-Type: application/json" \
    --header "Token: $CLOUDATE_TOKEN" \
    --data '{"signal":"power_off"}' | jq -r .state)
  echo "Статус: $power_off"

  echo "Получаем hostid для ВМ в zabbix"
  zabbix_hostid=$(curl -s -X POST "http://zabbix.sed.rtech.ru/api_jsonrpc.php" \
    --header 'Content-Type: application/json' \
    --data-raw '{
      "jsonrpc": "2.0",
      "method": "host.get",
      "params": {
          "output": ["hostid"],
          "filter": {
              "ip": ["'"$ip"'"]
          }
      },
      "auth": "'"$ZABBIX_TOKEN"'",
      "id": 1
    }' | jq -r .result[].hostid)
    echo "Получен hostid: $zabbix_hostid"

    echo "Выключаем отслеживание ВМ в zabbix"
    curl -s -X POST "http://zabbix.sed.rtech.ru/api_jsonrpc.php" \
      --header 'Content-Type: application/json' \
      --data-raw '{
        "jsonrpc": "2.0",
        "method": "host.update",
        "params": {
            "hostid": "'"$zabbix_hostid"'",
            "status": "1"
        },
        "auth": "'"$ZABBIX_TOKEN"'",
        "id": 1
      }' >> /dev/null
    zabbix_status=$(curl -s -X POST "http://zabbix.sed.rtech.ru/api_jsonrpc.php" \
    --header 'Content-Type: application/json' \
    --data-raw '{
      "jsonrpc": "2.0",
      "method": "host.get",
      "params": {
          "filter": {
              "ip": ["'"$ip"'"]
          }
      },
      "auth": "'"$ZABBIX_TOKEN"'",
      "id": 1
    }' | jq -r .result[].status)
    echo "Статус ВМ в zabbix: $zabbix_status"

done < "$VM_FILE"