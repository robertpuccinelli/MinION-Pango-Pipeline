# MinION-Pango-Pipeline

## Objective
Build a platform that performs real time Pango lineage identification with a MinION to help operators determine when to end a run while improving sequencing throughput and flow cell efficiency.

## Pipeline, High Level
* Start MinION run  
* Sequencing files on server updated every 5-10 minutes 
    * Assemble genome with artic 
    * Run through PangoLEARN classifier    
* Report lineage and confidence over time on web interface

## Implementation Details
**MinION**
1. New files from starting a MinION run starts a cron job that syncs file changes to the server every 5 minutes.
2. File syncing stops when there are no changed files after 10 minutes

**Server**:
1. When a new run is started, files are synced to the server. New directories launch a script that: 
	* updates the PangoLEARN lineage classifier, 
	* allocates space for run details on the web interface, 
	* and starts the pipeline.
2. Trigger the [Artic pipeline](https://artic.network/ncov-2019/ncov2019-bioinformatics-sop.html)
	* Filter reads with Artic
	* Run the MinION pipeline with Artic to generate consensus sequences
	* Aggregate consensus sequences into one file
3. Upon completing consensus aggregation, start [Pagolin pipeline](https://cov-lineages.org/pangolin_docs/usage.html)
	* Run pangolin
	* Wait for output .csv
4. CSV is parsed, data is appended to database, and web page is updated
5. Script terminates when no file changes are made after 10 minutes

## Requirements
* Docker
* Bash