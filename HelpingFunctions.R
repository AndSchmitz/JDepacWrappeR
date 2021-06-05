#
#Helping functions for jDepacWrappeR.R
#



#-------------------------------------------------------------------------
#Function to convert the output of one jDepac run into one dataframe row
ParsejDepacResponse <- function(jDepacResponse) {
  
  #Row 1 of jDepac output: Version
  Version <- data.frame(
    version = jDepacResponse[1]
  )
  
  #Row 2...n of jDepac output
  #Each row consists of an identifier (CRA, CRB, CRC, VDP) followed by whitespace and numer of key=value pairs
  ListOfParsedResponses <- list()
  for ( i in 2:length(jDepacResponse) ) {
    
    #Skip unexpected output rows:
    ValidLineStarts <- c("CRA", "CRB", "CRC", "VDP")
    CurrentLineStart <- substr(x =jDepacResponse[i], start = 1, stop = 3)
    if ( !(CurrentLineStart %in% ValidLineStarts) ) {
      next
    }
    
    CurrentResponseComponent <- unlist(strsplit(
      x = jDepacResponse[i],
      split = " "
    ))
    if ( length(CurrentResponseComponent) == 0 ) {
      #Skip if response line is empty string
      next
    }
    #Parse current component
    CurrentComponentParsed <- ParsejDepacResponseComponent(CurrentResponseComponent)
    #Append CurrentComponentParsed to list of results
    ListOfParsedResponses[[i]] <- CurrentComponentParsed
    
  } #end of loop over jDepac output lines
  
  #Drop attributes and convert factor levels to character
  ReturnValue <- bind_cols(Version,ListOfParsedResponses)
  ReturnValue[] <- lapply(ReturnValue, unname)
  ReturnValue[] <- lapply(ReturnValue, as.character)
  
  #Return
  return(ReturnValue)
}



#-------------------------------------------------------------------------
#Function to parse a single jDepac output component (INP, CRA, CLC, RES)
ParsejDepacResponseComponent <- function(jDepacResponseComponent) {
  
  Components <- unlist(strsplit(
    x = jDepacResponseComponent,
    split = " "
  ))
  #Prepend identifier (first element: CRA, CRB, etc.) to all other elements
  #to guarantee unique unique column names
  Identifier <- Components[1]
  Components <- Components[-1]
  Components <- paste0(Identifier,"_",Components)
  #Extract data from key=value pairs
  Keys <- vector()
  Values <- vector()
  for ( i in 1:length(Components) ) {
    CurrentKeyValuePair <- SplitKeyValuePair(Components[i])
    Keys <- as.character(c(Keys,CurrentKeyValuePair["Key"]))
    Values <- as.character(c(Values,CurrentKeyValuePair["Value"]))
  }
  
  ParsedComponent <- Values
  names(ParsedComponent) <- Keys
  ParsedComponent <- as.data.frame(t(ParsedComponent))
  return(ParsedComponent)
  
}



#-------------------------------------------------------------------------
#Function to split a "key=value" pair into a named vector
SplitKeyValuePair <- function(KeyValuePair, sep = "=") {
  nOccurrencesSepChar <- str_count(
    string = KeyValuePair,
    pattern = sep
  )
  if ( nOccurrencesSepChar != 1 ) {
    stop(paste0("Error in SplitKeyValuePair(): Separator \"",sep,"\" occurs zero or multiple times in string \"",KeyValuePair,"\""))
  }
  Key = unlist(strsplit(
    x = KeyValuePair,
    split = sep
  ))[[1]]
  Value = unlist(strsplit(
    x = KeyValuePair,
    split = sep
  ))[[2]]
  return(c(Key = Key, Value = Value))
}



