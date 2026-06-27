#!/bin/bash
set -e

# Проверка балансировщика (dev)
LB_IP=$(terraform output -raw load_balancer_ip)
echo "Проверяем балансировщик (HTTP): http://$LB_IP"
sleep 60
if curl -s -o /dev/null --max-time 10 http://$LB_IP; then
  echo "Балансировщик отвечает на HTTP"
else
  echo "Балансировщик не отвечает, пересоздаём Floating IP..."
  openstack --os-cloud vkcs floating ip delete "$LB_IP" || echo "Старый IP не удалён, создаём новый"
  NEW_IP=$(openstack --os-cloud vkcs floating ip create internet -c floating_ip_address -f value)
  openstack --os-cloud vkcs floating ip set --port "$(openstack --os-cloud vkcs loadbalancer show lab7-dev-lb -c vip_port_id -f value)" "$NEW_IP"
  echo "Новый Floating IP балансировщика: $NEW_IP"
fi

# Проверка бастиона
BASTION_IP=$(terraform output -raw bastion_public_ip)
echo "Проверяем бастион (пинг): $BASTION_IP"
sleep 10
if ping -c 2 -W 3 "$BASTION_IP" > /dev/null 2>&1; then
  echo "Бастион пингуется успешно"
else
  echo "Бастион не пингуется, пересоздаём Floating IP..."
  openstack --os-cloud vkcs floating ip delete "$BASTION_IP" || echo "Старый IP не удалён, создаём новый"
  NEW_IP=$(openstack --os-cloud vkcs floating ip create internet -c floating_ip_address -f value)
  BASTION_PORT=$(openstack --os-cloud vkcs port list --server lab7-dev-bastion -c ID -f value | head -1)
  openstack --os-cloud vkcs floating ip set --port "$BASTION_PORT" "$NEW_IP"
  echo "Новый Floating IP бастиона: $NEW_IP"
fi