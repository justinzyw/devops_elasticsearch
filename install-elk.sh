#!/bin/bash

# Fetch the variables
. parm.txt

# function to get the current time formatted
currentTime()
{
  date +"%Y-%m-%d %H:%M:%S";
}

sudo docker service scale devops-elklogstash=0
sudo docker service scale devops-elkkibana=0
sudo docker service scale devops-elkelasticsearch=0

echo ---$(currentTime)---populate the volumes---
#to zip, use: sudo tar zcvf devops_elk_volume.tar.gz /var/nfs/volumes/devops_elk*
sudo tar zxvf devops_elk_volume.tar.gz -C /

# Elasticsearch production requires minimum vm.max_map_count = 262144
# use this command to check: grep vm.max_map_count /etc/sysctl.conf
# use this command to update: sysctl -w vm.max_map_count=262144


echo ---$(currentTime)---create ELK Elasticsearch service---
sudo docker service create -d \
--name devops-elkelasticsearch \
--mount type=volume,source=devops_elkelasticsearch_volume_config,destination=/usr/share/elasticsearch/config,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_elkelasticsearch_volume_config \
--mount type=volume,source=devops_elkelasticsearch_volume_data,destination=/usr/share/elasticsearch/data,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_elkelasticsearch_volume_data \
--publish $ELKELASTICSEARCH_PORT:9200 \
--network $NETWORK_NAME \
--replicas 1 \
--constraint 'node.role == manager' \
$ELKELASTICSEARCH_IMAGE

echo ---$(currentTime)---create ELK Kibana service---
sudo docker service create -d \
--name devops-elkkibana \
--mount type=volume,source=devops_elkkibana_volume_config,destination=/usr/share/kibana/config,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_elkkibana_volume_config \
--publish $ELKKIBANA_PORT:5601 \
--network $NETWORK_NAME \
--replicas 1 \
--constraint 'node.role == manager' \
$ELKKIBANA_IMAGE


echo ---$(currentTime)---create ELK Logstash service---
sudo docker service create -d \
--name devops-elklogstash \
--mount type=volume,source=devops_elklogstash_volume_pipeline,destination=/usr/share/logstash/pipeline,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_elklogstash_volume_pipeline \
--mount type=volume,source=devops_elklogstash_volume_config,destination=/usr/share/logstash/config,\
volume-driver=local-persist,volume-opt=mountpoint=/var/nfs/volumes/devops_elklogstash_volume_config \
--network $NETWORK_NAME \
--replicas 1 \
--constraint 'node.role == manager' \
$ELKLOGSTASH_IMAGE

echo ---$(currentTime)---create Logspout service---
sudo docker service create -d \
--name devops-logspout \
--mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
--mount type=bind,src=/etc/hostname,dst=/etc/hostname \
--network $NETWORK_NAME \
--mode global \
--constraint 'node.role == manager' \
$ELKLOGSPOUT_IMAGE

sudo docker service scale devops-elkelasticsearch=1
sudo docker service scale devops-elkkibana=1
sudo docker service scale devops-elklogstash=1
