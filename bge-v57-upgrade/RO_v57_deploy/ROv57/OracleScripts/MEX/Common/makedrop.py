import sys

infile = sys.argv[1]
input = file(infile, "r")

if len(sys.argv) > 2:
   outfile = sys.argv[2]
else:
   outfile = "drop_" + infile
   
output = file(outfile, "w")
newlines = []

for line in input:
   tokens = line.split()
   if len(tokens) >= 1:
      if (tokens[0].lower() == 'create'):
         newline = "DROP TYPE " + tokens[4] + ";\n"
         newlines.append(newline)
      
newlines.reverse()
output.writelines(newlines)
