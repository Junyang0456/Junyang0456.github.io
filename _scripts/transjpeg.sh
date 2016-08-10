#!/bin/bash
#
# Convert images to progressive jpeg format.

DIR='/home/junyang/Desktop/junyang.github.io/'

for i in `find ${DIR}images -type f -name *.jpg`; do
#	if [ "${i##*.}" != jpg ]; then
#		convert "$i" "${i%.*}.jpg"
#		rm -f "$i"
#		i="${i%.*}.jpg"
#	fi
	jpegtran -copy none -optimize -outfile $i $i
	jpegtran -copy none -progressive -outfile $i $i
done

# replace png|gif with progressive jpg
#for i in `find ${DIR}_posts -type f -name *.md`; do
#	sed -r -i 's@(!\[.*\]\(/images/.*)(\<png\>|\<gif\>)@\1jpg@g' $i
#done
