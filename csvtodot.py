from math import sqrt
import subprocess
import sys

inp = sys.argv[1]
filename = sys.argv[1][:sys.argv[1].rfind('.')]

with open(inp) as file:
  data = [line.strip().split(',') for line in file]

#remove duplicate number field
if len(data) > 1:
  for line in data:
    if line[0] == line[1]:
      line.remove(line[0])

#input data formatting
couple_list = list()
for line in data:
  for index in range(1, len(line) - 1):
    one = line[index].replace("\"", "").replace("-", " ").replace(".", "").replace("'", "").replace("&amp;", "and").strip()
    two = line[index + 1].replace("\"", "").replace("-", " ").replace(".", "").replace("'", "").replace("&amp;", "and").strip()
    couple_list.append((one, two))

#output all edges (including duplicates)
with open(filename + ".dot", "w") as file:
  for couple in couple_list:
    file.write('"' + couple[0] + '"' + '->' + '"' + couple[1] + '"')
    file.write('\n') 

#get count of all unique lines for edge labels
uniq_count = subprocess.check_output("cat " + filename + ".dot | sort | uniq -c | sort -rn | sed 's/ *//' | sed 's/ /;/' | sed 's/[()]//g'", shell=True).decode('utf-8')
uniq_count = uniq_count.strip(' ').strip().split('\n')
uniq_count = [k.strip().split(';') for k in uniq_count]

with open( filename, "w") as file:
  file.write("digraph {\n")
  for item in uniq_count:
    file.write(item[1])
    file.write('\n')
    if int(item[0]) > 1:
      file.write('[label = "{:} intances"]\n'.format(item[0]))
  file.write("}")

#make graph from .dot file
subprocess.call("rm " + filename + ".dot", shell = True)
subprocess.call("dot -O -Tpng " + filename, shell = True)
