# Makefile for Spark WordCount project.

# Customize these paths for your environment.
# -----------------------------------------------------------
spark.root=/usr/local/spark-3.3.2-bin-without-hadoop
hadoop.root=/usr/local/hadoop-3.3.5
app.name=Twitter Followers Triangles
jar.name=spark-demo.jar
maven.jar.name=spark-demo-1.0.jar
# Set the job name accordingly (based on required execution)
# 1. Twitter Follower Count Programs:
# --> RDD-G: rdd_g.TwitterFollowers_RDD_G
# --> RDD-R: rdd_r.TwitterFollowers_RDD_R
# --> RDD-F: rdd_f.TwitterFollowers_RDD_F
# --> RDD-A: rdd_a.TwitterFollowers_RDD_A
# --> DSET: dset.TwitterFollowers_DSET
# 2. Twitter Triangle Count Programs:
# --> RS-Join with RDD: rdd_rsjoin.TwitterTriangles_RDD_RSJoin
# --> Rep-Join with RDD: rdd_repjoin.TwitterTriangles_RDD_RepJoin
# --> RS-Join with DataFrame/DataSet: dset_rsjoin.TwitterTriangles_DSET_RSJoin
# --> Rep-Join with DataFrame/DataSet: dset_repjoin.TwitterTriangles_DSET_RepJoin
job.name=rdd_r.TwitterFollowers_RDD_R
local.master=local[4]
local.input=input
local.output=output
local.awslog=awslog
# Pseudo-Cluster Execution
hdfs.user.name=joe
hdfs.input=input
hdfs.output=output
# AWS EMR Execution
aws.emr.release=emr-6.10.0
aws.bucket.name=cs6240-satyams-spark-bucket-v1
aws.subnet.id=subnet-6356553a
aws.input=input
aws.output=output
aws.log.dir=log
aws.primary.num.nodes=1
aws.core.num.nodes=6
aws.instance.type=m4.large
# -----------------------------------------------------------

# Compiles code and builds jar (with dependencies).
jar:
	mvn clean package
	cp target/${maven.jar.name} ${jar.name}

# Removes local output directory.
clean-local-output:
	rm -rf ${local.output}*

# Runs standalone
local: jar clean-local-output
	spark-submit --class ${job.name} --master ${local.master} --name "${app.name}" ${jar.name} ${local.input} ${local.output}

# Start HDFS
start-hdfs:
	${hadoop.root}/sbin/start-dfs.sh

# Stop HDFS
stop-hdfs: 
	${hadoop.root}/sbin/stop-dfs.sh
	
# Start YARN
start-yarn: stop-yarn
	${hadoop.root}/sbin/start-yarn.sh

# Stop YARN
stop-yarn:
	${hadoop.root}/sbin/stop-yarn.sh

# Reformats & initializes HDFS.
format-hdfs: stop-hdfs
	rm -rf /tmp/hadoop*
	${hadoop.root}/bin/hdfs namenode -format

# Initializes user & input directories of HDFS.	
init-hdfs: start-hdfs
	${hadoop.root}/bin/hdfs dfs -rm -r -f /user
	${hadoop.root}/bin/hdfs dfs -mkdir /user
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}
	${hadoop.root}/bin/hdfs dfs -mkdir /user/${hdfs.user.name}/${hdfs.input}

