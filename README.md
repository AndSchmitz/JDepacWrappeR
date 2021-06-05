# jDepacWrappeR
Wrapper function to run jDepac 0.2 from CSV input. 
 - See DemoInput.csv for definition of input CSV structure. Column "ID" can be used to identify simulations (e.g. a location name and/or timestamp). It is the only column that is not provided to jDepac as input.
 - See InputMapping.csv for information how CSV column names map to jDepac parameter names.
 - See DemoBatchOutput.csv for an example of batch results.
 
 How to use:
  - Download all files from this repository (e.g. via Code -> Download ZIP above).
  - Create a working directory and a subfolder "Input".
  - Copy the files "jDepacWrappeR.R", "HelpingFunctions.R" and "JDepac-0.2.1.jar" (not included in this repository) into the working directory.
  - Copy the files "DemoInput.csv" and "InputMapping.csv" into the "Input" folder.
  - Open the file "jDepacWrappeR.R" and adjust the variable "WorkDir" to match the path of the working directory.
  - Execute the "jDepacWrappeR.R" to run all lines in the "DemoInput.csv" one by one through jDepac. The results will be saved in a subfolder named "Output" in the working directory. R libraries "tidyverse" and "stringr" must be installed.
  - Change the content "DemoInput.csv" to run different scenarios with jDepac.
 

Currently only tested for MS Windows.
