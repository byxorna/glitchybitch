#!/usr/bin/env ruby
require 'aviglitch'
require 'optparse'
require 'moshy'

@opts = {
  input: [],
  output: nil,
}

def main
  OptionParser.new do |opts|
    #opts.on('-i', '--input FILE', 'input file') {|f| @opts[:input] << f}
    opts.on('-o', '--output FILE', 'output file') {|f| @opts[:output] = f}
  end.parse!

  ARGV.each {|a| @opts[:input] << a }


  if @opts[:input].empty?
    abort 'need --input files'
  end

  if @opts[:output].nil?
    abort 'missing --output'
  end

  frames = glitch3 @opts[:input]
  puts frames.class
  n = AviGlitch.open(frames)
  tmp = "#{@opts[:output]}-tmp"
  n.output tmp
  # bake down 
  moshy = Moshy::Bake.new
  moshy.prep(tmp, @opts[:output], false, nil, 4196)
  File.unlink tmp
end

def glitch3 inputs
  # open all inputs, and smash their keyframes and pframes together
  #input = inputs.shuffle.first
  pframes = nil
  iframes = nil
  frames = nil
  inputs.each do |input|
   # make empty Frames objects
   frames = AviGlitch.open(input).frames.clear if frames.nil?
   iframes = AviGlitch.open(frames).frames.clear if iframes.nil?
   pframes = AviGlitch.open(frames).frames.clear if pframes.nil?

   a = AviGlitch.open(input)
   a.frames.each do |f|
     frames.push(f)
     iframes.push(f) if f.is_iframe?
     pframes.push(f) if f.is_pframe?
   end
   a.close
  end

  startframe = rand(iframes.size)
  puts "got startframe #{startframe} of #{iframes.size} keyframes (total frames: #{frames.size})"
  keepstartframes = 5+rand(15)
  newframes = frames[startframe, keepstartframes]
  #puts newframes.inspect
  3.times do
    pf = pframes[rand(pframes.size), 1]
    newframes.concat(pf*50)
  end

  return newframes
end

def glitch2 inputs
  # open all inputs, and smash their keyframes and pframes together
  keyframeindexes = []
  pframeindicies = []
  totalframes = a.frames.size
  a.frames.each_with_index do |f,i|
    pframeindicies << i if f.is_pframe?
    keyframeindexes << i if f.is_iframe?
  end
  startframe = keyframeindexes[rand(keyframeindexes.length)]
  puts "got startframe #{startframe} of #{keyframeindexes.length} keyframes (total frames: #{totalframes})"
  puts "got #{pframeindicies.length} pframes: #{pframeindicies.inspect}"
  puts "got #{keyframeindexes.length} keyframes: #{keyframeindexes.inspect}"
  keepstartframes = 15
  frames = a.frames[startframe,keepstartframes]

  # add pframes, starting from the next pframe after startframe
  pframeindex = pframeindicies.each_with_index.select{|x,i| x>=(startframe+keepstartframes) }.first[1]
  puts "Got #{startframe} startframe, and next pframe is #{pframeindicies[pframeindex]} (index=#{pframeindex})"
  #dupeis = pframeindicies[pframeindex,1]
  dupeis = 1.times.map do |i|
    pframeindicies[pframeindex + rand(pframeindicies[pframeindex, pframeindicies.size].size)]
  end.sort
  puts "Duping frames #{dupeis.inspect}"
  dupeis.each do |pfi|
    #pfi = 36 #pframeindicies[rand(pframeindicies.size)]
    n = 30+rand(50)
    puts "picking pframe #{pfi} to dupe #{n} times"
    pf = a.frames[pfi, 1]
    if pf.first.is_iframe?
      abort "fuck, why is #{pfi} a iframe"
    end
    puts pf*n
    frames.concat(pf * n)
  end
  puts "total frames #{frames.size}"
  return frames
end

def glitch_that_shit inputs, output
  #a.mutate_keyframes_into_deltaframes!
  #a.glitch(:keyframes){|d| nil}
  a.glitch(:keyframes) do |data|
    d1 = data[0..data.length/2]
    d2 = data[data.length/2 .. -1]
    d1.gsub(/\d/, 'aaa')
    d1+d2
  end
end

main
