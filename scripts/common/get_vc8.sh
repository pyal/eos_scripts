
res_dir=d:/aaa/root/vc8

for dd in vcproj sln  suo ; do
	for aa in $(gfind . -name *.$dd) ; do
		aa1=$(dirname $aa)
		mkdir -p $res_dir/$aa1
		cp $aa $res_dir/$aa1
		echo $aa $aa1
	done
done