#-------------------------------------------------------------------------
#Function to convert one CSV input row to one jDepac input string
ConvertCSVInputRowTojDepacInput <- function(OneCSVInputLine) {
  if ( nrow(OneCSVInputLine) != 1 ) {
    stop("Function ConvertInputCSVTojDepac() must be called with a 1-row dataframe.")
  }
  jDepacInputString <- ""
  
  #Treat special columns: -o background concentrations
  BackgroundConcentrations <- paste0(
    "-o",
    OneCSVInputLine[1,"CmpConcentration"],
    ",",
    OneCSVInputLine[1,"BackgroundNH3"],
    ",",
    OneCSVInputLine[1,"BackgroundSO2"],
    " "
  )
  nMissing <- str_count(
    string = BackgroundConcentrations,
    pattern = "NA"
  )
  #If all three parameter values required for option -o are present,
  #append to jDepac input
  if ( nMissing == 0 ) {
    jDepacInputString <- paste0(jDepacInputString,BackgroundConcentrations)
    #if none of three is provided - ignore parameter
  } else if ( nMissing == 3 ) {
    #Else stop
  } else {
    stop("Values for either all or none of the columns CmpConcentration, BackgroundNH3, BackgroundSO2 must be provided.")
  }
  
  #Treat special columns: -U wind speed
  WindSpeed <- paste0(
    "-U",
    OneCSVInputLine[1,"ua"],
    ",",
    OneCSVInputLine[1,"ha"],
    " "
  )
  nMissing <- str_count(
    string = WindSpeed,
    pattern = "NA"
  )  
  #If both parameter values required for option -U are present,
  #append to jDepac input
  if ( nMissing == 0 ) {
    jDepacInputString <- paste0(jDepacInputString,WindSpeed)
    #if none of two is provided - ignore parameter
  } else if ( nMissing == 2 ) {
    #Else stop
  } else {
    stop("Values for either all or none of the columns ua and ha must be provided.")
  }  
  
  #Treat special columns: -Z Surface roughness
  Roughness <- paste0(
    "-Z",
    OneCSVInputLine[1,"z0"],
    ",",
    OneCSVInputLine[1,"d0"],
    " "
  )
  nMissing <- str_count(
    string = Roughness,
    pattern = "NA"
  )    
  #If both parameter values required for option -Z are present,
  #append to jDepac input
  if ( nMissing == 0 ) {
    jDepacInputString <- paste0(jDepacInputString,Roughness)
    #if none of two is provided - ignore parameter
  } else if ( nMissing == 2 ) {
    #Else stop
  } else {
    stop("Values for either all or none of the columns z0 and d0 must be provided.")
  }   
  
  #Treat special columns: -D Aerosol size
  AerosolSize <- paste0(
    "-D",
    OneCSVInputLine[1,"dae"],
    ",",
    OneCSVInputLine[1,"rho"],
    " "
  )
  nMissing <- str_count(
    string = AerosolSize,
    pattern = "NA"
  )
  #If both parameter values required for option -D are present,
  #append to jDepac input
  if ( nMissing == 0 ) {
    jDepacInputString <- paste0(jDepacInputString,AerosolSize)
    #if none of two is provided - ignore parameter
  } else if ( nMissing == 2 ) {
    #Else stop
  } else {
    stop("Values for either all or none of the columns dae and rho must be provided.")
  }   
  
  #Delete special columsn from CSV
  SpecialColumns <- c("CmpConcentration","BackgroundNH3","BackgroundSO2","ua","ha","z0","d0","dae","rho")
  CurrentCSVInputLine <- CurrentCSVInputLine[!(colnames(CurrentCSVInputLine) %in% SpecialColumns)]
  
  #Append remaining columns one by one to jDepacInputString
  for ( iCol in 1:ncol(CurrentCSVInputLine) ) {
    CurrentColName <- colnames(CurrentCSVInputLine)[iCol]
    CurrentValue <- CurrentCSVInputLine[1,CurrentColName]
    
    #Skip ID column
    if ( CurrentColName == "ID" ) {
      next
    }
    
    #Skip empty input lines
    if ( is.na(CurrentValue) ) {
      next
    }
    
    #Identify the jDepac parameter name corresponding to current CSV column name
    CurrentParameterName <- InputTranslation$jDepacParameterName[InputTranslation$CSVColumnName == CurrentColName]
    
    #Append current parameter to jDepac input string
    jDepacInputString <- paste0(jDepacInputString," -",CurrentParameterName,CurrentValue)
  }
  return(jDepacInputString)
}
