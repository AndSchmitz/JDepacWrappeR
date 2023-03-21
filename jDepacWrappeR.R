#
#Script to run jDepac as batch (CSV -> jDepac -> CSV)
#
#It tries to run JDpeac on all .txt files located in the subfolder "Input" in
#the directory specified by variable "WorkDir" below.
#
#All JDepac outputs are put in a subfolder named "Output" in the directory
#specified by variable "WorkDir" below.
#


#init-----
rm(list=ls()) #clear workspace
graphics.off() #turn off any open graphics
options(
  warnPartialMatchDollar = T, #warn if incomplete variable names match existing variables
  dplyr.summarise.inform=F #Disable unnecessary info messages
)

#library(tidyverse) #load library for easy data handling
library(stringr) #string handling


#Set working directory, use \\ or /
WorkDir <- "/home/user/JDepacExamples"

#Name of JDepac JAR file (must be located in WorkDir)
jDepacJAR <- "JDepac_v06.jar"


#You may need to adjust the line calling java below
#"java -jar ....." depending on your settings.




#Preparations----
#Load helper functions 
#Script HelpingFunctions.R must be located in WorkDir
# source(file.path(WorkDir,"HelpingFunctions.R"))
#Set input/output directories
InDir <- file.path(WorkDir,"Input")
OutDir <- file.path(WorkDir,"Output")
#Create output directory if not existing
dir.create(OutDir,showWarnings = F)


#Loop over input files-----
InputFiles <- list.files(
  path = InDir,
  pattern = ".txt",
  full.names = T
)
for ( CurrentInputFile in InputFiles ) {
  
  print(paste("Running jDepac for file",basename(CurrentInputFile),"..."))

  #_Run file-----
  Command <- paste0(
    "java -jar \"", file.path(WorkDir, jDepacJAR), "\" \"", CurrentInputFile, "\" --series" 
  )
  print(Command)
  
  system(
    command = Command
  )
  
  #_Clean up results-----
  ResultCSV_From <- gsub(
    x = CurrentInputFile,
    pattern = "txt$",
    replacement = "csv"
  )
  if ( !file.exists(ResultCSV_From) ) {
    stop("!file.exists(ResultCSV_From)")
  }
  ResultCSV_To <- file.path(OutDir, basename(ResultCSV_From))
  ResultCSV_To <- gsub(
    x = ResultCSV_To,
    pattern = "Input",
    replacement = "Output"
  )
  file.rename(
    from = ResultCSV_From,
    to = ResultCSV_To
  )
  #Also move log file
  LogBaseName <- gsub(
    x = basename(ResultCSV_From),
    pattern = "\\csv$",
    replacement = "log"
  )
  file.rename(
    from = file.path(InDir, LogBaseName),
    to = file.path(OutDir, LogBaseName)
  )
  
  
  # stop("..")
  #Finish-----
  print(paste("jDepacWrappeR finished with file",CurrentInputFile))
  
} #end of loop over input files

  
