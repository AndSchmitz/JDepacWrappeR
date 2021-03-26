#
#Script to run jDepac as batch (CSV -> jDepac -> CSV)
#


#init-----
rm(list=ls()) #clear workspace
graphics.off() #turn off any open graphics
options(
  warnPartialMatchDollar = T, #warn if incomplete variable names match existing variables
  dplyr.summarise.inform=F #Disable unnecessary info messages
)


library(tidyverse) #load library for easy data handling
library(stringr) #string handling


#Prepare I/O
#Set working directory, use \\
WorkDir <- "D:\\Users\\Schmitz12\\Desktop\\NotSyncToY\\Projekte\\VDI\\Vergleich DEPAC KRB\\Simulationen"
#jDepac JAR file name (must be located in WorkDir)
jDepacJAR <- "JDepac-0.2.1.jar"
#Load helper functions 
#Script HelpingFunctions.R must be located in WorkDir
source(file.path(WorkDir,"HelpingFunctions.R"))
#Set input/output directories
InDir <- file.path(WorkDir,"Input")
OutDir <- file.path(WorkDir,"Output")
#Create output directory if not existing
dir.create(OutDir,showWarnings = F)

#Read input CSV
#Must be located in folder "Input" in WorkDir
CSVInput <- read.table(
  file = file.path(InDir,"DemoInput.csv"),
  sep = ";",
  header = T,
  stringsAsFactors = F
)


#Read input translation table
#Must be located in folder "Input" in WorkDir
InputTranslation <- read.table(
  file = file.path(InDir,"InputMapping.csv"),
  sep = ";",
  header = T,
  stringsAsFactors = F
)



# --- No changes required below this line ---


#Check CSV input----
#Minimal check of CSV input validity
CSVCols <- colnames(CSVInput)
CSVCols <- CSVCols[CSVCols != "ID"]
WrongInputCols <- CSVCols[!(CSVCols %in% InputTranslation$CSVColumnName)]
if ( length(WrongInputCols) > 0 ) {
  stop(paste("The following columns in input CSV do not correspond to valid columns as defined in InputMapping.csv:",paste(WrongInputCols,collapse = ",")))
}
#Convert empty string to NA, required later
CSVInput[!is.na(CSVInput) & (CSVInput == "")] <- NA


#Run batch-----
#Empty dataframe for batch results
BatchOutput <- data.frame()
#Loop through input CSV rows
for ( iCSVInput in 1:nrow(CSVInput) ) {
  CurrentCSVInputLine <- CSVInput[iCSVInput,]
  CurrentjDepacInput <- ConvertCSVInputRowTojDepacInput(CurrentCSVInputLine)
  CurrentID <- CSVInput$ID[iCSVInput]

  print(paste("Running jDepac on input CSV ID:",CurrentID,"- parameters:",CurrentjDepacInput))
  #Running jDepac with current parametrization
  jDepacResponse <- system(
    command = paste0("java -jar \"", file.path(WorkDir,jDepacJAR),"\" ",CurrentjDepacInput),
    intern = T
  )
  
  #Catch some errors
  if ( any(grepl(x = jDepacResponse, pattern = "usage")) ) {
    print(jDepacResponse)
    stop("Error - stopping")
  }
  if ( any(grepl(x = jDepacResponse, pattern = "Exception")) ) {
    print(jDepacResponse)
    stop("Error - stopping")
  }
  
  #Convert jDepacResponse to data.frame
  jDepacResponseDF <- ParsejDepacResponse(jDepacResponse)
  
  #Add ID to jDepacResponse
  NewOutputRow <- bind_cols(
    data.frame(
      ID = CurrentID
    ),
    jDepacResponseDF
  )
  
  #Append NewOutputRow row to batch output
  BatchOutput <- bind_rows(BatchOutput,NewOutputRow)
  
}


#Save batch results-----
write.table(
  x = BatchOutput,
  file = file.path(OutDir,paste0("BatchRun-",format(Sys.time(),format = "%Y-%m-%d-%H-%M-%S"),".csv")),
  sep = ";",
  row.names = F
)



