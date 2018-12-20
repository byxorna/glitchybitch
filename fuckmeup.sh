#!/usr/bin/env bash
# https://github.com/wayspurrchen/moshy
# gem install moshy
set -e


input="$1"
output="fuck.avi"
pdupeframes=65
preframes=10

[[ -z $input ]] && echo "need input as \$1" && exit 1

rootdir="$(pwd)"
tmpdir="$(mktemp -d)"

# find a good frame
framecount="$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 $input)"
randomframe="$(($RANDOM % $framecount))"
file="$(basename $input)"

moshy -m prep -i $input -o $tmpdir/$file
echo "pduping frame $randomframe for $pdupeframes"
moshy -m pdupe -i $tmpdir/$file -f $randomframe -d $pdupeframes -o $tmpdir/pdupe-$file
moshy -m bake -i $tmpdir/pdupe-$file -o $tmpdir/bake-$file
# slice out from whereever we started our glitch, and include up to $preframes before
fromframe="$(($randomframe - $preframes))"
if [[ $fromframe -le 0 ]] ; then
  fromframe=0
fi
toframe=$(($randomframe + $pdupeframes))
echo "slicing $fromframe (glitchstart $randomframe) to $toframe ($preframes preframes, $pdupeframes pdupeframes)"
ffmpeg -y -i $tmpdir/bake-$file -vf 'select=gte(n\,'$fromframe')*lte(n\,'$toframe'),setpts=PTS-STARTPTS' $tmpdir/sliced-$file

#mv $tmpdir/bake-$file ./glitched-$file
# spit out a dumb gif
 ffmpeg -y -i $tmpdir/sliced-$file -vf scale=w=480:h=-1:force_original_aspect_ratio=decrease -loop -0 ./glitched-$file.gif

