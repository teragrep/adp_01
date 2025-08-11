#!/bin/bash
if [ ! -d /opt/teragrep/dfs/nn/ ]; then
    bash /entrypoint-common.sh namenode HTTP;
    echo "Bootstrapping namenode";
    # hdp_04
    echo "Getting hdp_04 keytab";
    ipa-getkeytab -s "ipa.${IPA_DOMAIN}" -p "srv-hdp_04/$(hostname).${IPA_DOMAIN,,}@${IPA_DOMAIN^^}" -k "/opt/teragrep/hdp_04/etc/srv-hdp_04.service.keytab";

    sudo su - hdfs -s "$(which bash)" -c "/opt/teragrep/hdp_03/bin/hdfs namenode -format teragrep"

    systemctl start namenode;

    ## FIXME ##
    echo "Sleeping a bit before leaving safemode and fixing permissions";
    sleep 10;

    # creds
    export KRB5CCNAME="/tmp/krb5cc_${UID}";
    kinit -kt /opt/teragrep/hdp_03/keytabs/namenode.service.keytab "namenode/$(hostname).${IPA_DOMAIN,,}@${IPA_DOMAIN^^}";

    # Leave safemode
    echo "Leaving safemode";
    /opt/teragrep/hdp_03/bin/hdfs dfsadmin -safemode leave;

    # Create bunch of permissions
    echo "Setting up permissions in hdfs";
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown hdfs:hadoop /;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chmod 775 /;
    /opt/teragrep/hdp_03/bin/hdfs dfs -mkdir -p /tmp/hadoop-yarn/nm-local-dir/usercache;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chmod 1777 /tmp/hadoop-yarn/nm-local-dir/usercache;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown hadoop:hadoop /tmp/hadoop-yarn;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown hadoop:hadoop /tmp/hadoop-yarn/nm-local-dir;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown hadoop:hadoop /tmp/hadoop-yarn/nm-local-dir/usercache;

    # Runs ldap->hdfs sync tool
    cp -vf /config/hdp-04/configuration.properties /opt/teragrep/hdp_04/etc/;
    echo "Running hdp_04";
    systemctl start hdp_04;

    # Patch hdfs credentials to well known values. Reversed password from IPA are well known but different.
    {{- range $user, $password := .Values.ipa.users }}
    echo "Overriding '{{$user}}' password to '$(rev <<< {{$password}})' on hdfs.";
    echo -n "$(rev <<< {{$password}})" | /opt/teragrep/hdp_03/bin/hdfs dfs -put -f - "/user/{{$user}}/s3credential";
    /opt/teragrep/hdp_03/bin/hdfs dfs -chmod 400 "/user/{{$user}}/s3credential";
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown "{{$user}}:{{$user}}" "/user/{{$user}}/s3credential";
    {{- end }}

    # Destroy current ticket
    kdestroy -A;
    unset KRB5CCNAME;
fi;

systemctl exit 0;
