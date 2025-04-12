#!/usr/bin/env bash

#  0x001d GPS Date                                -      -      -      -      -
#  0x0132 Date and Time                           -      -      -      -      -
#  0x9003 Date and Time (Original)                -      -      -      -      -
#  0x9004 Date and Time (Digitized)               -      -      -      -      -
#  0x9010 Offset Time For DateTime                -      -      -      -      -
#  0x9011 Offset Time For DateTimeOriginal        -      -      -      -      -
#  0x9012 Offset Time For DateTimeDigitized

[[ ! -f $1 ]] && echo "You need to provide a valid file as argument, $1 does not seem to be one" && exit 1

EXIF_TAGS=(0x001d 0x0132 0x9003 0x9004 0x9010 0x9011 0x9012)


for TAG in "${EXIF_TAGS[@]}"
do
  echo "Checking $1"
  exif -t $TAG $1
done


#exif -l all-for-test/educostafotografia-romananmoises-casamento-198.jpg  | grep -i date | cut -d' ' -f1 | xargs -I {} for file in $(ls -1 all-for-test)\; do exif -t {} all-for-test/$file\; done
