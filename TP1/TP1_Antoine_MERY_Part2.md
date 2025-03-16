# Part II : Images

La construction d'image avec Docker est basée sur l'utilisation de fichiers `Dockerfile`.

On consacre cette partie à la construction d'image custom !

L'idée est la suivante :

- vous créez un dossier de travail
- vous vous déplacez dans ce dossier de travail
- vous créez un fichier `Dockerfile`
  - vous y écrivez les instructions pour construire une image
  - `FROM` : indique l'image de base
  - `RUN` : indique des opérations à effectuer dans l'image de base
- vous exécutez une commande `docker build . -t <IMAGE_NAME>`
- une image est produite, visible avec la commande `docker images`

## Sommaire

- [Part II : Images](#part-ii--images)
  - [Sommaire](#sommaire)
  - [Exemple de Dockerfile et utilisation](#exemple-de-dockerfile-et-utilisation)
  - [Construisez votre propre Dockerfile](#construisez-votre-propre-dockerfile)

## Exemple de Dockerfile et utilisation

Exemple d'un Dockerfile qui :

- se base sur une image ubuntu
- la met à jour
- installe nginx

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx
```

Une fois ce fichier créé, on peut :

```bash
# on est dans le dossier qui contient le Dockerfile
$ ls
Dockerfile

# on lance un build d'image en précisant le dossier de build : . (le dossier actuel)
# et un nom (un "tag") pour l'image : my_own_nginx
$ docker build . -t my_own_nginx 

# une fois terminé, on peut lister les images qu'on a actuellement avec :
$ docker images
# on voit bien notre nouvelle image

# on peut lancerun nouveau conteneur qui utilise cette image
# ici, on spécifie qu'elle doit lancer la commande nginx au démarrage
$ docker run -p 8888:80 my_own_nginx nginx -g "daemon off;"

# should work
$ curl localhost:8888
```

> La commande `nginx -g "daemon off;"` permet de lancer NGINX au premier-plan, et ainsi demande à notre conteneur d'exécuter le programme NGINX à son lancement.

Plutôt que de préciser à la main à chaque `docker run` quelle commande doit lancer le conteneur (notre `nginx -g "daemon off;"` en fin de ligne ici), on peut, au moment du `build` de l'image, choisir d'indiquer que chaque conteneur lancé à partir de cette image lancera une commande donnée.

Il faut, pour cela, modifier le Dockerfile, et on ajoute la clause `CMD` :

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx

CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
```

```bash
$ ls
Dockerfile

$ docker build . -t my_own_nginx

$ docker images

$ docker run -p 8888:80 my_own_nginx

$ curl localhost:8888
$ curl <IP_VM>:8888
```

On peut aussi ajouter un fichier de la machine hôte à l'image avec `COPY` :

> Le chemin précisé est résolu depuis le dossier actuel où sera lancé la commande `docker build`. Donc le fichier `index.html` spécifié ci-dessous se trouve juste à côté du `Dockerfile`.

```bash
$ cat Dockerfile
FROM ubuntu

RUN apt update -y

RUN apt install -y nginx

COPY index.html /usr/share/nginx/html/

CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
```

![Waiting for Docker](./img/waiting_for_docker.jpg)

## Construisez votre propre Dockerfile

🌞 **Construire votre propre image**

- image de base (celle que vous voulez : debian, alpine, ubuntu, etc.)
  - une image du Docker Hub
  - qui ne porte aucune application par défaut
- vous ajouterez
  - mise à jour du système
  - installation de Apache (pour les systèmes debian, le serveur Web apache s'appelle `apache2` et non pas `httpd` comme sur Rocky)
  - page d'accueil Apache HTML personnalisée

➜ Pour vous aider, voilà un fichier de conf minimal pour Apache (à positionner dans `/etc/apache2/apache2.conf`) :

```apache2
# on définit un port sur lequel écouter
Listen 80

# on charge certains modules Apache strictement nécessaires à son bon fonctionnement
LoadModule mpm_event_module "/usr/lib/apache2/modules/mod_mpm_event.so"
LoadModule dir_module "/usr/lib/apache2/modules/mod_dir.so"
LoadModule authz_core_module "/usr/lib/apache2/modules/mod_authz_core.so"

# on indique le nom du fichier HTML à charger par défaut
DirectoryIndex index.html
# on indique le chemin où se trouve notre site
DocumentRoot "/var/www/html/"

# quelques paramètres pour les logs
ErrorLog "logs/error.log"
LogLevel warn
```

➜ Et aussi, la commande pour lancer Apache à la main sur un système Debian par exemple c'est : `apache2 -DFOREGROUND`.

🌞 **OU ALORS**

- si t'as un truc à toi, un projet, un serveur de chat, de jeu, j'en sais rien
- go le conteneuriser et me rendre ça
- je peux aider si c'est un truc un peu complexe

🌞 **Dans les deux cas, j'attends juste votre `Dockerfile` dans le compte-rendu**


````docker
# Utilisation de l'image Debian comme base
FROM debian:latest

# Mise à jour du système et installation d'Apache
RUN apt update -y && apt upgrade -y && apt install -y apache2

# Copie du fichier de configuration Apache personnalisé
COPY apache2.conf /etc/apache2/apache2.conf

# Copie d'une page d'accueil personnalisée dans le dossier web
COPY index.html /var/www/html/index.html

# Exposition du port 80
EXPOSE 80

# Commande pour démarrer Apache en mode foreground
CMD ["/usr/sbin/apache2", "-DFOREGROUND"]
````