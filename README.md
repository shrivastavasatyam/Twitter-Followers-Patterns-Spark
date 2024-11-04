# Twitter Follower's Patterns - Spark (Scala)

This project involves analyzing a Twitter follower dataset using various Spark-based aggregation techniques and join methods. The objective is to implement and compare different methods for counting followers and detecting triangles in a Twitter graph using Spark. Specifically, we explore techniques like `groupByKey`, `reduceByKey`, `foldByKey`, `aggregateByKey`, and DataFrame-based aggregation for counting followers. Additionally, we implement join-based methods like **RS-Join** and **Rep-Join** using RDD or Dataset/Dataframe to detect triangles in the graph. The project can be run locally, on a pseudo-distributed Hadoop cluster, or on AWS EMR for scalable data processing. This README.md provides detailed instructions for setting up the required environment, executing the program in different modes, and using AWS for distributed processing.

- **Triangles**: A triangle exists if three nodes X, Y, and Z are mutually connected, forming 3 edges (i.e., X -> Y, Y -> Z, Z -> X) that create a closed triad. These computations provide insights into the structure and connectivity of graphs like the Twitter dataset.

Author
-----------
- Satyam Shrivastava

Installation
------------
This project was set up on an Apple MacBook M1 Pro. The following components need to be installed first:
- OpenJDK 11 (installed via Homebrew)
- Hadoop 3.3.5 (downloaded from https://hadoop.apache.org/release/3.3.5.html)
- Maven (downloaded from https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.6.3/, using the first link)
- Scala 2.12.17 (downloaded from https://www.scala-lang.org/download/2.12.7.html)
- Spark 3.3.2 (without bundled Hadoop, downloaded from http://download.nust.na/pub2/apache/spark/spark-3.3.2/)
- AWS CLI 1 (installed via Homebrew)

### Steps to Install

1) Install OpenJDK 11: Install OpenJDK 11 using Homebrew:

   `brew install openjdk@11`

2) Install Hadoop 3.3.5: Download Hadoop 3.3.5, unzip the file, and move it to the appropriate directory:

   `mv hadoop-3.3.5 /usr/local/hadoop-3.3.5`

3) Install Maven 3.6.3: Download Maven 3.6.3, unzip the file, and move it to the appropriate directory:

   `mv apache-maven-3.6.3 /usr/local/apache-maven-3.6.3`

4) Install Scala 2.12.7: Download Scala 2.12.7, unzip the file, and move it to the appropriate directory:

   `mv scala-2.12.7 /usr/local/share/scala`

5) Install Spark 3.3.2 (without bundled Hadoop): Download Spark 3.3.2 (without bundled Hadoop), unzip the file, and move it to the appropriate directory:

   `mv spark-3.3.2-bin-without-hadoop /usr/local/spark-3.3.2-bin-without-hadoop`

6) Install AWS CLI 1: Install AWS CLI version 1 using Homebrew:

   `brew install awscli@1`

After installation, ensure the components are correctly set up by checking their versions:
```
java -version
hadoop version
mvn -version
aws --version
scala -version
spark-submit --version
```

Environment
-----------
1) **Setting up Environment Variables**:

   Environment variables are required to be defined based on the preferred shell. The zsh (Z-Shell) is used for this project on MacOS.

   Following are the relevant environment variables (in `~/.zshrc`) based on project's setup:

   ```
   export JAVA_HOME=/opt/homebrew/opt/openjdk@11

   export HADOOP_HOME=/usr/local/hadoop-3.3.5
   export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
   export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

   export M2_HOME=/usr/local/apache-maven-3.6.3
   export PATH=$M2_HOME/bin:$PATH

   export SCALA_HOME=/usr/local/share/scala
   export PATH=$PATH:$SCALA_HOME/bin

   export SPARK_HOME=/usr/local/spark-3.3.2-bin-without-hadoop
   export PATH=$PATH:$SPARK_HOME/bin
   export SPARK_DIST_CLASSPATH=$(hadoop classpath)
   
   export PATH="/opt/homebrew/opt/awscli@1/bin:$PATH"
   ```

2) Explicitly set `JAVA_HOME` in the Hadoop configuration file. Edit `$HADOOP_HOME/etc/hadoop/hadoop-env.sh` and add:

   `export JAVA_HOME=/opt/homebrew/opt/openjdk@11`


Jobs Overview
-----------

This project involves following Spark programs/jobs to process the Twitter dataset:

### 1. **Combining in Spark**:
   - Implement and compare different Spark RDD-based and Dataset/DataFrame-based methods for counting followers using the `edges.csv` data.
   - Each program processes the follower data and outputs the follower count for users whose IDs are divisible by 100.
   - The methods implemented are:
     - **RDD-G**: Uses `groupByKey` for aggregation.
     - **RDD-R**: Uses `reduceByKey` for aggregation.
     - **RDD-F**: Uses `foldByKey` for aggregation.
     - **RDD-A**: Uses `aggregateByKey` for aggregation.
     - **DSET**: Uses Dataset/DataFrame and the `groupBy` and `agg` functions for aggregation.

