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
WorkDir <- "/path/to/your/WorkDir"

#jDepac JAR file name (must be located in WorkDir)
jDepacJAR <- "JDepac-0.2.1.jar"



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

#Read input CSV-----
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
BatchOutputFileName <- file.path(OutDir,paste0("BatchRun-",format(Sys.time(),format = "%Y-%m-%d-%H-%M-%S"),".csv"))


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


#Guess output table structure------
#The number of output elements differs for different values in JDepac input parameter "cmp",
#e.g. between particles, HNO3 and NH3. In order to guarantee a consistent column structure in the
#output CSV for potentially mixed occurrences of different substances, all ocurring output
#columns are determined in advance. This is done by running the first occurrence (line) of each
#substance in the input CSV through jDepac and aggregating all occurring output elements/columns.
CSVInput_FirstOccurrenceEachSubstance <- CSVInput %>%
  group_by(cmp) %>%
  mutate(
    n = 1:n()
  ) %>%
  ungroup() %>%
  filter(
    n == 1
  )
OutputCols <- vector() #Vector with all output column names that will occur
for ( iTestInput in 1:nrow(CSVInput_FirstOccurrenceEachSubstance) ) {
  CurrentCSVInputLine <- CSVInput_FirstOccurrenceEachSubstance[iTestInput,]
  CurrentjDepacInput <- ConvertCSVInputRowTojDepacInput(CurrentCSVInputLine)
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
  OutputCols <- unique(c(OutputCols, colnames(jDepacResponseDF)))
}
#Create dumm dataframe with all expected columns
DummyDF <- data.frame(
  matrix(
    data = rep(NA, length(OutputCols)),
    ncol = length(OutputCols)
  )
)
colnames(DummyDF) <- OutputCols
DummyDF <- DummyDF %>%
  mutate(
    ID = NA
  ) %>%
  select(ID, version, everything())


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
  
  #Make sure all columns are present (potentially with NA values)
  NewOutputRow <- bind_rows(
    DummyDF,
    NewOutputRow
  )
  #Drop first row (NA) from DummyDF
  NewOutputRow <- NewOutputRow[-1,]
  
  #Convert UNDEF to NA to have columns of type numeric
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
