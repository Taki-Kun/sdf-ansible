#!/bin/bash


JAVA_HOME="/usr/local/jdk"

APP_PATH="/data/game/jiangsu_region_game/dsqp"
APP_MAINCLASS="com.dszy.game.service.launch.DSQPTestLauncher"
APP_WORKERCLASS="com.dszy.game.service.launch.DSQPTestWorker"
APP_PARAM=

for i in $APP_PATH/lib/*.jar;
do
    CLASSPATH="$CLASSPATH":${i}
done

for i in $APP_PATH/deploy/*.jar;
do
    CLASSPATH="$CLASSPATH":${i}
done

JAVA_OPTS="-Xms512m -Xmx512m -XX:SurvivorRatio=10 -XX:+DoEscapeAnalysis -XX:InitialTenuringThreshold=15 -XX:CMSWaitDuration=50 -XX:MaxTenuringThreshold=15 -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:CMSInitiatingOccupancyFraction=80 -XX:+CMSParallelRemarkEnabled -XX:+AggressiveOpts -XX:+UseFastAccessorMethods -XX:-DontCompileHugeMethods -XX:ReservedCodeCacheSize=128m -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -Xloggc:gc.log -XX:+DisableExplicitGC -Duser.timezone=GMT+08"
JAVA_WORKER="-Xms128m -Xmx256m -Xmn64m -Xnoagent"

PID_STATUS=0
WORKER_STATUS=0

checkPid() {
    # PID_STATUS=$(ps -fp 1 | awk '!/awk/' | awk /DSQPTestLauncher/'{ last = $0 } END { if ( last ~/java/ ) { print 1 } else { print 0 } }')
    PID_STATUS=$(ps -fp 1 | awk '!/awk/' | awk /DSQPTestLauncher/'{ last = $0 } END { print ( last ~/java/ )?1:0 }')
}

checkWorker() {
    WORKER_STATUS=$(ps -ef | awk '!/awk/' | awk /DSQPTestWorker/'{ last = $0 } END { print ( last ~/java/ )?1:0 }')
}

start() {
    checkPid

    if [[ $PID_STATUS != 0 ]]; then
        echo "warn: $APP_MAINCLASS already started!"
    else
        echo "Starting $APP_MAINCLASS ..."
        JAVA_CMD="$JAVA_HOME/bin/java $JAVA_OPTS -classpath $CLASSPATH $APP_MAINCLASS $APP_PARAM -c systemConfig.yml -e production"
        # exec /bin/bash -c "$JAVA_CMD"
        exec $JAVA_CMD
    fi
}

worker() {
    checkWorker

    if [[ $WORKER_STATUS != 0 ]]; then
        echo "warn: $APP_WORKERCLASS already started!"
    else
        echo "Starting $APP_WORKERCLASS ..."
        JAVA_CMD="$JAVA_HOME/bin/java $JAVA_WORKER -classpath $CLASSPATH $APP_WORKERCLASS $APP_PARAM"
        # exec /bin/bash -c "$JAVA_CMD"
        exec $JAVA_CMD
    fi
}

case "$1" in
    'start')
        start
        ;;
    'worker')
        worker
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|info|worker}"
        exit 1
esac
exit 0
