sudo apt update 
sudo apt install openjdk-17-jdk -y
sudo wget https://dlcdn.apache.org/kafka/4.0.0/kafka_2.13-4.0.0.tgz
sudo tar -xvf kafka_2.13-4.0.0.tgz
sudo mv kafka_2.13-4.0.0 /opt
sudo ln -s /opt/kafka_2.13-4.0.0 /opt/kafka
sudo echo 'export PATH=/opt/kafka/bin:$PATH' >> /root/.profile && source /root/.profile
sudo mkdir -p /var/log/kafka
sudo chown -R root:root /var/log/kafka
sudo chmod -R 755 /var/log/kafka
sudo mkdir -p /opt/kafka/config/kraft
sudo cp /opt/kafka/config/server.properties /opt/kafka/config/kraft/server.properties
sudo bash -c 'cat > /opt/kafka/config/kraft/server.properties << EOL
# The role of this server. Setting this puts us in KRaft mode
process.roles=broker,controller

# The node id associated with this instance
node.id=1

# The connect string for the controller quorum
controller.quorum.voters=1@localhost:9093

# Listeners
listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
inter.broker.listener.name=PLAINTEXT
advertised.listeners=PLAINTEXT://localhost:9092
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

# Logs configuration
log.dirs=/var/log/kafka
num.partitions=1
num.recovery.threads.per.data.dir=1
default.replication.factor=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1

# Log retention policies
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000

# Other configurations
group.initial.rebalance.delay.ms=0
EOL'
sudo bash -c 'cat > /etc/systemd/system/kafka.service << EOL
[Unit] 
Description=Apache Kafka Server (KRaft mode)
Documentation=http://kafka.apache.org/documentation.html 

[Service] 
Type=simple
Environment="JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh 

[Install] 
WantedBy=multi-user.target
EOL'
KAFKA_CLUSTER_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
echo "Using cluster ID: $KAFKA_CLUSTER_ID"
sudo /opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server.properties
sudo systemctl daemon-reload
sudo systemctl enable kafka 
sudo systemctl start kafka 
sudo systemctl status kafka