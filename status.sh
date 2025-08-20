#!/bin/sh

echo -e "Входные данные:\n
         VM_FILE=$VM_FILE\n
         CLOUDATE_TOKEN=$CLOUDATE_TOKEN\n
         ZABBIX_TOKEN=$ZABBIX_TOKEN\n"

VM_FILE_OLD="$VM_FILE"

while IFS= read -r vm_ID;
do
  response=$(curl -s -X GET "https://cloudate.digitalleague.ru/api/client/orders/$vm_ID" --header "Content-Type: application/json" --header "Token: $CLOUDATE_TOKEN" | jq -c)

  if [ -z "$response" ]; then
    echo "Не удалось получить информацию о ВМ c id: $vm_ID"
    continue
  fi

  if [ "$VM_FILE" == "at-consulting" ]; then
    VM_FILE="at\-consulting"
  fi

  name=$(echo "$response" | jq -r .name)
  ip=$(echo "$response" | jq -r .ip)

  ping -c 1 "$ip" >> /dev/null

  if [ $? -eq 0 ]; then
    state="включена"
    echo "on" >> appender
  else
    state="выключена"
    echo "off" >> appender
  fi

  echo -e "\n|==============================| vm_ID: $vm_ID |==============================|"
  echo "Название ВМ: $name"
  echo "IP: $ip"
  echo "Статус ВМ: $state"

done < "$VM_FILE"

if [ $(cat appender | grep -iv "off" | wc -l) -eq 0 ]; then
  echo -e "\n|===============|\nСтенд $VM_FILE_OLD выключен\n|===============|"
  bash appender.sh "Стенд $VM_FILE выключен"
elif [ $(cat appender | grep -iv "on" | wc -l) -eq 0 ]; then
  echo -e "\n|===============|\nСтенд $VM_FILE_OLD включен\n|===============|"
  bash appender.sh "Стенд $VM_FILE включен"
else
  echo -e "\n|===============|\nСтенд находится в процессе выключения/включения, повторите запрос статуса\n|===============|"
fi

rm appender