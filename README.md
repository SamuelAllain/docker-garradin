# docker-garradin

Garradin on Alpine Linux with Docker. With Alpine 3.1.16, PHP 8.1 and Nginx 1.22.0.

## Usage

Pre-requisite : *Docker Desktop*.

**Option 1** from [*Docker Hub*](https://hub.docker.com/r/samuelallain/garradin) : download the image and launch the container in one line
```
sudo docker run -d -t --name ga -p 80:80 -v vol-ga:/var/www/garradin/data/ samuelallain/garradin 
```


**Option 2** from the *Github* repository : build the image and launch the container

```
# clone the repository
git clone https://github.com/SamuelAllain/docker-garradin.git
cd docker-garradin

# build the image
sudo docker build -t garradin .

# launch the container
sudo docker run -d -t --name ga -p 80:80 -v vol-ga:/var/www/garradin/data/ garradin 
```
**Then open [http://localhost:80](http://localhost:80) in your browser.**

<hr>

To stop and remove the container
```
sudo docker rm -f ga
```

To shell inside the container :
```
sudo docker exec -it ga sh
```

To start off a new database, just remove the volume :
```
sudo docker volume rm vol-ga
```
and run again.

## Acknowledgements

This is inspired by [Aurélien Janvier](https://github.com/ajanvier/docker-garradin)'s and [Tim de Pater](https://github.com/TrafeX/docker-php-nginx)'s works. Thanks to them !

It also relies on resources hosted on Garradin's fossil server :

+ [general installation page](https://fossil.kd2.org/garradin/wiki?name=Installation) in French
+ [Debian/Ubuntu setup page](https://fossil.kd2.org/garradin/wiki?name=Installation%20sous%20Debian-Ubuntu)
+ [Nginx configuration](https://fossil.kd2.org/garradin/wiki?name=Installation/nginx)


## More explanations

*Disclaimer : those comments come from a newbie.*

**Garradin** is a PHP-written website, not a simple software.
Therefore, its installation is not that easy.
It requires a web server (Nginx or Apache), with a PHP interpreter (PHP-FPM).

**Supervisord** is used to launch the two required services, Nginx and PHP-FPM, as you can see in *config/supervisord.conf*.
Because the conf file has no "supervisorctl" section (I don't know how to write a working one), it is not possible to use `supervisorctl restart nginx` inside the container.
This would be nice to test new parameters without restarting the whole container. 
Instead I intensively used this command.
```
sudo docker rm -f ga ; sudo docker build -t garradin . ; sudo docker run -d -t --name ga -p 80:80 -v vol-ga:/var/www/garradin/data/ garradin 
```
You can still make sure that both Nginx and PHP-FPM services work with a simple `ps`.
And you can check that your configuration is well taken into account by `nginx -T` (with a lowercase `-t`, it checks the configuration file) and by `php-fpm81 -tt`.

**Nginx and PHP-FPM** communicate through a socket (*/run/garradin.socket*) as you can see in *config/nginx-garradin.conf* and *config/fpm-garradin.conf*.
As I imagine it, when Nginx receive a request over a PHP file, it sends it to PHP for interpretation and PHP hands back a HTML file to Nginx which sends it to the browser.

**Beware :** in the nginx configuration file *garradin.conf*, the root has to be the ***www***, **inside** the *garradin* folder, not the *garradin* itself.
Otherwise, you would receive a warning "Garradin n'est pas installé sur un sous-domaine dédié."

### Version compatibility

If you want to test another garradin version, you first need to check [available versions of garradin](https://fossil.kd2.org/garradin/uvlist).
Then you can put it as `GARRADIN_VERSION` in the *Dockerfile*.
If the version you want is only provided with the format *.tar.bz2*, change `tar xzvf garradin-$GARRADIN_VERSION.tar.gz` by `tar xjvf garradin-$GARRADIN_VERSION.tar.bz2`.

Then you have to check which PHP version is required for this Garradin version. You can do that with a case-sensitive "PHP" search on the [changelog](https://fossil.kd2.org/garradin/wiki/?name=Changelog).

Depending on this, you may want a newer or an older Alpine version, so that the PHP version you're looking for is available. Just change `ALPINE_VERSION` in the *Dockerfile*.

**Modules** Make sure you have installed all necessary modules.
For instance, I experienced a crash because the PHP function `finfo_open()`, provided by the module *php81-fileinfo*, was not found.
Indeed the module was not installed.
I added it to the `RUN apk add` line in the **Dockerfile**
