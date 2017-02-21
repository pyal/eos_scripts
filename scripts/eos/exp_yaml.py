import yaml
import sys
import argparse
import pprint;

def main():
	parser = argparse.ArgumentParser(description='Extract experiment points from yaml db.')

	parser.add_argument("yaml", #type=int,
	                    help="extract data from file")
	parser.add_argument("experiment", 
	                    help="extract data with given description")
	parser.add_argument("fields", 
	                    help="extract data with given fields")
	parser.add_argument("out", 
	                    help="output file")
	
	parser.add_argument('-s', '--show', dest='show', action='store_true', help="show all experiment names in db")
	parser.set_defaults(show=False)

	args = parser.parse_args()
	with open(args.yaml) as f:
		expPoints = yaml.safe_load(f)

		if args.show:
			print args.yaml, ":"
			for exp in expPoints:
				dataMap = expPoints[exp]
				Names = dataMap['Names']
				Data = dataMap['Data']
				print "    ", exp, ":", len(Data), " [", Names, "]"
			return

		dataMap = expPoints[args.experiment]
		Names = dataMap['Names']
		Data = dataMap['Data']
		nArr = Names.split();
		printArr = []
		if args.fields == "":
			args.fields = Names
			
		for field in args.fields.split():
			good = False
			for i in range(0, len(nArr)):
				if nArr[i] == field:
					printArr.append(i)
					good = True
			if not good:
				raise ValueError("Could not find ", field, " in ", Names)

		# if len(printArr) == 0:
		# 	printArr = range(0, len(nArr))

		with open(args.out, 'w') as out:
			out.write(args.fields + "\n")
			for pnt in Data:
				sep = ""
				for i in printArr:
					out.write(sep)
					out.write(str(pnt[i]))
					sep = " "
				out.write('\n')


if __name__ == "__main__":
    main()



