#*******************************************************************************
# @file map_to_csv.py
# @brief This Python script converts a C/C++ .map file into a CSV file
#*******************************************************************************

#===============================================================================
# IMPORTS
#===============================================================================

import sys
import os
import argparse
import re
import csv

#===============================================================================
# MAIN
#===============================================================================

if __name__ == "__main__":
    arg_parser = argparse.ArgumentParser(description="Parse a C/C++ map file into a CSV")
    arg_parser.add_argument("input", help="The input .map file")
    arg_parser.add_argument("output", help="The output .csv file")
    arg_parser.add_argument("--hex-size", action='store_true', dest="hex_size", help="Should 'size' values be in hex rather than decimal")

    args = arg_parser.parse_args()
    
    #---------------------------------------------------------------------------

    #Search until "Linker script and memory map"
    #This is the start of the actual map file data
    with open(args.input, "r") as f:
        line = f.readline()
        while line:
            if line.strip() == "Linker script and memory map":
                break
                
            #Next line
            line = f.readline()
        
        if not line:
            raise Exception("Unable to find start of sections in map file")
           
        #-----------------------------------------------------------------------

        #Regex pattern to match section, address, size, and symbol
        pattern = re.compile("^\s*(?:(?:\.[a-zA-Z0-9_\-]+)(?:\.[a-zA-Z0-9_\-]+)*)? +(0x[0-9a-fA-F]+) +(0x[0-9a-fA-F]+)? *(.*)?$")
        
        #Regex pattern to find the start of a new section
        #pattern_start_of_section = re.compile("^\s*\*\((\.[a-zA-Z0-9_\-]+)\)?")
        
        #Regex pattern to find start of a new sub-section
        pattern_match_start_of_subsection = re.compile("^\s*(\.[a-zA-Z0-9_\-]+)((?:\.[a-zA-Z0-9_\-]+)*)")
       
        with open(args.output, "w", newline="") as csv_file:
            #Start writing to CSV file
            csv_writer = csv.writer(csv_file, delimiter=",", quotechar="\"", quoting=csv.QUOTE_NONNUMERIC)
            
            #Write CSV header
            csv_writer.writerow(["Section", "Sub-Section", "Address", "Size", "Object", "Object Size", "Symbol"])
            
            section = None
            subsection = None
            object_size = 0
            object_name = ""
            
            line_count = 1
            symbol_count = 0
            section_count = 0
            
            while line:
                match_start_of_section = pattern_match_start_of_subsection.match(line)
                
                if match_start_of_section is not None:
                    #Extract the name of the section
                    if match_start_of_section[1] != section:
                        section = match_start_of_section[1]
                        section_count += 1
                    
                    #Extract the name of subsysection
                    subsection = match_start_of_section[2]
                      
                
                if section:
                    match = pattern.match(line)
                    
                    if match is not None:    
                        address = match[1]
                        size = ""
                        
                        #Extract the "symbol" name from the line
                        symbol = match[3] if match[3] else ""
                        symbol_count += 1
                        
                        #Does this line have a "size"?
                        if match[2]:
                            if args.hex_size: #Leave size as hex
                                size = match[2]
                            else: #convert size to decimal
                                size = int(match[2].replace("0x",""), 16)
                            
                            #Assume if lines following this do not have a "size", they share the size of this one
                            object_size = size
                            
                            #Search for the last file path separator in the symbol name
                            #If one exists, then this is probably a file path
                            #We will just assign object_name to the last part of the part (i.e., file name)
                            find1 = symbol.rfind("/")
                            find2 = symbol.rfind("\\")
                            findi = find1 if (find1 > find2) else find2
                            object_name = symbol[findi + 1:] if find1 > 0 else symbol
                        
                        assert section is not None
                        csv_writer.writerow([section, subsection if subsection else "", address if address else "", size, object_name, object_size, symbol])
                        line_count += 1 #Count number of lines written to CSV
                        
                line = f.readline()
            
            print("Wrote:")
            print(f"\t{line_count} lines")
            print(f"\t{section_count} sections")
            print(f"\t{symbol_count} symbols")