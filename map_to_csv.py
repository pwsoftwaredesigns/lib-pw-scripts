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
        
        #pattern = re.compile("^\s*(?P<section>.[a-zA-Z_\-]+)? +(?P<address>0x[0-9a-fA-F]+) +(?P<size>0x[0-9a-fA-F]+)? *(?P<symbol>.*)?")
        #print(pattern.groupindex)
        pattern = re.compile("^\s*(\.[a-zA-Z_\-]+)? +(0x[0-9a-fA-F]+) +(0x[0-9a-fA-F]+)? *(.*)?")
       
        with open(args.output, "w", newline="") as csv_file:
            #Start writing to CSV file
            csv_writer = csv.writer(csv_file, delimiter=",", quotechar="\"", quoting=csv.QUOTE_NONNUMERIC)
            
            #Write CSV header
            csv_writer.writerow(["Section", "Address", "Size", "Object", "Object Size", "Symbol"])
            
            section = None
            group_size = 0
            object_file = ""
            
            line_count = 1
            object_count = 0
            symbol_count = 0
            
            while line:
                match = pattern.match(line)
                
                if match is not None:
                    if match[1] is not None:
                        section = match[1]
                        
                    address = match[2] if match[2] else ""
                    size = ""
                    
                    if match[3]:
                        if args.hex_size: #Leave size as hex
                            size = match[3]
                        else: #convert size to decimal
                            size = int(match[3].replace("0x",""), 16)
                            
                        group_size = size
                        
                    symbol = match[4] if match[4] else ""
                    symbol_count += 1
                    if symbol.endswith(".o"):
                        #This is an object file
                        #Assume all following symbols are children of this file
                        #UNTIL another object file is encountered
                        object_file = symbol
                        object_count += 1
                    
                    csv_writer.writerow([section, address, size, object_file, group_size, symbol])
                    line_count += 1
                        
                line = f.readline()
            
            print("Wrote:")
            print("\t" + str(line_count) + " lines")
            print("\t" + str(object_count) + " object files")
            print("\t" + str(symbol_count) + " symbols")