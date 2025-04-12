#!/bin/bash

cfgSource="$1"
cfgDestRoot="$2"
toUpper() {
    echo $1 | tr  "[:lower:]" "[:upper:]"
}
toLower() {
    echo $1 | tr "[:upper:]" "[:lower:]"
}
escapeSpaces(){
    echo $1 | sed 's/ /\\ /g'
}
if [ "$#" != "2" ]; then
    echo "Usage: $0 <source> <destination>"
    exit 1
fi
which stat > /dev/null
# make sure stat command is installed
if [ $? -eq 1 ]
then
    echo "stat command not found!"
    exit 2
fi
which identify > /dev/null
# make sure identify command is installed
if [ $? -eq 1 ]
then
    echo "identify command not found!"
    exit 3
fi

which ffprobe > /dev/null
# make sure ffprobe command is installed
if [ $? -eq 1 ]
then
    echo "ffprobe command not found!"
    exit 3
fi


# using a tmp file you can have spaces in the file path
find "$cfgSource" -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.nef" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.avi" -o -iname "*.flv" -o -iname "*.VOB" -o -iname "*.mov" -o -iname "*.mpg" -o -iname "*.mp4" -o -iname "*.gif" > images.tmp

cat ./images.tmp | while read f;
do
       
        # Make sure the file we've been given by find actually exists.
        if [ -f "${f}" ]; then
                echo " "
                FILETYPE=$(toUpper ${f#*.})
                timestamp=""
                if [ "$FILETYPE" = "JPG" -o "$FILETYPE" = "NEF" -o "$FILETYPE" = "PNG" -o "$FILETYPE" = "JPEG" -o "$FILETYPE" = "BMP" ]; then

                    EXIF_TAGS=(DateTimeOriginal DateTimeDigitized DateTime)
                    for TAG in "${EXIF_TAGS[@]}"
                    do
                      timestamp="$(identify -format "%[exif:${TAG}]" "${f}")"
                    
                      if [ ! "${timestamp}" = "" ]; then
                          break
                      fi

                    done
                  
                    timestamp=${timestamp%T*}
                elif [ "$FILETYPE" = "MOV" -o "$FILETYPE" = "MP4" -o "$FILETYPE" = "FLV" -o "$FILETYPE" = "MPG" -o "$FILETYPE" = "VOB" -o "$FILETYPE" = "AVI" ]; then
                    # Video files needs a different way to check their metadata  
                    timestamp="$(ffprobe -v quiet "${f}" -show_entries stream=index,codec_type:stream_tags=creation_time:format_tags=creation_time |  grep -Eo '20([0-9]{2}-){2}[0-9]{2}' | head -1)"
                fi

                #If identify fails to read the date from exif
                # or file is not an image, try to get date from filename
                if [ "${timestamp}" = "" ]; then

                    # All together in the file name 
                    # Ex: 20110101
                    # also adding dashes so it will end up as
                    #   2011-01-01
                    timestamp=$(echo "$f" | grep -Eo '20[0-9]{6}' | sed 's/\(....\)\(..\)/\1-\2-/')
                    
                    # Double checking if possible date found is not in the future
                    if [ ! "${timestamp}" = "" ]; then
                        yearFound=$(echo $timestamp | cut -c 1-4)

                        currentYear=$(date '+%Y')
                        if [ $yearFound > $currentYear ]; then
                            timestamp=""
                        fi
                    fi

                fi
                if [ "${timestamp}" = "" ]; then

                    # Dash separated datee
                    # Ex: 2020-01-02
                    timestamp=$(echo "$f" | grep -Eo '20([0-9]{2}-){2}[0-9]{2}')

                fi

                # Last resort, get date from last modified file metadata
                if [ "${timestamp}" = "" ]; then

                    if [[ $OSTYPE == 'darwin'* ]]; then
                      timestamp=$(stat -f %SB -t %Y-%m-%d "$f")
                    else
                      timestamp=$(stat -c %y "$f")
                    fi
                fi
                # Looks like there are three possible timestamp formats:
                #       2014-05-05T14:46:47.16+01:00
                #       2015:02:28 12:57:50
                #       2013-05-25 19:24:26.000000000 +0100
                # Thankfully, cut will handle all of these formats.
                y=$(echo $timestamp | cut -c 1-4)
                m=$(echo $timestamp | cut -c 6-7)
                d=$(echo $timestamp | cut -c 9-10)
                #dateBaseDir=$y/$m/$d
                dateBaseDir=$y/$m
                destFile=$cfgDestRoot/$dateBaseDir/$(basename "${f}")
                # If the directory doesn't exist recursively create it.
                if [ ! -d "$cfgDestRoot/$dateBaseDir" ]; then
                        mkdir -p "$cfgDestRoot/$dateBaseDir"
                fi
                # Move the file.
                if [ -f "${destFile}" ]; then
                        # Existing file found.
                        echo "Existing file found: ${destFile}"
                        echo "Source: ${f}"
                        # Is it the same file? If so, delete the file we're processing.
                        md5src=$(md5sum "${f}")
                        md5src=${md5src% *}
                        md5dst=$(md5sum "${destFile}")
                        md5dst=${md5dst% *}
                        if [ $md5src = $md5dst ]; then
                                echo "Duplicate found, discarding identical file"
                                rm "$f"
                        else
                                # Is this file larger than the existing one?
                                sizeSrc=$(stat -c%s "$f")
                                sizeDst=$(stat -c%s "$destFile")
                                echo "Duplicate Found, keeping the larger file."
                                if [ $sizeSrc -gt $sizeDst ]; then
                                        mv "$f" "$destFile"
                                        #echo "mv \"$f\" \"$destFile\""
                                else
                                        rm "$f"
                                        #echo "rm \"$f\""
                                fi
                        fi
                else
                        mv "$f" "$destFile"
                        echo "Moved $f to $destFile"
                fi
        else
            echo "${f}"
            echo "File not found!"
        fi
        echo "== =="
done
#Now delete empty folders from source
find "$cfgSource" -iname "*.DS_Store" -exec rm -v {} +
find "$cfgSource" -iname "*.thm" -exec rm -v {} +
find "$cfgSource" -iname "*.IND" -exec rm -v {} +
find "$cfgSource" -iname "Thumbs.db" -exec rm -v {} +
find "$cfgSource" -type d -empty -delete
#Delete temporary file
#rm images.tmp
