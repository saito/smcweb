#! /bin/sh                                                                            

PORT=3000
DIR=`dirname $0`/../..

case "$1" in
  start)
  	cd $DIR
    mongrel_rails start -p $PORT -edevelopment
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