#!/bin/bash

###
# get channel name
###

get_channel_name()
{
    yt-dlp -q --skip-download --write-info-json --playlist-items 1 $url -o "channel_name"
    folder_name=$(gron channel_name.info.json | fgrep "json.channel ="| grep -oP '"\K[^"\047]+(?=["\047])')
    rm -rf channel_name.info.json
}

###
# video processing function
###
downloader()
{
file='url.txt'
lines=$(cat $file)

#loop one url at a time from url.txt
for line in $lines
do
    #getting video title for filenames
    title=$(yt-dlp --get-filename $line -o "%(title)s")
    echo filename is $title

    yt-dlp --skip-download --write-info-json $line -o "a" #download metadata
    yt-dlp --skip-download --write-thumbnail --convert-thumbnails jpg $line -o "$title" #download thumbnail
    yt-dlp -f bestaudio[acodec=opus] $line -k -o "$title.audio" #download opus audio
    yt-dlp --download-archive /home/watora/unraid/Media/youtube/archive.log -f bestvideo[vcodec=vp9.2]/bestvideo[vcodec=vp9] $line -k -N 5 -o "$title.video" #download highest vp9 video with fragments from m3u8/mpd in parallel (change -N value)

    #parse json using gron tool
    metaurl=$(gron a.info.json | fgrep "json.webpage_url =" | grep -oP '"\K[^"\047]+(?=["\047])')
    metauploader=$(gron a.info.json | fgrep "json.uploader =" | grep -oP '"\K[^"\047]+(?=["\047])')

    #merge video and audio, embed thumbnail and add url, uploader and full title into file metadata
    ffmpeg -i "$title.video" -i "$title.audio" -attach "$title.jpg" -metadata:s:t mimetype=image/jpeg -map 0:v:0 -map 1:a:0 -metadata url="$metaurl" -metadata uploader="$metauploader" -c copy "$title.mkv"
    #remove leftover files
    rm -rf "$title.video" "$title.audio" "$title.jpg" "a.info.json"
    sed -i '1d' url.txt
done
}

get_urls()
{
    echo "Downloading IDs"
    yt-dlp --get-id $url > url.txt
}

###
# Main body of script starts here
###
cd /home/watora/unraid/Media/youtube
echo "Input url"
read url
echo "Getting channel name.."
get_channel_name
echo "Channel name is $folder_name"

#check if directory exists, if not, create one.
DIRECTORY=$folder_name
if [ -d "$DIRECTORY" ]; then
    echo "$DIRECTORY is a valid directory"
    cd $folder_name
else
    echo "$DIRECTORY is not valid... creating"
    mkdir $folder_name
    cd $folder_name
fi

#check if url.txt is present in channel directory, if yes it resumes downloading, if not it downloads ids again and redownloads videos checking against archive.log for existing videos
URL_FILE=url.txt
if [ -f "$URL_FILE" ]; then
    echo "Existing url.txt found.. "
    echo "Resuming download.."
    downloader
    rm -rf url.txt
    echo "url.txt has been deleted"
else
    get_urls
    downloader
    rm -rf url.txt
    echo "url.txt has been deleted"
fi
