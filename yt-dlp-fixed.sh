#!/bin/bash
echo input channel name
read channel
mkdir /home/watora/unraid/Media/youtube/$channel
cd /home/watora/unraid/Media/youtube/$channel
echo input url
read url

#get channel IDs and place them on url.txt
yt-dlp --get-id $url > url.txt

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
    yt-dlp -f bestaudio $line -k -o "$title.audio" #download opus audio
    yt-dlp --download-archive /home/watora/unraid/Media/youtube/archive.log -f bestvideo[vcodec=vp9.2]/bestvideo[vcodec=vp9] $line -k -N 5 -o "$title.video" #download highest vp9 video with fragments from m3u8/mpd in parallel (change -N value)

    #parse json using gron tool
    metaurl=$(gron a.info.json | fgrep "json.webpage_url =" | grep -oP '"\K[^"\047]+(?=["\047])')
    metauploader=$(gron a.info.json | fgrep "json.uploader =" | grep -oP '"\K[^"\047]+(?=["\047])')

    echo url is $metaurl
    echo uploader is $metauploader

    #merge video and audio, embed thumbnail and add url, uploader and full title into file metadata
    ffmpeg -i "$title.video" -i "$title.audio" -attach "$title.jpg" -metadata:s:t mimetype=image/jpeg -map 0:v:0 -map 1:a:0 -metadata url="$metaurl" -metadata uploader="$metauploader" -c copy "$title.mkv"
    #remove leftover files
    rm -rf "$title.video" "$title.audio" "$title.jpg" "a.info.json"
done

rm -rf url.txt
echo finished downloading
