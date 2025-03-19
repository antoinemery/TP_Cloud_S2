# Part I : Programmatic approach

On commence tranquillement avec cette première partie !

- [Part I : Programmatic approach](#part-i--programmatic-approach)
- [I. Premiers pas](#i-premiers-pas)
- [II. Un ptit LAN](#ii-un-ptit-lan)

# I. Premiers pas

🌞 **Créez une VM depuis le Azure CLI**

- en utilisant uniquement la commande `az` donc
- assurez-vous que dès sa création terminée, vous pouvez vous connecter en SSH en utilisant une IP publique
- vous devrez préciser :
  - quel utilisateur doit être créé à la création de la VM
  - le fichier de clé utilisé pour se connecter à cet utilisateur
  - comme ça, dès que la VM pop, on peut se co en SSH !
- je vous laisse faire vos recherches pour créer une VM avec la commande `az`

> *Encore une fois, je vous recommande d'utiliser `az interactive`.*

Par exemple, une commande simple pour faire ça (ça suppose qu'une clé publique SSH existe dans `.ssh/id_rsa.pub`):

```bash
az vm create -g TP-CLOUD -n TP_AZ_CLI --image Ubuntu2204 --admin-username antoine --ssh-key-values .ssh/id_rsa.pub --size Standard_B1s
```
``az vm create`` : Commande pour créer une VM sur Azure.
``-g meo ``: Spécifie le groupe de ressources nommé "meo" dans lequel la VM sera créée.
``-n super_vm ``: Définit le nom de la VM comme "super_vm".
``--image Ubuntu2204 ``: Spécifie l'image du système d'exploitation à utiliser, ici Ubuntu 22.04.
``--admin-username it4 ``: Définit le nom d'utilisateur administrateur de la VM sur "it4".
``--ssh-key-values ../.ssh/id_rsa.pub ``: Indique le fichier de la clé publique SSH pour l'authentification.

🌞 **Assurez-vous que vous pouvez vous connecter à la VM en SSH sur son IP publique.**

- une fois connecté, observez :
  - **la présence du service `walinuxagent`**

    ````bash
    antoine@TPAZCLI:~$ ps ax |grep walinuxagent

    1732 pts/0    S+     0:00 grep --color=auto walinuxagent
    ````

    - permet à Azure de monitorer et interagir avec la VM
  - **la présence du service `cloud-init`**
    - permet d'effectuer de la configuration automatiquement au premier lancement de la VM
    - c'est lui qui a créé votre utilisateur et déposé votre clé pour se co en SSH !
    
    ````bash
    antoine@TPAZCLI:~$ ps ax |grep cloud-init

    1802 pts/0    R+     0:00 grep --color=auto cloud-init
    ````

    - vous pouvez vérifier qu'il s'est bien déroulé avec la commande `cloud-init status`

    ````bash
    antoine@TPAZCLI:~$ cloud-init status

    status: done
    ````

> Pratique de pouvoir se connecter en utilisant une IP publique comme ça ! En revanche votre offre *Azure for Students* ne vous donne le droit d'utiliser que 3 IPs publiques. Pensez donc bien à supprimer les ressources au fur et à mesure du TP.

# II. Un ptit LAN

🌞 **Créez deux VMs depuis le Azure CLI**

- assurez-vous qu'elles ont une IP privée (avec `ip a`)

````bash
    antoine@VM1:~$ ip a
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
        valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host
        valid_lft forever preferred_lft forever
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
        link/ether 00:0d:3a:d8:d4:f4 brd ff:ff:ff:ff:ff:ff
        inet 10.0.0.4/24 metric 100 brd 10.0.0.255 scope global eth0
        valid_lft forever preferred_lft forever
        inet6 fe80::20d:3aff:fed8:d4f4/64 scope link
        valid_lft forever preferred_lft forever
````

- elles peuvent se `ping` en utilisant cette IP privée

````bash
antoine@VM1:~$ ping 10.0.0.5
PING 10.0.0.5 (10.0.0.5) 56(84) bytes of data.
64 bytes from 10.0.0.5: icmp_seq=1 ttl=64 time=4.03 ms
64 bytes from 10.0.0.5: icmp_seq=2 ttl=64 time=1.32 ms

antoine@VM2:~$ ping 10.0.0.4
PING 10.0.0.4 (10.0.0.4) 56(84) bytes of data.
64 bytes from 10.0.0.4: icmp_seq=1 ttl=64 time=4.82 ms
64 bytes from 10.0.0.4: icmp_seq=2 ttl=64 time=1.43 ms
````

- deux VMs dans un LAN quoi !

> *N'hésitez pas à vous rendre sur la WebUI de Azure pour voir vos VMs créées.*

---
