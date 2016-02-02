#
# Simplified R script to analyse the feature data
#


## PREPARE DATA ## ================================

# load and prepare var names # ---------------
# NB: it will probably be necessary to parse the macro output to conform here
#     this one file should contain one row per feature, with the following variables:
#     - an ID indicating which mouse the feature came from
#     - the manuall calling of the feature (at least for LDA training features)
#     - and all the ImageJ "measure particles" measures that you want to work with
# Note: this dataset contains feature data from mice
#       with various genotypes and submitted to multiple diferent treatments
dat <- read.csv("4Paper/FeatureData.csv")
dat$MouseID <- as.character(dat$MouseID)

feature.measure.names <-  
	c("Area", "Perim.", "Mean", "StdDev", "Mode", "Min", "Max", "Median",
		"Skew", "Kurt", "Major", "Minor", "Angle", "Circ.", "AR", "Round", "Solidity",
		"Feret", "FeretAngle", "MinFeret", "IntDen", "RawIntDen") # measure variable names

feature.calling.name <- "TumourCalling" # feature calling variable name

mouse.ID.name <- "MouseID" # mouse ID variable name


# describe # -----------------------------------
describe.dataset <- function(mydat, datasetname="dataset") {
	# simple function for describing the dataset
	cat(datasetname,"description:","\n")
	cat(" - #features =",nrow(mydat),"\n")
	cat(" - #measures =",length(feature.measure.names),"\n")
	cat(" - #mice     =",length(unique(mydat[,mouse.ID.name])),"\n")
	cat(" - distribution of feature calls:","\n")
	print(summary(mydat[,feature.calling.name]))
}

describe.dataset(dat)


# transform # -----------------------------------
# transform the variables
#   an exploratory analysis may be necessary to decide whic
#   variables need transforming and how
# - log10
for (col in c('AR', 'Area', 'Feret', 'IntDen', 'Major', 'MinFeret', 'Minor', 'Perim.', 'RawIntDen')) {
	dat[,col] <- log10( dat[,col] )
}
# - shifted log10
for (col in c('Kurt', 'Min', 'Skew')) {
	dat[,col] <- log10( dat[,col] - min(dat[,col], na.rm=TRUE) + 1 )
}
# - remaining measures: no change
rm(col)


# Feature filtering # ------------------------------
#   an exploratory analysis may be necessary to decide which 
#   variables need cut-offs and which cut-off values to use
# - define cutoffs (based on exploratory analyses)
cutoffs <- list(
	"Feret"    = c(-0.30, 1.50),  # note: log10 scale
	"Kurt"     = c( 0.00, 1.50),  # note: shifted log10 scale
	"MinFeret" = c(-0.50, 1.50),  # note: log10 scale
	"Perim."   = c( 0.00, 2.00),  # note: log10 scale
	"Skew"     = c( 0.25, 1.00)   # note: shifted log10 scale
)

# - ID & remove outliers
anybad <- rep(FALSE, nrow(dat))
for (measure.name in names(cutoffs)) {
	bad <- !is.na(dat[,measure.name]) & ( 
		dat[,measure.name]<cutoffs[[measure.name]][1] |
			dat[,measure.name]>cutoffs[[measure.name]][2]	
	) ; names(bad) <- rownames(dat)
	anybad <- anybad | bad
}
rm(measure.name)
cat("Summary of BAD features:\n")
print(summary(anybad))

dat <- dat[!anybad,]
rm(bad, anybad)

describe.dataset(dat)

# - remove features without calling information
dat <- dat[!is.na(dat[,feature.calling.name]),]

describe.dataset(dat)



## RUN LDA ON ALL FEATURES ## ==============================
library(MASS)
library(car)


# Add squared measures # --------------------------------
feature.measure.names.sqrd <- c()
for (col in feature.measure.names) {
	dat[,paste0(col, ".sqrd")] <- dat[,col] ^ 2
	feature.measure.names.sqrd <- c( feature.measure.names.sqrd, paste0(col, ".sqrd") )
}


# run LDA # ----------------------------------
lda.res <- lda( as.formula( paste( 
	feature.calling.name, '~', 
	paste(c(feature.measure.names, feature.measure.names.sqrd), collapse="+") ) ) , 
		 data=dat, na.action="na.omit" )


# generate automatic ("predict") feature callings using LDA # -----------------
# The predict() implementation from package MASS returns a list, 
#   wherein item "class" contains the calls of the elements in newdata,
#   but you could also play around with the "scaling" item from the list 
#   returned by function lda().
lda.res$pred <- MASS:::predict.lda(lda.res, newdata=dat)
feature.predicting.name <- paste0("pred.",feature.calling.name)
dat[,feature.predicting.name] <- lda.res$pred$class # store in dat for further use
print( lda.res )


# single LDA performance indicators # --------------------------------------
# calculated across all features
print( tab <- table( 
	FeatureCalling = dat[,feature.calling.name], 
	Predicted      = lda.res$pred$class) )

print( Ad.TPR     <- 100*tab['Ad','Ad'] / sum( tab['Ad', ] ) )
print( Ad.PPV     <- 100*tab['Ad','Ad'] / sum( tab[, 'Ad'] ) )
print( n.Ad.pred  <- sum( tab[, 'Ad'] ) )
print( n.Ad.obs   <- sum( tab['Ad', ] ) )
print( Ad.ratio   <- sum( tab[, 'Ad'] ) / sum( tab['Ad', ] ) )

