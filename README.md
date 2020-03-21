# Project - v1: Spark (Scala) running on Yarn
We have built a Hadoop cluster using Docker to build a developing environment. Currently, we were
able to build Spark 2.4.5 to run on Hadoop 2.7. This should serve as a reference when building a 
develop environment. The next step would be to build a 3 node cluster with NoSQL databases
interacting with Hadoop in order to get a better understanding
of Hadoop's ecossystem, but this should be added in future releases.

# Starting up

If after you run the Dockerfile you still can't seem to make things work properly, first start
your ssh, stop the hadoop service, clear your namenode metadata (do not do this on production
environments) and restart hadoop:

service ssh start
stop-all.sh
hadoop namenode -format # NEVER USE THIS ON PRODUCTION
start-all.sh

You could use dfs-start.sh and the yarn shell if you would like to as well.

# Testing

To check if everything was set up correctly, run the following spark-submit command:
spark-submit --deploy-mode client --master yarn --num-executors 1 --conf spark.dynamicAllocation.enabled=false --class org.apache.spark.examples.SparkPi  $SPARK_HOME/examples/jars/spark-examples_2.11-2.4.5.jar 10

# Next steps for this project

Installing Kafka and Confluent, along with a NoSQL database (ScyllaDB or Cassandra) on a 3 node cluster.
 


