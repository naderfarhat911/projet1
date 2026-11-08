#!/bin/bash
# usage: build.sh <frames_dir> <out.mp4>
set -e
S=/tmp/claude-0/-home-user-projet1/4e2838d7-914f-55b1-aeaf-b41d60ef7caa/scratchpad
V2=/root/.claude/uploads/4e2838d7-914f-55b1-aeaf-b41d60ef7caa/4921a68e-VID_20261108_083333_234.mp4
FR=$1; OUT=$2; T=$S/seg; mkdir -p $T; cd $S
B=fonts/Bebas.ttf; D=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
ENC="-c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r 30 -an"
GOLD=0xD4AF37
# text helpers: title(text,size,y,start,end) with fade
tt(){ echo "drawtext=fontfile=$B:text='$1':fontsize=$2:fontcolor=$5:x=(w-tw)/2:y=$3:shadowcolor=black@0.8:shadowx=4:shadowy=4:alpha='if(lt(t,$4),0,min(1,(t-$4)*4))'"; }
V2F="scale=1080:1920,setsar=1,fps=30"
grad="drawbox=x=0:y=ih*0.62:w=iw:h=ih*0.38:color=black@0.45:t=fill"
# A banner
ffmpeg -v error -y -ss 0 -t 2.5 -i $V2 -vf "$V2F,$grad,$(tt 'SABER' 230 1250 0.2 white),$(tt 'BARBERSHOP' 120 1480 0.5 $GOLD)" $ENC $T/a.mp4
# B pole
ffmpeg -v error -y -ss 4.0 -t 2.0 -i $V2 -vf "$V2F,$grad,$(tt 'MONTRÉAL' 170 1350 0.1 white)" $ENC $T/b.mp4
# C logo
ffmpeg -v error -y -ss 8.0 -t 2.0 -i $V2 -vf "$V2F,$grad,$(tt 'L’ART DU BARBIER' 130 1380 0.1 $GOLD)" $ENC $T/c.mp4
# D interior
ffmpeg -v error -y -ss 10.2 -t 2.5 -i $V2 -vf "$V2F,$grad,$(tt 'UN SALON' 140 1300 0.1 white),$(tt 'HAUT DE GAMME' 140 1450 0.3 $GOLD)" $ENC $T/d.mp4
# E face-swapped salon scene (10s), vertical layout: blurred bg + sharp center
VL="split[bg][fg];[bg]scale=-2:1920,crop=1080:1920,boxblur=30:3,eq=brightness=-0.15[bg2];[fg]scale=-2:1200,crop=1080:1200[fg2];[bg2][fg2]overlay=0:360"
ffmpeg -v error -y -framerate 24 -i $FR/%04d.png -filter_complex "$VL,fps=30,\
drawtext=fontfile=$B:text='COUPE SUR MESURE':fontsize=120:fontcolor=white:x=(w-tw)/2:y=150:shadowcolor=black:shadowx=4:shadowy=4:enable='lt(t,3.4)',\
drawtext=fontfile=$B:text='DÉGRADÉ • BARBE • RASAGE':fontsize=100:fontcolor=$GOLD:x=(w-tw)/2:y=170:shadowcolor=black:shadowx=4:shadowy=4:enable='between(t,3.4,6.8)',\
drawtext=fontfile=$B:text='FINITION PARFAITE':fontsize=120:fontcolor=white:x=(w-tw)/2:y=150:shadowcolor=black:shadowx=4:shadowy=4:enable='gte(t,6.8)',\
drawtext=fontfile=$D:text='Votre style, notre passion':fontsize=50:fontcolor=white@0.9:x=(w-tw)/2:y=1660:shadowcolor=black:shadowx=2:shadowy=2" $ENC $T/e.mp4
# F real barber + client
ffmpeg -v error -y -ss 13.0 -t 2.3 -i $V2 -vf "$V2F,$grad,$(tt 'DES CLIENTS SATISFAITS' 120 1400 0.1 white)" $ENC $T/f.mp4
# G barber frontal
ffmpeg -v error -y -ss 15.65 -t 1.35 -i $V2 -vf "$V2F,$grad,$(tt 'VOTRE BARBIER' 130 1400 0.05 $GOLD)" $ENC $T/g.mp4
# H end card (7.2s) on last swapped frame
LAST=$(ls $FR/*.png | tail -1)
ffmpeg -v error -y -loop 1 -t 7.35 -framerate 30 -i $LAST -filter_complex "[0]scale=-2:1920,crop=1080:1920:'(iw-1080)/2+40*t':0,boxblur=12:2,eq=brightness=-0.32,\
drawbox=x=140:y=400:w=800:h=4:color=$GOLD:t=fill,\
$(tt 'SABER' 260 480 0.1 white),$(tt 'BARBERSHOP' 140 740 0.3 $GOLD),\
$(tt 'RÉSERVEZ DÈS MAINTENANT' 100 1000 0.8 white),\
drawbox=x=140:y=1150:w=800:h=4:color=$GOLD:t=fill,\
drawtext=fontfile=$D:text='Instagram / TikTok':fontsize=46:fontcolor=white@0.8:x=(w-tw)/2:y=1240:alpha='min(1,max(0,(t-1.3)*3))',\
drawtext=fontfile=$D:text='@saberbarbershop_mtl':fontsize=66:fontcolor=white:x=(w-tw)/2:y=1310:alpha='min(1,max(0,(t-1.3)*3))',\
drawtext=fontfile=$D:text='WhatsApp':fontsize=46:fontcolor=white@0.8:x=(w-tw)/2:y=1460:alpha='min(1,max(0,(t-1.8)*3))',\
drawtext=fontfile=$B:text='+1 438-308-3228':fontsize=130:fontcolor=$GOLD:x=(w-tw)/2:y=1520:alpha='min(1,max(0,(t-1.8)*3))',\
fade=t=out:st=6.75:d=0.6" $ENC $T/h.mp4
printf "file '%s'\n" $T/a.mp4 $T/b.mp4 $T/c.mp4 $T/d.mp4 $T/e.mp4 $T/f.mp4 $T/g.mp4 $T/h.mp4 > $T/list.txt
ffmpeg -v error -y -f concat -safe 0 -i $T/list.txt -c copy $T/video.mp4
# audio: music from video 2, extended to 30s
ffmpeg -v error -y -i $V2 -vn -ac 2 -ar 44100 $T/music.wav
ffmpeg -v error -y -t 21.2 -i $T/music.wav -ss 1.0 -t 10.5 -i $T/music.wav -filter_complex "[0][1]acrossfade=d=0.6:c1=tri:c2=tri,atrim=0:30,afade=t=in:d=0.2,afade=t=out:st=28.8:d=1.2[a]" -map "[a]" -c:a aac -b:a 192k $T/audio.m4a
ffmpeg -v error -y -i $T/video.mp4 -i $T/audio.m4a -map 0:v -map 1:a -c:v copy -c:a copy -t 30 -movflags +faststart $OUT
ffprobe -v error -show_entries format=duration -of csv=p=0 $OUT
