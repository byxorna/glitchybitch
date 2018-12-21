#!/usr/bin/env bash
# https://github.com/wayspurrchen/moshy
set -ex

input="$1"
pdupeframes=600
preframes=10

[[ -z $input ]] && echo "need input as \$1" && exit 1

rootdir="$(pwd)"
tmpdir="$(mktemp -d)"
file="$(basename "$input")"

if [[ ! $input =~ .avi$ ]] ; then
  ffmpeg -y -i "$input" "$tmpdir/$file.avi"
  input="$tmpdir/$file.avi"
  file="$(basename "$input")"
fi


moshy -m prep -i "$input" -o "$tmpdir/prep-$file"
# find a good frame
framecount="$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 "$tmpdir/prep-$file")"
randomframe="$(($RANDOM % $framecount))"
echo "pduping frame $randomframe for $pdupeframes"
moshy -m pdupe -i "$tmpdir/prep-$file" -f $randomframe -d $pdupeframes -o "$tmpdir/pdupe-$file"
moshy -m bake -i "$tmpdir/pdupe-$file" -o "$tmpdir/bake-$file"
# slice out from whereever we started our glitch, and include up to $preframes before
fromframe="$(($randomframe - $preframes))"
if [[ $fromframe -le 0 ]] ; then
  fromframe=0
fi
toframe=$(($randomframe + $pdupeframes))
echo "slicing $fromframe (glitchstart $randomframe) to $toframe ($preframes preframes, $pdupeframes pdupeframes)"
ffmpeg -y -i "$tmpdir/bake-$file" -vf 'select=gte(n\,'$fromframe')*lte(n\,'$toframe'),setpts=PTS-STARTPTS' "$tmpdir/sliced-$file"

#mv $tmpdir/bake-$file ./glitched-$file
# spit out a dumb gif
ffmpeg -y -i "$tmpdir/sliced-$file" -vf scale=w=480:h=-1:force_original_aspect_ratio=decrease -loop -0 "./glitched-$file.gif"

rm -rf "$tmpdir"



