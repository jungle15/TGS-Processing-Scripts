#!/bin/bash

## Initialize the GoGo.m script

rm GoGo.m
cp GoGo-Header.m GoGo.m
rm Compiled-Analysis.csv
touch Compiled-Analysis.csv

## Initialize column headers for the final output

echo "File Name, Peak Frequency (Hz), Frequency Error, Thermal Diffusivity (m2/s), Thermal Error, Tau\n" >> Compiled-Analysis.csv

## Get each POS file in the Analysis directory

for filename in Analysis/*POS*.txt;
do

	filename_pos=$filename
	# filename_neg="$(echo $filename_pos | rev | cut -c 10- | rev)""NEG-1.txt"
	filename_neg="${filename_pos/POS/NEG}"
	echo $filename_pos
	echo $filename_neg

## Extract the rough grating spacing from the filename, if one wasn't supplied as an argument
## First, extract the grating from the filename

	temp=${filename_pos%%um-*}
	grating="$(echo $temp | rev | cut -c -4 | rev)"
	# echo $temp
	echo Grating = $grating
	
## Now check to see if the user supplied one. If so, overwrite it.

	while [ "$1" != "" ]; do
	    case $1 in
	        -g | --grating )        shift
	                                grating=$1
	                                ;;
	        -h | --help )           usage
	                                exit
	                                ;;
	        * )                     usage
	                                exit 1
	    esac
	    shift
	done

## Extract interesting bits of info to overlay on the final image

	StudyName="$(grep 'Study Name' $filename_pos)"
#	StudyName="$(echo $StudyName | cut -c 9- | tr -d '\n\r')"
	StudyName="$(echo $StudyName | sed 's/^.*Name//' | tr -d '\r\n\ ')"
	echo $StudyName
	SampleName="$(grep 'Sample Name' $filename_pos)"
#	SampleName="$(echo $SampleName | cut -c 9- | tr -d '\n\r')"
	SampleName="$(echo $SampleName | sed 's/^.*Name//' | tr -d '\r\n\ ')"
	echo $SampleName
	Date="$(grep -nrH 'Date' $filename_pos)"
#	Date="$(echo $Date | cut -c 16- | tr -d '\n\r')"
	Date="$(echo $Date | sed 's/^.*Date//' | tr -d '\r\n\ ')"
	Date="$(echo $Date | sed 's/\//-/g')"
	echo $Date
	Time="$(grep -nrH 'Time' $filename_pos | head -n1)"
#	Time="$(echo $Time | cut -c 16- | tr -d '\n\r')"
	Time="$(echo $Time | sed 's/^.*Time//' | tr -d '\r\n\ ')"
	echo $Time

## Create a MATLAB .m file to process the two data files

	sed 's/<GRATING>/'$grating'/'  Batch-MATLAB-Template.m >> GoGo.m
	sed -i "s|<TIMESTAMP>|\"Date: "$Date", Time: "$Time", \\\lambda="$grating"\\\mu m\"|" GoGo.m
	sed -i "s|<SAMPLESTAMP>|\"Study:\ "$StudyName"\ Sample:\ "$SampleName"\"|" GoGo.m
       sed -i "s|<FILENAME-POS>|\""$filename_pos"\"|" GoGo.m
      sed -i "s|<FILENAME-NEG>|\""$filename_neg"\"|" GoGo.m
	sed -i 's/_/\\_/g' GoGo.m

done

echo "quit;" >> GoGo.m

/usr/local/MATLAB/R2018b/bin/./matlab -nodisplay -nodesktop -r "GoGo"

