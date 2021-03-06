#!/bin/bash 
# convert fastq files into sorted bam files with tophat2 and samtools packages.
# Renyi Wu,    v0.3-added fastqc on 6-15-20.;
cd "$(dirname "$0")" #or cd "${0%/*}" or cd "${0%/*}"
# redirect stdout/stderr to a file
#exec &> log.txt
# OR else to redirect only stdout use: 
date
printf "Starting job...\n DO NOT CLOSE THIS TERMINAL!!\n"
exec 3>&1 4>&2
exec >> logfile.txt 2>&1
date
echo "Currently in: ${0%/*} , with these file/folder(s)"
ls -hp
cpu_num="12" #"set number of cpu/threads to be used for computing
FQ_EXT=".fq.gz" #fastq file extension, or ".fq.gz", ".fastq.gz"
GENE_ANNO="/home/administrator/Documents/mm9.2_for_bismark/Mus_musculus_UCSC_mm9.2/Mus_musculus/UCSC/mm9/Annotation/Genes/genes.gtf" #GENE_ANNO="/home/administrator/Documents/mm9.2_for_bismark/Mus_musculus_UCSC_mm9.2/Mus_musculus/UCSC/mm9/Annotation/Genes/genes.gtf" #GENE_annotation file
echo "set annotation file as: $GENE_ANNO"
GENE_REF="/home/administrator/Documents/mm9.2_for_bismark/Mus_musculus_UCSC_mm9.2/Mus_musculus/UCSC/mm9/Sequence/Bowtie2Index/genome" #GENE_REF="/home/administrator/Documents/mm9.2_for_bismark/Mus_musculus_UCSC_mm9.2/Mus_musculus/UCSC/mm9/Sequence/Bowtie2Index/genome" # Gene reference files
echo " Set gene reference folder as: $GENE_REF"


#create necessary folders
mkdir -v fastq  tophat_out bam bam_sorted cuff 

#Move all .gz files to fastq\ folder
mv *.gz ./fastq/

#Run FastQC,optional
mkdir FastQC_reports #make directory for reports, optional
fastqc --extract --outdir=./FastQC_reports/ ./fastq/*.gz
#echo "done"
#echo "counting reads"
date >fastqc_reads_for_all.txt
for i in ./FastQC_reports_auto/*/fastqc_data.txt
do
grep "Filename" "$i" >>fastqc_reads_for_all.txt
grep "Total Sequences" "$i" >>fastqc_reads_for_all.txt
grep ">>Sequence Duplication Levels" "$i" >>fastqc_reads_for_all.txt
grep "#Total Deduplicated Percentage" "$i" >>fastqc_reads_for_all.txt
grep "#Duplication Level" "$i" >>fastqc_reads_for_all.txt
awk '/^1\t/{n++}n==5{print; exit}' "$i" >>fastqc_reads_for_all.txt #Fetch the 5th line starting with "1 TAB", which is the line of interest.
echo "\n" >>fastqc_reads_for_all.txt
done

#run tophat2 for all fastq files, then move "accepted_hits.bam" files to "bam" folder with correlated names
echo "Starting tophat2...running..."
for fqfile in ./fastq/*
do
basefn=$(basename $fqfile $FQ_EXT)
mkdir -pv tophat_out/$basefn
tophat2 -G $GENE_ANNO -p $cpu_num -o "./tophat_out/$basefn" $GENE_REF $fqfile #$HOME_DIR"BAM_Files" 
mv ./tophat_out/$basefn/accepted_hits.bam ./bam/$basefn.bam
echo "Finished file $basefn.bam"
done
echo "tophat2 job done."


#Run samtools to sort .bam files. saved as sorted.bam files
echo "Running samtools..."
for bamfile in ./bam/*.bam
do
basefn=$(basename $bamfile .bam)
samtools sort -@ $cpu_num $bamfile ./bam_sorted/$basefn.sorted
done
echo "Done! Got these files in bam_sorted folder:"
ls -lh ./bam_sorted/

#Run samtools index, optional
echo "samtools indexing..."
mkdir -pv bam_sorted/index
for bamefilesort in ./bam_sorted/*.sorted.bam
do
samtools index $bamefilesort
mv ./bam_sorted/*.bai ./bam_sorted/index/
done
echo "samtool indexing done. "
date
ls -lh ./bam_sorted/index/

#Call another script named "cuffdiff.sh" to run gene expression analysis, make sure this script has been properly set up.
#
sh cuffdiff.sh
echo job done.
date
exec >&3 2>&4
date
printf "Job done. \nPress any key to quit."
read -n1 a