### 2. **Triangle Counting**:
   - Detect triangles in the Twitter follower graph using join-based techniques:
     - **RS-Join (RDD-based)**: Finds triangles using a relational-style join with RDDs.
     - **Rep-Join (RDD-based)**: Detects triangles using a replicated join approach with RDDs.
     - **RS-Join (DataFrame-based)**: Uses Dataset/DataFrame to perform RS-Join.
     - **Rep-Join (DataFrame-based)**: Uses Dataset/DataFrame to perform Rep-Join.

Each of these jobs can be run locally or in a distributed environment using AWS EMR.

**Important**: It is required to **manually modify the `job.name` in the Makefile** each time to switch between jobs. This step is required because each job has a different logic, and the correct job class must be specified to run the desired program. For example, use `exact.Exact2HopCount` for the exact 2-hop count job, or `repjoin.RepJoinTriangleCount` for the Rep-Join triangle counting.


Makefile Configuration
---------

The Makefile is pre-configured for different jobs based on the type of operation. To switch between jobs, adjust the `job.name` parameter in the Makefile:

```makefile
# Set job name to the class name corresponding to the desired job
# Use the appropriate job name:
# -> RDD-G: rdd_g.TwitterFollowers_RDD_G
# -> RDD-R: rdd_r.TwitterFollowers_RDD_R
# -> RDD-F: rdd_f.TwitterFollowers_RDD_F
# -> RDD-A: rdd_a.TwitterFollowers_RDD_A
# -> DSET: dset.TwitterFollowers_DSET
# -> RSJoin: rdd_rsjoin.TwitterTriangles_RDD_RSJoin
# -> RepJoin: rdd_repjoin.TwitterTriangles_RDD_RepJoin
# -> RSJoin (DataFrame): dset_rsjoin.TwitterTriangles_DSET_RSJoin
# -> RepJoin (DataFrame): dset_repjoin.TwitterTriangles_DSET_RepJoin

job.name=rdd_g.TwitterFollowers_RDD_G
```

Execution
---------
Following are the general steps of execution used for implementing the project:

1) Clone the project's GitHub repository or unzip the project files into Visual Studio Code (or any preferred IDE).

2) Open Terminal window in VS Code. Navigate to directory where project files unzipped.

3) **Edit Makefile** and `pom.xml` **file**:
   All build and execution commands are organized in the Makefile. The Makefile is pre-configured to handle local, pseudo-distributed, and AWS EMR setups. Project can be executed directly using the `make` commands provided below without modifying the Makefile unless we're customizing the environment.
   Additionally, the pom.xml file is configured with the recommended software versions for this course (such as OpenJDK 11, Hadoop 3.3.5, and Maven 3.6.3). Since the same versions are being used as suggested in the course, there's no need to update the pom.xml file
   
   Edit the Makefile to customize the environment at the top. **If necessary, adjust the job names and paths in the Makefile as shown above**.

   Sufficient for standalone: hadoop.root, jar.name, local.input. Other defaults acceptable for running standalone.

5) Standalone Hadoop:
	- `make switch-standalone`		-- set standalone Hadoop environment (execute once)
	- `make local`

6) Test Run with a Small File:
   Before running the full program, it's a good idea to validate the setup with a small test file for visualizing the results easily. Create a simple text file (`sample_edges.txt`) with 8-10 lines in the input folder. Create a separate `outputSample` folder.

```
# sample content
1,2
2,3
3,1
1,4
4,5
5,6
6,4
3,6
2,5
5,3
```
   Create a separate `outputSample` folder. Edit the parameters (local.input and local.output) in Makefile. Execute the respective program locally using the sample file now. Understand the output results.
	- `make local`

7) Adding Lineage (RDD) or Plan Explanation (Dataset/Dataframe) Visualization to the Program:
   To visualize the lineage of the RDD transformations, modify the scala program file to include a call to `toDebugString()` or `explain()`. Here's how:
   	- Open scala program and add the following at the end of the program for RDD:
   	  `logger.info(counts.toDebugString)`
   	  
   	- Open scala program and append the following at the end of the final dataframe:
   	  `DF.explain(true)`
   	
    - Run the program to  see the lineage/plan execution printed in the generated logs.

8) Pseudo-Distributed Hadoop: (https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html#Pseudo-Distributed_Operation)
	- `make switch-pseudo`			-- set pseudo-clustered Hadoop environment (execute once)
	- `make pseudo`					-- first execution
	- `make pseudoq`				-- later executions since namenode and datanode already running

9) AWS EMR Hadoop: (you must configure the emr.* config parameters at top of Makefile)
	- `make make-bucket`			-- Create an S3 bucket (only for the first execution)
	- `make upload-input-aws`		-- Upload input data to AWS S3 (only for the first execution)
	- `make aws`					-- Run the Hadoop job on AWS EMR. Check for successful execution with web interface (aws.amazon.com)
	- `download-output-aws`		-- After successful execution & termination, download the output from S3
 	- `download-log-aws`		-- After successful execution & termination, download the logs from S3

**Important**: Terminate EMR cluster and delete the files from S3 bucket after successful execution of the jobs to avoid unnecessary costs. Monitor EMR usage through AWS to manage expenses effectively.

### Notes: 
- The work was consistently committed (every 15-20 mins) to version control and maintain a proper workflow.
- The input, output, and logs directories (not suited for version control) are added to .gitignore to avoid size issues when uploading to GitHub. These files are stored on OneDrive for easy access without overloading the repository.