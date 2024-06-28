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
mkdir -p ${section_11_dir}/logs_a
touch ${section_11a_logfile}
exec &> >(tee ${section_11a_logfile})
print_version


# Step 1: Check if cellcount is generated ###################################
if [ "${cellcounts_required}" = "no" ]
then
  echo "No cell counts required" 
  cellcounts_cov="NULL"
fi


# Step 2: Generate qcovar for GWAS of smoking ###################################
${R_directory}Rscript resources/smoking/qcovar_gwas_smoking.R \
	      ${cellcounts_cov} \
	      ${covariates} \
          ${bfile}.fam \
	      ${smoking_pred}


# Step 3:GWAS of smoking ###################################
echo "Running GWAS for smoking."
${gcta} \
  		--bfile ${bfile} \
  		--grm-sparse ${grmfile_fast}  \
  		--fastGWA-mlm  \
  		--pheno ${smoking_pred}.smok.plink  \
  		--autosome \
      --h2-limit 100 \
  		--out ${section_11_dir}/gwas_smoking


# Step 4: Visulization ###################################

echo "Making plots"
rm -f ${section_11_dir}/GWAlist.txt
find ${section_11_dir} -type f -name "*.fastGWA" > ${section_11_dir}/GWAlist.txt
${R_directory}Rscript resources/genetics/plot_gwas.R \
		${section_11_dir}/GWAlist.txt \
		10 \
		1 \
		3 \
		2 \
		TRUE \
		0 \
		0 \
		0 \
		0 

rm -f ${section_11_dir}/GWAlist.txt
echo "Successfully finished the GWAS on smoking!"
