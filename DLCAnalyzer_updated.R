
#installation of necessary packages
install.packages("tensorflow")
install.packages("sp")
install.packages("ggplot2")
install.packages("imputeTS")
install.packages("data.table")
install.packages("cowplot")
install.packages("corrplot")
install.packages("ggmap")
install.packages("keras")

# --- START FROM HERE EVERY TIME YOU OPEN THIS .R FILE ---
install.packages("tensorflow")
library(tensorflow)
install_tensorflow(method = 'conda', envname = 'r-reticulate')
library(reticulate)
use_condaenv('r-reticulate')
library(tensorflow)
tf$constant("Hello Tensorflow")
library(sp)
library(ggplot2)
library(imputeTS)
library(data.table)
library(cowplot)
library(corrplot)
library(ggmap)




#setting working directory
setwd("H:/Behaviour/OFT/DLC_Analyzer")

#path of DLCAnalyzer_Functions_final.R file -- copied from https://github.com/ETHZ-INS/DLCAnalyzer
source("H:/Behaviour/OFT/DLC_Analyzer/DLCAnalyzer-master/R/DLCAnalyzer_Functions_final.R")


##### OFT for single .csv file -- generated with Trained Network in Colab (make sure the network trained is specific for your purpose)

#path for single .csv file
Tracking <- ReadDLCDataFromCSV(file = "H:/Behaviour/OFT/Videos_processed/2022-02-16 12-58-06/cam_port1DLC_resnet50_open-fieldAug20shuffle1_133500.csv", fps = 10)
names(Tracking$data)
PlotPointData(Tracking, points = c("nose", "head", "bottom", "tail"))

#clean data with less than 95% cutoff
Tracking <- CleanTrackingData(Tracking, likelihoodcutoff = 0.95)
PlotPointData(Tracking, points = "head")

#cut ending frames (max 9000 frames=15min, 6000=10min)
Tracking <- CutTrackingData(Tracking, end = 4527)
PlotPointData(Tracking, points = "head")

#calibrate data from pixels to metric
Tracking <- CalibrateTrackingData(Tracking, method = "area", in.metric = 43.38*43.38, points = c("topleftcorner", "toprightcorner", "bottomrightcorner", "bottomleftcorner"))
Tracking$px.to.cm
PlotPointData(Tracking, points = c("nose", "head", "bottom", "tail"))

#add zones of OFT box labelled during training ("topleftcorner", "toprightcorner", "bottomrightcorner", "bottomleftcorner")
Tracking <- AddOFTZones(Tracking, scale_center = 0.5, scale_periphery = 0.5, scale_corner = 0, points = c("topleftcorner", "toprightcorner", "bottomrightcorner", "bottomleftcorner"))
PlotZoneSelection(Tracking, point = "head", zones = "periphery")
#PlotZoneVisits(Tracking, points = c("nose", "head", "bottom", "tail"))
#PlotZoneVisits(Tracking, points = c("nose"))
PlotZoneVisits(Tracking, points = c("head"))
#PlotZoneVisits(Tracking, points = c("bottom"))
#PlotZoneVisits(Tracking, points = c("tail"))
Tracking <- CalculateMovement(Tracking, movement_cutoff = 5, integration_period = 5)
head(Tracking$data$head)
plots <- PlotDensityPaths(Tracking,points = c("nose", "head", "bottom", "tail"))
#plots$nose
plots$head
#plots$bottom
#plots$tail
plots <- AddZonesToPlots(plots,Tracking$zones)
#plots$nose
plots$head
#plots$bottom
#plots$tail

#create report center
ReportCenter <- ZoneReport(Tracking, point = "head", zones = "center")
t(data.frame(ReportCenter))

##create .csv from report periphery --- choose output folder
write.csv(ReportCenter,"H:/Behaviour/OFT/Videos_processed/2022-02-16 12-58-06/report_center_10min_2022-02-16 12-58-06.csv", row.names = TRUE)

