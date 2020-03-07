FROM ubuntu:18.04

EXPOSE 22

USER root
RUN apt-get update
RUN apt-get install -y \
 vim openssh-server openssh-client sudo openjdk-8-jre
# RUN adduser hduser
RUN useradd -m -s /bin/bash hduser \
  && groupadd hdfs \
  && usermod -aG hdfs hduser \
  && usermod -aG sudo hduser \
  && mkdir ~hduser/.ssh
RUN mkdir -p /home/hduser/.ssh
#Setting up SSH config: accept public keys provided by nodes, without requiring password authentication
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config
RUN echo "PubkeyAcceptedKeyTypes +ssh-dss" >> /home/hduser/.ssh/config
RUN echo "PasswordAuthentication no" >> /home/hduser/.ssh/config
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Keys for root:
RUN  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
RUN  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
RUN  chmod 0600 ~/.ssh/authorized_keys

RUN chown -R hduser:hduser /home/hduser
# Keys for hduser:
USER hduser
RUN ssh-keygen -t rsa -P '' -f ~hduser/.ssh/id_rsa \
  &&  cat ~/.ssh/id_rsa.pub >> ~hduser/.ssh/authorized_keys \
  &&  chmod 0600 ~hduser/.ssh/authorized_keys

# Getting Hadoop and Spark:
WORKDIR /home/hduser
RUN wget http://ftp.unicamp.br/pub/apache/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz
RUN tar -xzf hadoop-2.7.7.tar.gz && mv hadoop-2.7.7 hadoop
RUN rm -rf hadoop-2.7.7.tar.gz

RUN wget http://ftp.unicamp.br/pub/apache/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz
RUN tar -xzf spark-2.4.5-bin-hadoop2.7.tgz
RUN mv spark-2.4.5-bin-hadoop2.7 spark
RUN rm -rf spark-2.4.5-bin-hadoop2.7.tgz

USER root
# Adding config files previously edited:
ENV HADOOP_HOME /home/hduser/hadoop
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/jre
ADD configs/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
ADD configs/hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh
ADD configs/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
ADD configs/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
ADD configs/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
ADD configs/workers $HADOOP_HOME/etc/hadoop/workers

# Setting environment variables (verify from this point):
ENV HADOOP_CONF_DIR $HADOOP_HOME/etc/hadoop

ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR $HADOOP_HOME/lib/native
ENV YARN_HOME $HADOOP_HOME
ENV PATH $JAVA_HOME/bin:$PATH
ENV PATH $HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Environment variables for hduser:

RUN echo "PATH=/home/hduser/hadoop/bin:/home/hduser/hadoop/sbin:$PATH" >>  /home/hduser/.profile
RUN echo "export HADOOP_HOME=/home/hduser/hadoop" >> /home/hduser/.bashrc
RUN echo "export PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin"  >> /home/hduser/.bashrc
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre" >> /home/hduser/.bashrc



RUN mkdir -p /home/hduser/data
RUN mkdir -p /home/hduser/data/nameNode /home/hduser/data/dataNode /home/hduser/data/nameNodeSecondary /home/hduser/data/tmp

RUN chown hduser -R /home/hduser/data
#RUN chown hduser -R /home/hduser/hadoop

RUN echo "export YARN_RESOURCEMANAGER_USER=hduser" >> /home/hduser/.bashrc
RUN echo "export YARN_NODEMANAGER_USER=hduser" >> /home/hduser/.bashrc
RUN echo "export HDFS_SECONDARYNAMENODE_USER=hduser" >> /home/hduser/.bashrc
RUN echo "export HDFS_DATANODE_USER=hduser" >> /home/hduser/.bashrc
RUN echo "export HDFS_NAMENODE_USER=hduser" >> /home/hduser/.bashrc

#For Spark's environment variables:
RUN echo "PATH=/home/hduser/spark/bin:$PATH" >> /home/hduser/.profile
RUN echo "export HADOOP_CONF_DIR=/home/hduser/hadoop/etc/hadoop" >> /home/hduser/.profile
RUN echo "export SPARK_HOME=/home/hduser/spark" >> /home/hduser/.profile
RUN echo "export LD_LIBRARY_PATH=/home/hduser/hadoop/lib/native:$LD_LIBRARY_PATH" >> /home/hduser/.profile

ENV SPARK_HOME /home/hduser/spark
ADD configs/spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf



#Starting SSH
CMD service ssh start && bash
# Check which of these ports we really need to expose after configuring single node:
EXPOSE 8088 8888 5000 50070 50075 50030 50060
# Did you get a connection refused when trying to use commands on hdfs? Try running stop-all.sh,
# hadoop namenode -format and start-all.sh, as this could be a problem with wrong configurations
# on the namenode daemon.
