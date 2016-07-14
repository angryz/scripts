#!/bin/sh

####################################
# Java process start and stop
# Author: zzp
# Created at: 2015/11/3
####################################

#
# source profile
#
if [ -f /etc/profile ]; then
  . /etc/profile
fi

APP_USER="ubus"
APP_GROUP="wheel"
APP_HOME="/usr/local/javaapp"
APP_NAME=$2
PID_DIR="/usr/local/javaapp/run"
pidfile="$PID_DIR/$APP_NAME.pid"

checkAppName() {
  if [ "-$APP_NAME" == "-" ]; then
    echo "Usage: $0 {deploy|start|stop|restart|status|info} app_name"
    exit 1
  fi
}

checkJava() {
  if [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA="$JAVA_HOME/bin/java"
  else
    JAVA=`which java`
  fi

  if [ ! -x "$JAVA" ]; then
    echo "Could not find any executable java binary. Please install java in your PATH or set JAVA_HOME"
    exit 1
  fi
}

deploy() {
  checkAppName
  if [ ! -e "$APP_HOME/packages/$APP_NAME-bin.tar" ]; then
    echo "Could not find $APP_NAME-bin.tar, exit."
    exit 1
  fi
  if [ -d "$APP_HOME/$APP_NAME" ]; then
    echo "Directory $APP_HOME/$APP_NAME exists, will be removed"
    rm -rf "$APP_HOME/$APP_NAME"
  fi
  tar xvf "$APP_HOME/packages/$APP_NAME-bin.tar" -C $APP_HOME
  mv "$APP_NAME-bin" $APP_NAME
  retval=$?
  return $retval
}

start() {
  checkAppName
  checkJava
  if [ -n "$PID_DIR" ] && [ ! -e "$PID_DIR" ]; then
    mkdir -p "$PID_DIR" && chown "$APP_USER":"$APP_GROUP" "$PID_DIR"
  fi
  if [ -n "$pidfile" ] && [ ! -e "$pidfile" ]; then
    touch "$pidfile" && chown "$APP_USER":"$APP_GROUP" "$pidfile"
  fi

  echo -n $"Starting $APP_NAME: "
  # start it
  $APP_HOME/$APP_NAME/bin/$APP_NAME >$APP_HOME/logs/$APP_NAME.out 2>$APP_HOME/logs/$APP_NAME.err &
  pid=$!
  echo $pid > $pidfile
  retval=$pid
  echo $retval
  return $retval
}

stop() {
  checkAppName
  if [ ! -e "$pidfile" ]; then
    echo "! $APP_NAME already stopped or $pidfile was delelted"
    exit 1
  fi
  pid=`cat $pidfile`
  echo $"Stopping $APP_NAME: $pid"
  # stop it by kill
  kill $pid
  sleep 3s
  pida=`ps -ef | grep java | grep -v grep | grep  $pid | sed -n 1p | awk '{print $2}'`
  if [ "$pida" == "$pid" ]; then
    echo "Failed by kill, will kill by forced"
    kill -9 $pid
  fi
  retval=$?
  [ $retval -eq 0 ] && rm -f $pidfile
  return $retval
}

status() {
  checkAppName
  if [ ! -e "$pidfile" ]; then
    echo "! $APP_NAME is not running or $pidfile was delelted"
  else
    pid=`cat $pidfile`
    echo $"$APP_NAME is running: $pid"
  fi
  retval=$?
  return $retval
}

info() {
  checkAppName
  echo "****************************"
  echo "* System Information:"
  echo "****************************"
  echo `head -n 1 /etc/issue`
  echo `uname -a`
  echo
  echo "****************************"
  echo "* Java Information:"
  echo "****************************"
  echo "JAVA_HOME=$JAVA_HOME"
  echo `$JAVA_HOME/bin/java -version`
  echo
  echo "****************************"
  echo "* App Information:"
  echo "****************************"
  echo "AppHome=$APP_HOME"
  echo "Program=$APP_NAME"
  echo "StartUp=$APP_HOME/$APP_NAME/bin/$APP_NAME"
  return 0
}

case "$1" in
  'deploy')
    deploy
    ;;
  'start')
    start
    ;;
  'stop')
    stop
    ;;
  'restart')
    stop
    start
    ;;
  'status')
    status
    ;;
  'info')
    info
    ;;
  *)
    echo "Usage: $0 {deploy|start|stop|restart|status|info} app_name"
    exit 1
esac
exit $?
