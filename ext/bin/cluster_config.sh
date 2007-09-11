#! /bin/sh

mongrel_rails cluster::configure -e production -p 3100 -N 5 -c /home/project/rails/proxy -a 127.0.0.1 --user mongrel --group mongrel