#create report periphery
ReportPeriphery <- ZoneReport(Tracking, point = "head", zones = c("center"), zone.name = "periphery", invert = TRUE)
t(data.frame(ReportPeriphery))

##create .csv from report periphery --- choose output folder
write.csv(ReportPeriphery,"H:/Behaviour/OFT/Videos_processed/2022-02-16 12-58-06/report_periphery_10min_2022-02-16 12-58-06.csv", row.names = TRUE)

#PlotZoneVisits(Tracking, point = "head")
png(file="H:/Behaviour/OFT/Videos_processed/2022-02-16 12-58-06/Rplot_density_path_10min_2022-02-16 12-58-06.png", width=827, height=577)
plots <- PlotDensityPaths(Tracking,points = c("head"))
plots$head
dev.off()
png(file="H:/Behaviour/OFT/Videos_processed/2022-02-16 12-58-06/Rplot_density_path_zones_10min_2022-02-16 12-58-06.png", width=827, height=577)
plots <- AddZonesToPlots(plots, Tracking$zones)
plots$head
dev.off()







##### OFT for multiple .csv files

##setting working directory
setwd("H:/Behaviour/DLC_Analyzer")

##path of DLCAnalyzer_Functions_final.R file -- copied from https://github.com/ETHZ-INS/DLCAnalyzer
source("H:/Behaviour/DLC_Analyzer/DLCAnalyzer-master/R/DLCAnalyzer_Functions_final.R")

##path of .csv 
input_folder <- "H:/Behaviour/Videos_processed/RearChR_optostimulation/2021-09-14 16-37-07/"
files <- list.files(input_folder, pattern= "*133500.csv")
files

##pipeline of commands to multiple files
pipeline <- function(path){
  Tracking <- ReadDLCDataFromCSV(path, fps = 10)
  Tracking <- CalibrateTrackingData(Tracking, method = "area", in.metric = 43.38*43.38, points = c("topleftcorner", "toprightcorner", "bottomrightcorner", "bottomleftcorner"))
  Tracking <- CutTrackingData(Tracking, end = 290)
  Tracking <- CleanTrackingData(Tracking, likelihoodcutoff = 0.95)
  Tracking <- AddOFTZones(Tracking, scale_center = 0.5, scale_periphery = 0.8, scale_corners = 0.4, points = c("topleftcorner", "toprightcorner", "bottomrightcorner", "bottomleftcorner"))
  Tracking <- OFTAnalysis(Tracking, movement_cutoff = 5, integration_period = 5, points = "head")
  return(Tracking)
}

##execute it for all files and combine them into a list of Tracking objects
TrackingAll <- RunPipeline(files,input_folder, FUN = pipeline)
#warnings()

##access individual results
Tracking <- TrackingAll$"cam_port1DLC_resnet50_open-fieldAug20shuffle1_133500.csv"
#PlotZoneVisits(Tracking, point = "head")
png(file="H:/Behaviour/Videos_processed/RearChR_optostimulation/2021-09-14 16-37-07/Rplot_density_path_2021-09-14 16-37-07.png", width=827, height=577)
plots <- PlotDensityPaths(Tracking,points = c("head"))
plots$head
dev.off()
png(file="H:/Behaviour/Videos_processed/RearChR_optostimulation/2021-09-14 16-37-07/Rplot_density_path_zones_2021-09-14 16-37-07.png", width=827, height=577)
plots <- AddZonesToPlots(plots, Tracking$zones)
plots$head
dev.off()

##combined report of all files
Report <- MultiFileReport(TrackingAll)
#Report[,1:36]

##create .csv from report --- choose output folder
write.csv(Report,"H:/Behaviour/Videos_processed/RearChR_optostimulation/2021-09-14 16-37-07/report_file_2021-09-14 16-37-07.csv", row.names = TRUE)

#create PDF files with multi-plots for all analyses
PlotDensityPaths.Multi.PDF(TrackingAll,points = c("nose", "head", "bottom", "tail"), add_zones = TRUE)
PlotZoneVisits.Multi.PDF(TrackingAll,points = c("nose", "head", "bottom", "tail"))
