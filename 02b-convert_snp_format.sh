#!/bin/bash

set -e

# Initialize variables
config_file="./config"

# Parse options using getopts
while getopts "c:" opt; do
    case $opt in
        c) config_file=$OPTARG ;;
        *) echo "Usage: $0 -c <config_file>"
           exit 1 ;;
    esac
done

# Shift option arguments, so $1 becomes the first positional argument
shift $((OPTIND - 1))

set -e
echo "-----------------------------------------------"
echo ""
echo "Using config located at:" ${config_file}
echo ""
echo "-----------------------------------------------"
	
source ${config_file}
exec &> >(tee ${section_02b_logfile})
print_version

function make_tab_format {

	transposed_file=$1
	allele_references=$2
	chunksize=$3
	outfile=$4

	echo "Generating matrixeqtl format genetic data"

	# Getting the allele references for the 012 coding
	cut -f 2,5,6 ${transposed_file}.traw | gzip -fc > ${allele_references}

	# Get the header in the right format - just extract IID from the current header
	head -n 1 ${transposed_file}.traw | cut -f 7- | tr '\t' '\n' | tr '_' '\t' | cut -f 2 | tr '\n' '\t' | awk '{ printf ("snpid\t%s\n", $0) }' > traw.header

	# Remove extraneous columns
	sed 1d ${transposed_file}.traw | cut -f 2,7- > ${transposed_file}.traw2
	mv ${transposed_file}.traw2 ${transposed_file}.traw

	rm -f ${outfile}.tab.*
	split -d -a 10 -l ${chunksize} ${transposed_file}.traw ${outfile}.tab.

	i=1
	for file in ${outfile}.tab.*
	do
		echo ${file}
		cat traw.header ${file} > ${outfile}.tab.${i}
		rm ${file}
		i=$(($i+1))
	done

	rm traw.header
	rm ${transposed_file}.traw
	echo "Done!"

}



# Generate plink.raw / plink.frq #freq files are required to determine effect allele
# Chromosome X is coded as 0/2 for males
echo "Converting plink files to transposed raw format"
${plink2} --bfile ${bfile} --recode A-transpose --out ${bfile} --freq

# How big will each chunk be
nrow=`wc -l ${bfile}.bim | awk '{ print $1 }'`
chunksize=$(($nrow / $genetic_chunks))
remainder=$(($nrow % $genetic_chunks))

if [ ! "${remainder}" == "0" ]
then
	chunksize=$(($chunksize + 1))
fi
echo "Splitting genetic data into ${genetic_chunks} chunks"
echo "Each chunk will contain ${chunksize} SNPs"

make_tab_format ${bfile} ${allele_ref} ${chunksize} ${tabfile}

# Convert CNV data
#${R_directory}Rscript resources/genetics/cnv_tabfile.R ${cnvs} ${tabcnv} ${intersect_ids} ${genetic_chunks}

echo "Successfully converted genetic data"