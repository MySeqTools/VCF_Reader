# source("http://www.bioconductor.org/biocLite.R"); biocLite("VariantAnnotation")
library("VariantAnnotation")
library("IRanges")
library("GenomicRanges")
library(foreign)
#####

#####################################################################################################
# To run this script change the setwd()
setwd("E:\\Illumina\\130520_M00897_0029_000000000-A3EAE\\Data\\Intensities\\BaseCalls\\Alignment7")
sample="SA494"
run="A3EAE"
#check="depth"
check = "freq"
#check = "calls"

# Outputs
# system('mkdir C:\\Users\\dyap_000\\Documents\\R\\SA494')
dir="C:\\Users\\dyap_000\\Documents\\R\\SA494"

runname=paste(run,"run",sep="-")
exptname=paste(sample,runname,sep="_")
if (check == "depth") filename=paste(exptname,"reads",sep="_")
if (check == "freq") filename=paste(exptname,"freq",sep="_")
if (check == "calls") filename=paste(exptname,"calls",sep="_")

output=paste(dir,filename,sep="\\")

csvfile=paste(output, "csv", sep=".")
pdffile=paste(output, "pdf", sep=".")
vennfile=paste(output, "Venn.pdf", sep="-")

title=filename
xaxislab=paste(sample, "Nuclei", sep=" ")

####################################################################################################

# read txt files with names of data files .vcf
pat=paste(sample,"*.*vcf",sep="")
file_names = list.files(pattern = pat);
file_names

# Extract all the VCFs into a concatenated VCF list
vcf_list = lapply(file_names, readVcf, "hg19", sep = "\t")

getwd()

# Change the number of samples
# check with "list(vcf_list)"
samples <- length(vcf_list)

createCounter <- function(value) { function(i) { value <<- value+i} }
count <- createCounter(1)


#########################################################
# THIS IS THE CURRENT WORKING MODULE THAT WORKS !!!!!   #
#########################################################



sumdf <- data.frame(	Sample_ID = rep("", samples),
			Variants = rep(0, samples),
			Rows = rep("", samples),
			stringsAsFactors = FALSE)

for (rj in seq(samples)) 	{
			sid <- colnames(vcf_list[[rj]])
			varn <- nrow(vcf_list[[rj]])

sumdf$Samples_ID[rj] <- sid
sumdf$Variants[rj] <- varn

		
# For each of the list of samples
len <- nrow(vcf_list[[rj]])

	if ( len > 0 ){
		

d.frame <- data.frame(	     ID = rep("", len),
 			     framename = rep (0, len),
			     stringsAsFactors = FALSE)

if (check == "freq" ) names(d.frame)[2] <- "Varalfreq"
if (check == "depth" ) names(d.frame)[2] <- "Seqdepth"

for (ri in seq(len) ) 	{

	d.frame$ID[ri] <- rownames(vcf_list[[rj]][ri])
if (check == "calls")	d.frame$Calls[ri] <- geno(vcf_list[[rj]][ri])$GT
if (check == "freq")	d.frame$Varalfreq[ri] <- geno(vcf_list[[rj]][ri])$VF
if (check == "depth")	d.frame$Seqdepth[ri] <- geno(vcf_list[[rj]][ri])$DP

			} 

# unique freq val or seq depth for summary plot
# must be the same length as names(d.frame)
names(d.frame)[2] <- paste(sid)


			} else { d.frame <- "NULL" };

assign(paste("Nuclei", rj, sep=""), d.frame)

# for first value 
	if ( rj == 1 && d.frame != "NULL"  ) {
		first <- d.frame }
 
# combining successive data.frames
	if ( rj == 2 && d.frame != "NULL"  ) { 
		sum1 <- merge(first, d.frame, by="ID", all=TRUE) }

# combining successive data.frames
	if ( rj > 2 && d.frame != "NULL"  ) { 
		a <- count(1)
		sum1 <- merge(sum1, d.frame, by="ID", all=TRUE) 
		} else { print("skip") }

}


write.table(sum1,file=csvfile,sep=",",row.names=FALSE,col.names=TRUE)


###################################

# Drawing heatmap

# Must be convert into a data.matrix (non-numeric converted to N/A)
ef <- data.matrix(sum1[2:ncol(sum1)])

# col headers - unique nuclei
names(sum1)



filt <-rownames(ef[rowSums(is.na(ef))==5,])


# Label rownames with ID
rownames(ef) <- sum1$ID

colnames(ef)

##############################################

# Label according to samplesheet
colnames(ef)[1] = "SA494-T"
colnames(ef)[2] = "SA494-N"
colnames(ef)[3] = "SA494-X4nonWGA"
colnames(ef)[4] = "SA494-X4x3"
colnames(ef)[5] = "SA494-X4"

# Venn Diagram
attach(ef)
Tumour <- (ef[,1] >= 0.2)
Normal <- (ef[,2] >= 0.2)
X4_nonWGA <- (ef[,3] >= 0.2)
X4_triplex <- (ef[,4] >= 0.2)
X4_Single <- (ef[,5] >= 0.2)
#c3 <- cbind(Tumour,Normal,X4_nonWGA,X4_triplex,X4_Single)
c3 <- cbind(X4_Single,X4_triplex)
a <- vennCounts(c3)
pdf(vennfile, width=6, height=6)
vennDiagram(a, main="Variant SNV positions SA494 > 0.2 Alt Allele Freq")
#vennDiagram(a, include = "both", 
 # names = c("High Writing", "High Math", "High Reading"), 
 # cex = 1, counts.col = "red")
dev.off()

# heatmap(ef, Rowv=NA, Colv=NA, col = heat.colors(1024), scale="column", margins=c(5,10))

pdf(pdffile, width=6, height=6)
heatmap(ef, Rowv=NA, Colv=NA, na.rm=TRUE, main=title, xlab=xaxislab, ylab="Position", cexCol=0.8, col=rev(heat.colors(1000)))
dev.off()

########################################################

