from math import sqrt
import subprocess
import sys

inp = sys.argv[1]
filename = sys.argv[1][:sys.argv[1].rfind('.')]

with open(inp) as file:
  data = [line.strip().split(',') for line in file]
  file.close()

#remove duplicate number field
for line in data:
  if line[0] == line[1]:
    line.remove(line[0])

#input data formatting
couple_list = list()
for line in data:
  for index in range(1, len(line) - 1):
    one = line[index].replace("\"", "").replace("-", " ").replace(".", "").replace("'", "").replace("&", "").strip()
    two = line[index + 1].replace("\"", "").replace("-", " ").replace(".", "").replace("'", "").replace("&", "").strip()
    couple_list.append((one, two))

average = sum([float(k[0]) for k in data]) / len(data)
maximum = max([int(k[0]) for k in data])
minimum = min([int(k[0]) for k in data])
stdev = sqrt(sum([(int(k[0]) - average)**2 for k in data])/len(data)) 
min_path = subprocess.check_output("egrep '^" + str(minimum) + "' " + inp + " | sed 's/^[^,]*,//' | sed 's/,/, /g'", shell = True).strip()
min_path = min_path.decode('utf-8').split('\n')
max_path = subprocess.check_output("egrep '^" + str(maximum) + "' " + inp + " | sed 's/^[^,]*,//' | sed 's/,/, /g'", shell = True).strip()
max_path = max_path.decode('utf-8').split('\n')

#remove duplicate number fields from min/max output strings
def remove_dups(l):
  if isinstance(l, list):
    for i, path in enumerate(l):
      index = path.find(',')
      if path[:index].isnumeric():
        l[i] = l[i][index + 1:]
    return l
  if isinstance(l, str):
    index = l.find(',')
    if l[:index].isnumeric():
      return l[index + 1:]

min_path = remove_dups(min_path)
max_path = remove_dups(max_path)
  

#colors
r = '\033[1;31;40m'
d = '\033[0;37;40m'

print(r + "An average {:.2f} +/- {:.2f} pages were visited on the way to philosophy.".format(average, stdev) + d)
print(r + "Minimum", minimum, "pages to philosophy. (" + str(len(min_path)) + " hit(s))" + d)
[print(r + "Start ->" + d, k) for k in min_path]
print(r + "Maximum", maximum, "pages to philosophy. (" + str(len(max_path)) + " hit(s))" + d)
[print(r + "Start ->" + d, k) for k in max_path]

#output all edges (including duplicates)
with open(filename + ".dot", "w") as file:
  for couple in couple_list:
    file.write('"' + couple[0] + '"' + '->' + '"' + couple[1] + '"')
    file.write('\n') 
  file.close()

#get count of all unique lines for edge labels
uniq_count = subprocess.check_output("cat " + filename + ".dot | sort | uniq -c | sort -rn | sed 's/ *//' | sed 's/ /;/' | sed 's/[()]//g'", shell=True).decode('utf-8')
uniq_count = uniq_count.strip(' ').strip().split('\n')
uniq_count = [k.strip().split(';') for k in uniq_count]

with open( filename + ".dot", "w") as file:
  file.write("digraph {\n")
  for item in uniq_count:
    file.write(item[1])
    file.write('\n')
    if int(item[0]) > 1:
      file.write('[label = "{:} intances"]\n'.format(item[0]))
  file.write("}")
  file.close()

#make graph from .dot file
subprocess.call("dot -Tpng " + filename + ".dot" + " > " + filename + ".png", shell = True)