print( nAd.TPR     <- 100*tab['nAd','nAd'] / sum( tab['nAd', ] ) )
print( nAd.PPV     <- 100*tab['nAd','nAd'] / sum( tab[, 'nAd'] ) )
print( n.nAd.pred  <- sum( tab[, 'nAd'] ) )
print( n.nAd.obs   <- sum( tab['nAd', ] ) )
print( nAd.ratio   <- sum( tab[, 'nAd'] ) / sum( tab['nAd', ] ) )

rm(tab,
	 Ad.TPR,  Ad.PPV,  n.Ad.pred,  n.Ad.obs,  Ad.ratio, 
	 nAd.TPR, nAd.PPV, n.nAd.pred, n.nAd.obs, nAd.ratio)



## ANALYSE RESULTS AT MOUSE LEVEL ## ==============================

# load mouse data # -------------------
mouse.dat <- read.csv("./4Paper/MouseData.csv")
mouse.dat$MouseID <- as.character(mouse.dat$MouseID)

# - limit to mice that:
#   - are of APC Min genotype
#   - were untreated or treated by MSU + M. smegmatis
#   - are present in both data frames
ok.mice.IDs <- mouse.dat$MouseID[ 
	(!is.na(mouse.dat$Genotype))  & (mouse.dat$Genotype=="APC +/-") &
	(!is.na(mouse.dat$Treatment)) & (mouse.dat$Treatment %in% c("untreated", "msu;msmeg"))]
ok.mice.IDs <- ok.mice.IDs[ok.mice.IDs %in% unique(dat[,mouse.ID.name])]
ok.mice.IDs <- ok.mice.IDs[ok.mice.IDs %in% mouse.dat$MouseID]
print(length(ok.mice.IDs))

mouse.dat <- mouse.dat[mouse.dat$MouseID %in% ok.mice.IDs,]
dat       <- dat[    dat[,mouse.ID.name] %in% ok.mice.IDs,]
print(summary(mouse.dat))
print(summary(dat))


# build tumour burden measures # -------------------------------------
# support function: agg.measure: function to aggregate values by class levels
# - mydat        : data frame containing data to aggregate
# - classvarname : name of classification variable to aggregate
# - idname       : name of factor/character variable to aggregate by
# - targetlev    : target class
# - measurename  : name of measure to aggregate
# - agg.FUN      : function to aggregate values
# - ...          : passed to aggregate
agg.measure <- function( mydat,  classvarname,  idname="MouseID", 
												 targetlev="Ad",  measurename="Area", 
												 agg.FUN=sum, ... ) {
	ok <- (mydat[,classvarname]==targetlev)
	tmp <- aggregate( mydat[ok,measurename], 
										by=list(ID=mydat[ok,idname]), 
										FUN=agg.FUN, ... )
	res <- tmp$x ; names(res) <- tmp$ID
	return(res)
}

# add Area sums
# - manually CALLed feature
tmp <- agg.measure ( 
	dat, classvarname=feature.calling.name, idname="MouseID", 
	targetlev="Ad", measure="Area", 
	agg.FUN=sum )
mouse.dat$CALL.Ad.Area.sum <- tmp[ mouse.dat$MouseID ]
mouse.dat$CALL.Ad.Area.sum[is.na(mouse.dat$CALL.Ad.Area.sum)] <- 0

# - LDA-called features
tmp <- agg.measure ( 
	dat, classvarname=feature.predicting.name, idname="MouseID", 
	targetlev="Ad", measure="Area", 
	agg.FUN=sum )
mouse.dat$LDA.Ad.Area.sum <- tmp[ mouse.dat$MouseID ]
mouse.dat$LDA.Ad.Area.sum[is.na(mouse.dat$LDA.Ad.Area.sum)] <- 0

# add counts
# - manually CALLed feature
tmp <- table(dat[,mouse.ID.name], dat[,feature.calling.name])
mouse.dat$CALL.Ad.Area.count <- tmp[mouse.dat$MouseID, "Ad"]

# - LDA-called features
tmp <- table(dat[,mouse.ID.name], dat[,feature.predicting.name])
mouse.dat$LDA.Ad.Area.count <- tmp[mouse.dat$MouseID, "Ad"]


# split by median age at culling # --------
age.cutoff <- median( mouse.dat$Lifespan, na.rm=TRUE )
op <- par(no.readonly = TRUE)
plot(density(mouse.dat$Lifespan, adj=0.5, na.rm=TRUE), 
		 col="darkblue", lwd=2, main="Lifespan distribution")
abline(v=age.cutoff, lty="dashed", col="magenta")
par(op)


# some simple plots # ------------------
op <- par(no.readonly = TRUE)
par( mar=c(4,4,1,1) )
plot( mouse.dat[,c("CALL.Ad.Area.count", "LDA.Ad.Area.count")],
			bg=ifelse(mouse.dat$Treatment=="untreated", "darkgreen", "magenta"),
			pch=ifelse(mouse.dat$Sex=="M", 24, 25)) ; abline(a=0, b=1, lty="dashed", col="grey")
plot( mouse.dat[,c("CALL.Ad.Area.sum",   "LDA.Ad.Area.sum")] ,
			bg=ifelse(mouse.dat$Treatment=="untreated", "darkgreen", "magenta"),
			pch=ifelse(mouse.dat$Sex=="M", 24, 25)) ; abline(a=0, b=1, lty="dashed", col="grey")  
par(op)


# Anything else your heart desires! # ------------------




# EOF