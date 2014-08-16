# just random timing helpers for debugging..

def time!
  $t = Time.now.to_f
  $tt = nil if $tt
end

def time?
  puts "since beginning: #{Time.now.to_f - $t}"
  puts "since last time?: #{Time.now.to_f - $tt}" if $tt
  $tt = Time.now.to_f
end
