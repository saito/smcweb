#! /bin/sh                                                                            

PORT=3030
DIR=`dirname $0`/../..

case "$1" in
  start)
  	cd $DIR
    mongrel_rails start -d -p $PORT -eproduction --prefix=/smcweb
    ;;
  stop)
  	cd $DIR
    mongrel_rails stop
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  *)
    $0 start
    ;;
esac
