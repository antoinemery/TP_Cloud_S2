# I. Premiers pas Ansible

Dans cette partie, je vous fait :

- setup une install d'Ansible sur votre PC
- on prépare les VMs
- **et on déploie de la conf !**

## Sommaire

- [I. Premiers pas Ansible](#i-premiers-pas-ansible)
  - [Sommaire](#sommaire)
  - [1. Mise en place](#1-mise-en-place)
    - [A. Setup Azure](#a-setup-azure)
    - [B. Setup sur votre poste](#b-setup-sur-votre-poste)
  - [2. La commande `ansible`](#2-la-commande-ansible)
  - [3. Un premier playbook](#3-un-premier-playbook)
  - [3. Création de nouveaux playbooks](#3-création-de-nouveaux-playbooks)
    - [A. NGINX](#a-nginx)
    - [B. MariaDB ou MySQL](#b-mariadb-ou-mysql)
- [III. Repeat](#iii-repeat)

## 1. Mise en place

### A. Setup Azure

➜ **Préparez un plan Terraform `main.tf`** (dans un nouveau répertoire de travail dédié à ce TP)

- il crée 2 VMs
- chacune doit être joignable en SSH depuis votre poste
- doit utiliser une image proposée par Azure un minimum à jour
- ajouter une conf `cloud-init.txt` :
  - Ansible et Python installés (référez-vous à la doc d'install de Ansible pour votre l'OS que vous avez choisi)
  - création d'un user qui a accès aux droits `root` avec la commande `sudo`
  - je vous conseille une conf en `NOPASSWD` pour ne pas avoir à saisir votre password à chaque déploiement
  - ce user a une clé publique pour vous y connecter sans mot de passe

🌞 **Vous me livrerez vos deux fichiers en compte-rendu**

- `main.tf` (et éventuellement d'autres fichiers `.tf`)
- `cloud-init.txt`

    ### [Fichier main.tf](terraform/main.tf)
    ### [Fichier cloud-init.txt](terraform/cloud-init.txt)
---

### B. Setup sur votre poste

➜ **Installez Ansible sur votre machine**

- il vous faudra aussi Python
- suivez [la doc officielle pour l'install](https://docs.ansible.com/ansible/latest/installation_guide/index.html)

➜ **Toujours dans le même répertoire de travail sur votre PC, créez un dossier `ansible/`**

- il accueillera le code Ansible pour ce TP

➜ **Préparez la connexion Ansible aux VMs**

- créez un fichier `ansible/.ssh-config` avec le contenu suivant

```ssh-config
Host 10.3.1.*
  User <VOTRE_USER>
  IdentityFile <VOTRE_CLE_PRIVEE>
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentitiesOnly yes
  LogLevel FATAL
```

- créez un fichier `ansible.cfg` avec le contenu suivant

```ini
[ssh_connection]
ssh_args = -F ./.ssh-config
```

> Si vous êtes pas trop bordéliques, vous avez donc actuellement dans votre répertoire de travail : `main.tf`, `cloud-init.txt` et le dossier `ansible/` qui contient le fichier `ansible/.ssh-config`.

## 2. La commande `ansible`

On va enfin utiliser un peu Ansible !

➜ Pour cela, **créez un fichier `ansible/hosts.ini`** avec le contenu suivant :

```ini
[tp3]
<IP DE LA PREMIERE VM>
<IP DE LA DEUXIEME VM>
```

On va commencer avec quelques commandes Ansible pour exécuter des tâches *ad-hoc* : c'est à dire des tâches one shot depuis la ligne de commandes.

```bash
$ cd ansible

# lister les hôtes que Ansible voit dans notre inventaire
$ ansible -i hosts.ini tp3 --list-hosts

# tester si ansible est capable d'interagir avec les machines
$ ansible -i hosts.ini tp3 -m ping

# afficher toutes les infos que Ansible est capable de récupérer sur chaque machine
$ ansible -i hosts.ini tp3 -m setup

# exécuter une commande sur les machines distantes
$ ansible -i hosts.ini tp3 -m command -a 'uptime'

# exécuter une commande en root
$ ansible -i hosts.ini tp3 --become -m command -a 'reboot'
```

## 3. Un premier playbook

Enfin, on va écrire un peu de code Ansible.  
On va commencer simple et faire un *playbook* en un seul fichier, pour prendre la main sur la syntaxe, et faire un premier déploiement.

➜ **créez un fichier `first.yml`**, notre premier *playbook* :

```yaml
---
- name: Install nginx
  hosts: tp3
  become: true

  tasks:
  - name: Install nginx
    dnf:
      name: nginx
      state: present

  - name: Insert Index Page
    template:
      src: index.html.j2
      dest: /usr/share/nginx/html/index.html

  - name: Start NGiNX
    service:
      name: nginx
      state: started
```

> Chaque élément de cette liste YAML est donc une *task* Ansible. Les mots-clés `yum`, `template`, `service` sont des *modules* Ansible.

➜ **Et un fichier `index.html.j2` dans le même dossier**

```jinja2
Hello from {{ ansible_default_ipv4.address }}
```

➜ **Exécutez le playbook**

```bash
$ ansible-playbook -i hosts.ini first.yml
```

> N'oubliez pas d'ouvrir le port 80 avec une règle Azure (modifiez et ré-appliquez votre fichier `main.tf`).

## 3. Création de nouveaux playbooks

### A. NGINX

➜ **Créez un *playbook* `nginx.yml`**

- déploie un serveur NGINX
- génèreérer un certificat et une clé au préalable
  - le certificat doit être déposé dans `/etc/pki/tls/certs`
  - la clé doit être déposée dans `/etc/pki/tls/private`
- créer une racine web et un index
  - créez le dossier `/var/www/tp3_site/`
  - créez un fichier à l'intérieur `index.html` avec un contenu de test
- déploie une nouveau fichier de conf NGINX
  - pour servir votre `index.html` en HTTPS (port 443)
- ouvre le port 443/TCP dans le firewall

➜ **Modifiez votre `hosts.ini`**

- ajoutez une section `web`
- elle ne contient que `10.3.1.11`

➜ **Lancez votre playbook sur le groupe `web`**

➜ **Vérifiez que vous accéder au site avec notre navigateur**

> S'il y a besoin d'aide pour tout ça, si vous n'êtes pas du tout familier avec la conf NGINX, n'hésitez pas à faire appel à moi.

🌞 **Pour le compte-rendu**

- `nginx.yml` et `hosts.ini` dans le compte-rendu
- un ptit `curl` vers l'interface Web NGINX

> N'oubliez pas d'ouvrir le port 443 avec une règle Azure (modifiez et ré-appliquez votre fichier `main.tf`).


`nginx.yml` : 

---

```bash
- name: Setup NGINX with HTTPS
  hosts: web
  become: true
  tasks:

    - name: Install required packages
      apt:
        name:
          - nginx
          - openssl
        state: present
        update_cache: yes

    - name: Create SSL certificate directory
      file:
        path: /etc/nginx/ssl
        state: directory
        mode: '0755'

    - name: Generate self-signed SSL certificate
      command: >
        openssl req -new -newkey rsa:2048 -days 365 -nodes -x509
        -subj "/CN=localhost" -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
      args:
        creates: /etc/nginx/ssl/nginx.crt

    - name: Create web root directory
      file:
        path: /var/www/tp3_site
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    - name: Create a simple index.html file
      copy:
        dest: /var/www/tp3_site/index.html
        content: "<h1>Hello from Ansible with HTTPS!</h1>"
        owner: www-data
        group: www-data
        mode: '0644'

    - name: Deploy NGINX configuration for HTTPS
      copy:
        dest: /etc/nginx/sites-available/tp3_site
        content: |
          server {
              listen 443 ssl;
              server_name _;

              ssl_certificate /etc/nginx/ssl/nginx.crt;
              ssl_certificate_key /etc/nginx/ssl/nginx.key;

              root /var/www/tp3_site;
              index index.html;

              location / {
                  try_files $uri $uri/ =404;
              }
          }
        owner: root
        group: root
        mode: '0644'

    - name: Enable site configuration
      file:
        src: /etc/nginx/sites-available/tp3_site
        dest: /etc/nginx/sites-enabled/tp3_site
        state: link

    - name: Remove default NGINX site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent

    - name: Restart NGINX
      service:
        name: nginx
        state: restarted
```
`hosts.ini` : 

```
[tp3]
vm1
vm2

[web]
vm1
```

`curl` : 

````bash
$ curl http://98.71.177.152
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
````
---

### B. MariaDB ou MySQL

➜ **Créez un *playbook* `mariadb.yml`** (ou `mysql.yml`)

- déploie un serveur 
  - MariaDB si vous avez choisi une base RedHat (Rocky, Alma, etc.)
  - ou MySQL si vous utilisez une base Debian  (Debian, Ubuntu, etc.)
- crée un user SQL ainsi qu'une base de données sur laquelle il a tous les droits

➜ **Modifiez votre `hosts.ini`**

- ajoutez une section `db`
- elle ne contient que `10.3.1.12`

➜ **Lancez votre playbook sur le groupe `db`**

➜ **Vérifiez en vous connectant à la base que votre conf a pris effet**

🌞 **Pour le compte-rendu**

- `mariadb.yml` (ou `mysql.yml`) et `hosts.ini` dans le compte-rendu

> N'oubliez pas d'ouvrir le port 3306 avec une règle Azure (modifiez et ré-appliquez votre fichier `main.tf`).

---

`mysql.yml` : 
````bash
- name: Deploy MySQL and configure user and database
  hosts: db
  become: true
  tasks:
    - name: Install MySQL
      apt:
        name: mysql-server
        state: present
    
    - name: Update apt package cache
      apt:
        update_cache: yes
    
    - name: Install Python3
      apt:
        name: python3
        state: present

    - name: Install python3-pip
      apt:
        name: python3-pip
        state: present
    
    - name: Install PyMySQL (required for MySQL modules)
      pip:
        name: PyMySQL
        state: present
        

    - name: Start MySQL service
      service:
        name: mysql
        state: started
        enabled: yes

    - name: Create database
      mysql_db:
        name: db
        state: present
        login_unix_socket: /var/run/mysqld/mysqld.sock

    - name: Create SQL user
      mysql_user:
        name: antoine
        password: EfreiBDX2024
        priv: 'db.*:ALL'
        state: present
        login_unix_socket: /var/run/mysqld/mysqld.sock

    - name: Grant all privileges to the user
      mysql_user:
        name: antoine
        host: "%"
        password: EfreiBDX2024
        priv: 'db.*:ALL'
        state: present
        login_unix_socket: /var/run/mysqld/mysqld.sock
````

`hosts.ini` : 
````bash
[tp3]
vm1
vm2

[db]
vm3
````

# III. Repeat

🌞 **En compte-rendu...**

- tous les fichiers modifiés/ajoutés

`inventories/vagrant_lab/host_vars/vm1.yml`: 

```
vhosts:
  - test2:
      nginx_servername: test2
      nginx_port: 8082
      nginx_webroot: /var/www/html/test2
      nginx_index_content: "<h1>teeeeeest 2</h1>"
  - test3:
      nginx_servername: test3
      nginx_port: 8083
      nginx_webroot: /var/www/html/test3
      nginx_index_content: "<h1>teeeeeest 3</h1>"
```

`roles/nginx/tasks/vhosts.yml`:

```
- name: Create webroots
  file:
    path: "{{ item.value.nginx_webroot }}"
    state: directory
    owner: root
    group: root
    mode: '0755'
  loop: "{{ vhosts | dict2items }}"

- name: Create index
  copy:
    dest: "{{ item.value.nginx_webroot }}/index.html"
    content: "{{ item.value.nginx_index_content }}"
    owner: root
    group: root
    mode: '0644'
  loop: "{{ vhosts | dict2items }}"

- name: NGINX Virtual Hosts
  template:
    src: vhost.conf.j2
    dest: "/etc/nginx/conf.d/{{ item.key }}.conf"
  notify: Reload nginx
  loop: "{{ vhosts | dict2items }}"

- name: Open firewall ports for vhosts
  ansible.builtin.command:
    cmd: "ufw allow {{ item.value.nginx_port }}"
  loop: "{{ vhosts | dict2items }}"
  ignore_errors: true
```

`roles/nginx/templates/vhost.conf.j2` : 

```
server {
    listen {{ item.value.nginx_port }};
    server_name {{ item.value.nginx_servername }};

    location / {
        root {{ item.value.nginx_webroot }};
        index index.html;
    }
}
```

`roles/nginx/handlers/main.yml` : 

```
- name: Reload nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
```

