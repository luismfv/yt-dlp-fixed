# yt-dlp-fixed
My (bad) attempt of getting yt-dlp to embed video, audio, thumbnail and metadata in one go with ffmpeg instead of doing it multiple times like yt-dlp chooses to do, saving unnecessary writes to drives.

Needs gron(https://github.com/tomnomnom/gron) in order to parse metadata json

Make sure to change lines 4 and 5 to their appropriate paths, same for --download-archive location on line 25 (if you don't want an archive simple delete the flag).

I tried my best to comment what should be needed in the script itself. It grabs urls from channels into a url.txt inside the channel folder and will loop the whole file until the channel is done, once everything is done leftover files are deleted.

If you found a problem please let me know :)
