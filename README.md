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
eval "$(ssh-agent -s)"
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
node1 ansible_host=192.168.40.10 etcd_member_name=etcd1

[etcd:children]
kube_control_plane

[kube_node]
node2 ansible_host=192.168.40.8
node3 ansible_host=192.168.40.31
EOF
```

Запуск установки kubespray

```bash
ansible-playbook -i inventory/sample/inventory.ini -b -v --private-key ~/.ssh/nt_test cluster.yml

```

Скопировать конфиг себе на ВМ

```bash
ssh ubuntu@192.168.40.10 "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config
```

Отредактировать конфиг `nano ~/.kube/config`

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ...
    server: https://192.168.40.10:6443 # изменить на локальный адрес control plane ноды
  name: cluster.local
...
```

Устанавливаем `nginx ingress controller`

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl patch svc ingress-nginx-controller -n ingress-nginx \
  -p '{"spec":{"externalTrafficPolicy":"Cluster"}}'

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

Настраиваем работу Grafana по пути `/grafana`
```bash
kubectl -n monitoring set env deployment/grafana \
  GF_SERVER_ROOT_URL="http://158.160.177.192/grafana" \
  GF_SERVER_SERVE_FROM_SUB_PATH="true"
kubectl -n monitoring rollout restart deployment/grafana
```

Ingress манифест для Grafana

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /grafana
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
```

<img width="1164" height="564" alt="изображение" src="https://github.com/user-attachments/assets/186fbbd2-028d-4e5d-95fc-61f4b62e11e7" />


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

### Настройка Atlantis

Подготовка бинарника Terraform
```bash
docker run --name=tf hashicorp/terraform:1.12.2
docker cp tf:/bin/terraform /tmp/terraform1.12.2
docker rm tf
```
Настройка Github:
* Необходимо создать сервисный аккаунт Github, который будет использовать Atlantis;
* У этого аккаунта создать personal access token c правами на `repo`;
* Дать сервисному аккаунту доступ к репозиторию в Collaborators;

<img width="1284" height="702" alt="diplom-collaborators" src="https://github.com/user-attachments/assets/47814f69-0b99-4c47-99ad-4bb9b56922d1" />

* Настроить вебхук, который будет отправляться на сервер Atlantis при пул реквестах и коммитах;
  - Тип - `applicatin/json`;
  - Установить секретный токен `ATLANTIS_GH_WEBHOOK_SECRET` для защиты;
  - Events (проставить галочки): Issue comments, Pull requests, Pushes;

 <img width="1221" height="883" alt="diplom-webhook" src="https://github.com/user-attachments/assets/928bfe3a-95f0-43e9-acfc-bcc381d5f621" />

* Установить защиту main-ветки репозитория;

<img width="926" height="927" alt="diplom-branch" src="https://github.com/user-attachments/assets/1e444b99-5fa0-4b50-a84f-3f26ec034b7e" />

Подготовка VM Atlantis
```bash
export ATLANTIS_IP=$(terraform output -raw tf_atlantis_vm_ip)
scp /tmp/terraform1.12.2 ubuntu@$ATLANTIS_IP:/tmp/terraform1.12.2
scp ~/.ssh/nt_test.pub ubuntu@$ATLANTIS_IP:/tmp/nt_test.pub
scp ~/yc_tf_key.json ubuntu@$ATLANTIS_IP:/tmp/yc_tf_key.json
```

Далее на VM Atlantis:

```bash
ssh ubuntu@$ATLANTIS_IP
```

Установка Docker

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

Подготовка конфига для работы Atlantis
```bash
mkdir ~/atlantis-data
mkdir ~/atlantis-data/bin
mv /tmp/nt_test.pub ~/atlantis-data/nt_test.pub
mv /tmp/terraform1.12.2 ~/atlantis-data/bin/terraform1.12.2 && chmod +x ~/atlantis-data/bin/terraform1.12.2
mv /tmp/yc_tf_key.json ~/atlantis-data/yc_tf_key.json
chmod 644 ~/atlantis-data/nt_test.pub
chmod 644 ~/atlantis-data/yc_tf_key.json

cat <<EOF > ~/atlantis-data/.terraformrc
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF
```

Создаем `.env` файл с секретами
```bash
HOME=/home/ubuntu
ATLANTIS_GH_WEBHOOK_SECRET=
ATLANTIS_URL=http://...
YC_SECRET_ACCESS_KEY=
YC_ACCESS_KEY_ID=
TF_VAR_folder_id=
TF_VAR_cloud_id=
TF_VAR_token=
GH_BOT_TOKEN=
GH_BOT_USER=ygatlantisbot
GH_REPO=github.com/yagavrin/devops-diplom
SSH_PUB_KEY_NAME=nt_test.pub
TF_VERSION=v1.12.2
```

`compose.yaml` для запуска Atlantis

```yaml
services:
  atlantis:
    image: runatlantis/atlantis
    container_name: atlantis
    restart: unless-stopped
    ports:
      - "4141:4141"
    volumes:
      - ${HOME}/atlantis-data:/atlantis-data
      - ${HOME}/atlantis-data/.terraformrc:/home/atlantis/.terraformrc:ro
      - ${HOME}/atlantis-data/nt_test.pub:/home/atlantis/.ssh/${SSH_PUB_KEY_NAME}:ro
      - ${HOME}/atlantis-data/yc_tf_key.json:/home/atlantis/yc_tf_key.json:ro
    environment:
      TF_LOG: TRACE
      TF_LOG_PATH: /atlantis-data/tf.log
      ATLANTIS_GH_WEBHOOK_SECRET: ${ATLANTIS_GH_WEBHOOK_SECRET}
      TF_CLI_CONFIG_FILE: /home/atlantis/.terraformrc
      AWS_ACCESS_KEY_ID: ${YC_ACCESS_KEY_ID}
      AWS_SECRET_ACCESS_KEY: ${YC_SECRET_ACCESS_KEY}
      TF_VAR_folder_id: ${TF_VAR_folder_id}
      TF_VAR_cloud_id: ${TF_VAR_cloud_id}
      TF_VAR_ssh_pub_key_path: /home/atlantis/.ssh/${SSH_PUB_KEY_NAME}
      GH_BOT_TOKEN: ${GH_BOT_TOKEN}
    command: >
      server
      --data-dir=/atlantis-data
      --atlantis-url="${ATLANTIS_URL}"
      --repo-allowlist="${GH_REPO}"
      --gh-user="${GH_BOT_USER}"
      --gh-token="${GH_BOT_TOKEN}"
      --gh-webhook-secret="${ATLANTIS_GH_WEBHOOK_SECRET}"
      --default-tf-version="${TF_VERSION}"
```

Пример завершенного пулл реквеста:
https://github.com/yagavrin/devops-diplom/pull/4