# Load data to HDFS
upload-input-hdfs: start-hdfs
	${hadoop.root}/bin/hdfs dfs -put ${local.input}/* /user/${hdfs.user.name}/${hdfs.input}

# Removes hdfs output directory.
clean-hdfs-output:
	${hadoop.root}/bin/hdfs dfs -rm -r -f ${hdfs.output}*

# Download output from HDFS to local.
download-output-hdfs:
	mkdir ${local.output}
	${hadoop.root}/bin/hdfs dfs -get ${hdfs.output}/* ${local.output}

# Runs pseudo-clustered (ALL). ONLY RUN THIS ONCE, THEN USE: make pseudoq
# Make sure Hadoop  is set up (in /etc/hadoop files) for pseudo-clustered operation (not standalone).
# https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html#Pseudo-Distributed_Operation
pseudo: jar stop-yarn format-hdfs init-hdfs upload-input-hdfs start-yarn clean-local-output 
	spark-submit --class ${job.name} --master yarn --deploy-mode cluster ${jar.name} ${local.input} ${local.output}
	make download-output-hdfs

# Runs pseudo-clustered (quickie).
pseudoq: jar clean-local-output clean-hdfs-output 
	spark-submit --class ${job.name} --master yarn --deploy-mode cluster ${jar.name} ${local.input} ${local.output}
	make download-output-hdfs

# Create S3 bucket.
make-bucket:
	aws s3 mb s3://${aws.bucket.name}

# Upload data to S3 input dir.
upload-input-aws: make-bucket
	aws s3 sync ${local.input} s3://${aws.bucket.name}/${aws.input}
	
# Delete S3 output dir.
delete-output-aws:
	aws s3 rm s3://${aws.bucket.name}/ --recursive --exclude "*" --include "${aws.output}*"

# Upload application to S3 bucket.
upload-app-aws:
	aws s3 cp ${jar.name} s3://${aws.bucket.name}

# Main EMR launch.
aws: jar upload-app-aws delete-output-aws
	aws emr create-cluster \
		--name "Twitter-Triangles-RDD-RepJoin-50K-6W" \
		--release-label ${aws.emr.release} \
		--instance-groups '[{"InstanceCount":${aws.core.num.nodes},"InstanceGroupType":"CORE","InstanceType":"${aws.instance.type}"},{"InstanceCount":${aws.primary.num.nodes},"InstanceGroupType":"MASTER","InstanceType":"${aws.instance.type}"}]' \
		--applications Name=Hadoop Name=Spark \
		--steps Type=CUSTOM_JAR,Name="${app.name}",Jar="command-runner.jar",ActionOnFailure=TERMINATE_CLUSTER,Args=["spark-submit","--deploy-mode","cluster","--class","${job.name}","s3://${aws.bucket.name}/${jar.name}","s3://${aws.bucket.name}/${aws.input}","s3://${aws.bucket.name}/${aws.output}"] \
		--log-uri s3://${aws.bucket.name}/${aws.log.dir} \
		--configurations '[{"Classification": "hadoop-env", "Configurations": [{"Classification": "export","Configurations": [],"Properties": {"JAVA_HOME": "/usr/lib/jvm/java-11-amazon-corretto.x86_64"}}],"Properties": {}}, {"Classification": "spark-env", "Configurations": [{"Classification": "export","Configurations": [],"Properties": {"JAVA_HOME": "/usr/lib/jvm/java-11-amazon-corretto.x86_64"}}],"Properties": {}}]' \
		--use-default-roles \
		--enable-debugging \
		--auto-terminate
		
# Download output from S3.
download-output-aws: clean-local-output
	mkdir ${local.output}
	aws s3 sync s3://${aws.bucket.name}/${aws.output} ${local.output}

# Download log from S3.
download-log-aws:
	mkdir ${local.awslog}
	aws s3 sync s3://${aws.bucket.name}/${aws.log.dir} ${local.awslog}

# Change to standalone mode.
switch-standalone:
	cp config/standalone/*.xml ${hadoop.root}/etc/hadoop

# Change to pseudo-cluster mode.
switch-pseudo:
	cp config/pseudo/*.xml ${hadoop.root}/etc/hadoop

# Package for release.
distro:
	rm -f Spark-Demo.tar.gz
	rm -f Spark-Demo.zip
	rm -rf build
	mkdir -p build/deliv/Spark-Demo
	cp -r src build/deliv/Spark-Demo
	cp -r config build/deliv/Spark-Demo
	cp -r input build/deliv/Spark-Demo
	cp pom.xml build/deliv/Spark-Demo
	cp Makefile build/deliv/Spark-Demo
	cp README.txt build/deliv/Spark-Demo
	tar -czf Spark-Demo.tar.gz -C build/deliv Spark-Demo
	cd build/deliv && zip -rq ../../Spark-Demo.zip Spark-Demo
	