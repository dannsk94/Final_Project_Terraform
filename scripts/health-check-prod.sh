#!/bin/bash
set -e

# Проверка балансировщика (prod)
LB_IP=$(terraform output -raw load_balancer_ip)
echo "Проверяем балансировщик (пинг): $LB_IP"
sleep 60
if ping -c 2 -W 3 "$LB_IP" > /dev/null 2>&1; then
  echo "Балансировщик пингуется успешно"
else
  echo "Балансировщик не пингуется, пересоздаём Floating IP..."
  OLD_IP=$(openstack floating ip list --fixed-ip-address "$(terraform output -raw lb_internal_ip)" -c "Floating IP Address" -f value)
  openstack floating ip delete "$OLD_IP"
  NEW_IP=$(openstack floating ip create internet -c floating_ip_address -f value)
  openstack floating ip set --port "$(openstack loadbalancer show lab7-prod-lb -c vip_port_id -f value)" "$NEW_IP"
  echo "Новый Floating IP балансировщика: $NEW_IP"
fi

# Проверка бастиона (prod)
BASTION_IP=$(terraform output -raw bastion_public_ip)
echo "Проверяем бастион (пинг): $BASTION_IP"
sleep 10
if ping -c 2 -W 3 "$BASTION_IP" > /dev/null 2>&1; then
  echo "Бастион пингуется успешно"
else
  echo "Бастион не пингуется, пересоздаём Floating IP..."
  OLD_IP=$(openstack floating ip list --fixed-ip-address "$(terraform output -raw bastion_private_ip)" -c "Floating IP Address" -f value)
  openstack floating ip delete "$OLD_IP"
  NEW_IP=$(openstack floating ip create internet -c floating_ip_address -f value)
  BASTION_PORT=$(openstack port list --server lab7-prod-bastion -c ID -f value | head -1)
  openstack floating ip set --port "$BASTION_PORT" "$NEW_IP"
  echo "Новый Floating IP бастиона: $NEW_IP"
fi