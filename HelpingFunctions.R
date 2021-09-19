#
#Helping functions for jDepacWrappeR.R
#


#-------------------------------------------------------------------------
#Function to convert the output of one JDepac run into one dataframe row
ParsejDepacResponse <- function(jDepacResponse) {
  
  #Relevant rows of JDepac response start with INP, CLC or OUT
  CurrentOutput <- grep(
    x = jDepacResponse,
    pattern = "INP;|CLC;|OUT;",
    value = T
  )
  
  #Helping function to split key-value paired JDepac output
  #This function is applied to each item of the JDepac output
  SplitKeyValuePair <- function(OnejDepacResponseItem) {
  
    # OnejDepacResponseItem <- CurrentOutput[1]
    ItemName <- str_extract(
      string = OnejDepacResponseItem,
      pattern = "^.*\\("
    )
    ItemName <- str_replace(
      string = ItemName,
      pattern = ";",
      replacement = ""
    )
    ItemName <- str_replace(
      string = ItemName,
      pattern = "\\(",
      replacement = ""
    )
    ItemName <- str_replace(
      string = ItemName,
      pattern = " ",
      replacement = "_"
    )
    ItemValue <- str_split(
      string = OnejDepacResponseItem,
      pattern = ";"
    )[[1]][3]
    ItemValue <- str_replace(
      string = ItemValue,
      pattern = "\\s*",
      replacement = ""
    )
    
    #Return current item as a one-row one-col data.frame
    DF <- as.data.frame(ItemValue)
    colnames(DF) <- ItemName
    return(DF)
    
  } #end of helping functions
  
  #Apply helping function to current JDepac output row
  OutputRowAsDataFrame <- lapply(
    X = CurrentOutput,
    FUN = SplitKeyValuePair
  )
  #And bind all the one-row one-col data.frames of current JDepac output row
  #to a one-row n-column data.frame
  OutputRowAsDataFrame <- bind_cols(OutputRowAsDataFrame)
  
  #Return
  return(OutputRowAsDataFrame)
}




#-------------------------------------------------------------------------
#Function to convert one CSV input row to one jDepac input string
ConvertCSVInputRowTojDepacInput <- function(OneCSVInputLine) {
  if ( nrow(OneCSVInputLine) != 1 ) {
    stop("Function ConvertInputCSVTojDepac() must be called with a 1-row dataframe.")
  }
  jDepacInputString <- as.vector(OneCSVInputLine)
  CurrentID <- jDepacInputString$ID
  
  #Drop arguments with NA values
  jDepacInputString <- jDepacInputString[names(jDepacInputString) != "ID"]
  ArgNames <- paste0("--",names(jDepacInputString))
  idx_drop <- which(is.na(jDepacInputString))
  if ( length(idx_drop) > 0 ) {
    jDepacInputString <- jDepacInputString[-idx_drop]
    ArgNames <- ArgNames[-idx_drop]
  }
  if ( length(jDepacInputString) == 0 ) {
    stop(paste("All parameters are NA for input ID",CurrentID))
  }
  
  #Adjust name of column "nh3so2" for JDepac (add hyphen)
  idx_nh3so2 <- which(ArgNames == "--nh3so2")
  if ( length(idx_nh3so2) == 1 ) {
    ArgNames[idx_nh3so2] <- "--nh3-so2"
  }
  
  #Concatenate JDepac input string
  jDepacInputString <- paste(ArgNames, jDepacInputString, sep = "=", collapse = " ")
  
  #Return
  return(jDepacInputString)
  
}

