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


#Set working directory, use \\ or /
WorkDir <- "/Path/To/WorkDir"

#Name of JDepac JAR file (must be located in WorkDir)
jDepacJAR <- "JDepac-0.3.0.jar"

#Name of input file, expected in subfolder "Input" of WorkDir
InputCSVName <- "DemoInput.csv"


# --- No changes required below this line ---


#Preparations----
#Load helper functions 
#Script HelpingFunctions.R must be located in WorkDir
source(file.path(WorkDir,"HelpingFunctions.R"))
#Set input/output directories
InDir <- file.path(WorkDir,"Input")
OutDir <- file.path(WorkDir,"Output")
#Create output directory if not existing
dir.create(OutDir,showWarnings = F)
#Name for output file
BatchOutputFileName <- file.path(OutDir,paste0("BatchRun-",format(Sys.time(),format = "%Y-%m-%d-%H-%M-%S"),".csv"))

#Read input CSV-----
#Must be located in folder "Input" in WorkDir
CSVInput <- read.table(
  file = file.path(InDir,InputCSVName),
  sep = ";",
  header = T,
  stringsAsFactors = F
)

#Check CSV input----
#Minimal check of CSV input validity
CSVCols <- colnames(CSVInput)
CSVCols <- CSVCols[CSVCols != "ID"]
#Convert empty string to NA, required later
CSVInput[!is.na(CSVInput) & (CSVInput == "")] <- NA

#Run batch-----
#Empty list for batch results
BatchOutput <- list()
#Loop through input CSV rows
IsFirstSave <- T
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
    stop(paste("Error with ID",CurrentID," - stopping."))
  }
  if ( any(grepl(x = jDepacResponse, pattern = "Exception")) ) {
    print(jDepacResponse)
    stop(paste("Error with ID",CurrentID," - stopping."))
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
  
  #Convert UNDEF to NA to have columns of type numeric
  #From version <0.3.0. Still relevant?
  NewOutputRow[NewOutputRow == "UNDEF"] <- NA
  
  #Append NewOutputRow row to batch output
  BatchOutput[[iCSVInput]] <- NewOutputRow
  
  #Save results and clear memory every SaveEveryNumSimulations input rows
  #to avoid memory problems
  SaveEveryNumSimulations <- 100
  if ( (iCSVInput %% SaveEveryNumSimulations == 0) | (iCSVInput == nrow(CSVInput)) ) {
    #Convert BatchOutput from list to dataframe
    BatchOutput <- do.call(
      what = bind_rows,
      args = BatchOutput
    )
    #Save batch results    
    write.table(
      x = BatchOutput,
      file = BatchOutputFileName,
      sep = ";",
      row.names = F,
      #Write column names only at the first save operation
      col.names = ifelse(
        test = IsFirstSave,
        yes = T,
        no = F
      ),
      #Append on every following save operation
      append = ifelse(
        test = IsFirstSave,
        yes = F,
        no = T
      )
    )
    IsFirstSave <- F
    #Empty list for next batch results
    BatchOutput <- list()
  }

} #End of loop over input CSV rows

#Finish-----
print("jDepacWrappeR finished.")

