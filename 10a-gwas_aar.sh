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
mkdir -p ${section_10_dir}/logs_a
touch ${section_10a_logfile}
exec &> >(tee ${section_10a_logfile})
print_version



# Step 1: run the GCTA-GRM: calculating the genetic relationship matrix from autosomal SNPs

# ${gcta} \
# 	--bfile ${bfile} \
# 	--autosome \
# 	--maf 0.05 \
# 	--make-grm \
# 	--out  \
# 	--thread-num 10


# Step 2: generate a sparse genetic relationship matrix (GRM) ###################################

${gcta} \
	--grm ${grmfile_all} \
	--make-bK-sparse 0.05 \
  --autosome \
	--out ${grmfile_fast}  \
  --thread-num ${nthreads}

echo 'Done on making bK sparse'

# Step 3: fastGWA ###################################
i=1
tail -n +2 ${age_pred}.txt > age_acc.plink
clock_names=$(cut -d" " -f 3- ${age_pred}.txt | head -n 1)

for clock_name in $clock_names
do  
  ${gcta} \
          --bfile ${bfile}  \
          --grm-sparse ${grmfile_fast} \
          --fastGWA-mlm \
          --mpheno $i \
          --pheno age_acc.plink \
          --h2-limit 20 \
          --out ${section_10_dir}/${clock_name}
  i=$(($i+1))
  echo "Done the GWAS on" $clock_name 
done
rm age_acc.plink

# Step 4: Visulization ###################################

rm -f ${section_10_dir}/GWAlist.txt
find ${section_10_dir} -type f -name "*.fastGWA" > ${section_10_dir}/GWAlist.txt
${R_directory}Rscript resources/genetics/plot_gwas.R \
	      ${section_10_dir}/GWAlist.txt \
	      10 \
	      1 \
	      3 \
	      2 \
	      TRUE \
	      0 \
	      0 \
	      0 \
	      0 

rm -f ${section_10_dir}/GWAlist.txt

echo "Successfully finished the GWAS on age accelerations!"

