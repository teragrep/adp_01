#!/bin/bash
export ZEPPELIN_WAR=/opt/teragrep/ajs_01/lib/ajs_01.war
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export ZEPPELIN_CLASSPATH=/opt/teragrep/ajs_01/lib/*
export USE_HADOOP=true
export ZEPPELIN_ADDR=0.0.0.0
export ZEPPELIN_PORT=8080
export ZEPPELIN_JMX_ENABLE=true
export ZEPPELIN_JMX_PORT=9996
export ZEPPELIN_WAR_TEMPDIR=/tmp/jetty-tmp
export SPARK_HOME=/opt/teragrep/spk_02
export PATH=$PATH:/opt/teragrep/hdp_03/bin
export HADOOP_HOME=/opt/teragrep/hdp_03
export HADOOP_CONF_DIR=/opt/teragrep/hdp_03/etc/hadoop
export ZEPPELIN_IMPERSONATE_CMD='ZEPPELIN_IMPERSONATE_USER="${ZEPPELIN_IMPERSONATE_USER}" /opt/teragrep/zep_01/bin/sudo-wrapper.sh'
export ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER=true
export KRB5CCNAME="/tmp/krb5cc_${UID}"
export PYTHONPATH="/opt/teragrep/pyz_01"
