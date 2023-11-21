#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail
#TODO move this to 001
docker_image=seglh/bcl2fastq2:v2.20.0.422_60dbb5a
#test if can get docker image
docker run $docker_image
### Set up parameters
# split project name to get the NGS run number
folder_to_download=${project_to_demultiplex/00[2-3]_/}

API_KEY=$(echo $DX_SECURITY_CONTEXT |  jq '.auth_token' | sed 's/"//g')

mkdir -p runfolder out/bcl2fastq2_output/demultiplexing out/stats_json/demultiplexing out/fastqs/fastqs

cd runfolder
dx download -f -r $project_to_demultiplex:/$folder_to_download/ --auth $API_KEY 
rm $folder_to_download/Data/Intensities/BaseCalls/*fastq*
dx download "$samplesheet"
cd ..

demux_args="--no-lane-splitting"
if [ -n "$demultiplex_args" ]; then
	demux_args="${demux_args} ${demultiplex_args}"
fi
docker run -v /home/dnanexus/runfolder:/mnt/run $docker_image -R /mnt/run/$folder_to_download/ --sample-sheet /mnt/run/$samplesheet_name $demux_args  2>&1 | tee /home/dnanexus/out/bcl2fastq2_output/demultiplexing/$project_to_demultiplex.log 

mv /home/dnanexus/runfolder/$folder_to_download/Data/Intensities/BaseCalls/*fastq* /home/dnanexus/out/fastqs/fastqs/
mv /home/dnanexus/runfolder/$folder_to_download/Data/Intensities/BaseCalls/Stats/Stats.json /home/dnanexus/out/stats_json/demultiplexing/Stats.json

# Upload results
dx-upload-all-outputs