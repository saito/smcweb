#! /bin/sh                                                                            

PORT=3010
DIR=`dirname $0`/../..

case "$1" in
  start)
  	cd $DIR
    mongrel_rails start -d -p $PORT -eproduction
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