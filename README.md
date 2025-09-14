### Создание инфраструктуры

Подготовка сервисного аккаунта для Terraform с необходимыми правами

```bash
sudo apt install jq -y

TF_SA_NAME=sa-terraform
yc iam service-account create --name "$TF_SA_NAME"
TF_SA_ID=$(yc iam service-account get --name "$TF_SA_NAME" --format json | jq -r .id)
FOLDER_ID=$(yc config get folder-id)
# VPC (networks, subnets, SGs, IPs)
yc resource-manager folder add-access-binding $FOLDER_ID   --role vpc.admin --subject serviceAccount:$TF_SA_ID

# Network Load Balancer 
yc resource-manager folder add-access-binding $FOLDER_ID   --role load-balancer.admin --subject serviceAccount:$TF_SA_ID

yc resource-manager folder add-access-binding $FOLDER_ID   --role compute.admin --subject serviceAccount:$TF_SA_ID

yc resource-manager folder add-access-binding $FOLDER_ID   --role container-registry.admin --subject serviceAccount:$TF_SA_ID

# For creating/reading service accounts & keys
yc resource-manager folder add-access-binding $FOLDER_ID   --role iam.serviceAccounts.admin --subject serviceAccount:$TF_SA_ID

yc resource-manager folder add-access-binding $FOLDER_ID   --role admin --subject serviceAccount:$TF_SA_ID

yc iam key create --service-account-id "$TF_SA_ID" --output ~/yc_tf_key.json
```

Создание backend для Terraform

```bash
cd src/backend/bootstrap
terraform init
terraform apply
export YC_ACCESS_KEY_ID=$(terraform output -raw tf_backend_access_key)
export YC_SECRET_ACCESS_KEY=$(terraform output -raw tf_backend_secret_key
cd ../infrastructure
terraform init -backend-config="access_key=${YC_ACCESS_KEY_ID}" -backend-config="secret_key=${YC_SECRET_ACCESS_KEY}"
```

Создание инфраструктуры

```bash
cd ../infrastructure
terraform apply
```


### Развертывание K8s кластера 

Подготовка VM для развертывания K8s кластера
```bash
export BASTION_IP=$(terraform output -raw tf_bastion_ip)
export YCR_SA_PULLER_ID=$(terraform output -raw ycr_sa_puller_id)
```
Копируем ключ доступа
```bash
scp ~/.ssh/nt_test ubuntu@$BASTION_IP:~/.ssh/
scp ~/.ssh/nt_test.pub ubuntu@$BASTION_IP:~/.ssh/
```

Создаем авторизованный ключ доступа для Registry

```bash
yc iam key create --service-account-name $YCR_SA_PULLER_ID --output puller_key.json
scp puller_key.json ubuntu@$BASTION_IP:~/puller_key.json
```

**Дальнейшие действия на VM bastion:**

```bash
ssh ubuntu@$BASTION_IP
```

Установка kubectl

```bash
mkdir ~/.kube
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
```

Добавляем ssh-ключ для Ansible

```bash
eval "$(ssh-agent -s)
ssh-add ~/.ssh/nt_test

ssh-add -l
```

Скачиваем и подготавливаем Kubespray

```bash
sudo apt update
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout v2.28.0
sudo apt install python3.11-venv python3-pip -y
python3.11 -m venv venv && source venv/bin/activate
pip install -r requirements.txt ansible-core~=2.16.4
```

Настраиваем inventory

```bash
cat <<EOF > inventory/sample/inventory.ini
[all:vars]
ansible_user=ubuntu
[kube_control_plane]
node1 ansible_host=192.168.40.30 etcd_member_name=etcd1

[etcd:children]
kube_control_plane

[kube_node]
node2 ansible_host=192.168.40.31
node3 ansible_host=192.168.40.16
EOF
```

Запуск установки kubespray

```bash
ansible-playbook -i inventory/sample/inventory.ini -b -v --private-key ~/.ssh/nt_test cluster.yml --tags=kubeconfig
```

### Установка системы мониторинга в кластер

```bash
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus
```

Настраиваем NetworkPolicy для Grafana для корректной работы с ingress:

```bash
nano manifests/grafana-networkPolicy.yaml
```

```yaml
...
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    - namespaceSelector:  # Allow ingress-nginx namespace
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
...
```

Применяем манифесты:

```bash
kubectl apply --server-side -f manifests/setup
kubectl wait --for=condition=Established --all CustomResourceDefinition --timeout=60s
kubectl apply -f manifests/
```

### Настройка CI/CD

Создаем секрет с конфигурацией подключения к Yandex Registry

```bash
kubectl create secret docker-registry yc-registry-secret   --docker-server=cr.yandex   --docker-username=json_key   --docker-password="$(cat ~/puller_key.json)"   --docker-email=y.gavrinskiy@mail.ru   -n default
```

Настройка GitHub Actions

Создаем секреты в env `prod`:

- `BASTION_HOST`
- `BASTION_SSH_PRIVATE_KEY`
- `BASTION_USER`
- `SSH_PASSPHRASE`
- `YC_SA_ID` - сервисный аккаунт с правами push в Registry (`ycr-sa`)

<img width="869" height="493" alt="изображение" src="https://github.com/user-attachments/assets/5df1264d-2ca2-49b5-a7b7-37a4784fd6a5" />

Настраиваем федерацию аккаунтов между GitHub и Yandex Cloud:

- **Issuer (iss):** `https://token.actions.githubusercontent.com`  
- **Audience (aud):** `https://github.com/yagavrin`  
- **JWKS адрес:** `https://token.actions.githubusercontent.com/.well-known/jwks`  
- **Имя:** `github-wif`  

<img width="621" height="646" alt="изображение" src="https://github.com/user-attachments/assets/1170ae5e-37b4-43e4-a904-76a0c7a79f2a" />

Привязываем сервисный аккаунт (`ycr_sa`) с параметром:

```
Sub: repo:yagavrin/devops-diplom-app:environment:prod
```

### Запускаем тестовое приложение Nginx

```bash
kubectl apply -f nginx-deployment.yaml
```
