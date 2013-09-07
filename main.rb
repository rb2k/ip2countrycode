require 'open-uri'
require 'ipaddr'

def generate_lookup_table
  delegation_lists = [
  'ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-latest',
  'ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-latest',
  'ftp://ftp.arin.net/pub/stats/arin/delegated-arin-latest',
  'ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-latest',
  'ftp://ftp.ripe.net/pub/stats/ripencc/delegated-ripencc-latest'
  ]
  lookup_table = {}
  delegation_lists.each do |list|
    puts "List: #{list}"
    open(list).read.each_line do |line|
      next unless line.include?('ipv4')
      # http://www.apnic.net/publications/media-library/documents/resource-guidelines/rir-statistics-exchange-format
      registry, cc, type, start, value, date, status, extensions = line.split('|')
      ipaddr1 = IPAddr.new start rescue next
      ipaddr2 = IPAddr.new(ipaddr1.to_i + value.to_i, Socket::AF_INET)
      range = ipaddr1.to_i..(ipaddr1.to_i + value.to_i)
      lookup_table[cc] ||= []
      lookup_table[cc] << range
      puts "#{ipaddr1} - #{ipaddr2}: #{cc}"    
    end
  end
end

persisted_table_filename = 'ip_countrycode_lookup.dat'

if File.exists?(persisted_table_filename)
  lookup_table = File.open(persisted_table_filename) { |file| Marshal.load(file) } 
  puts "Loaded persisted table."
else
  lookup_table = generate_lookup_table
  File.open(persisted_table_filename,'w') { |file| Marshal.dump(lookup_table, file) }
  puts "Created new lookup table and persisted it."
end

loop do
  puts "Enter your IP:"
  ip_input = IPAddr.new(gets.chomp).to_i rescue next
  result = 'n/a'
  lookup_table.each_pair do |cc, ranges|
    if not ranges.select{|range| range.include?(ip_input)}.empty?
      result = cc
      break
    end
  end
  puts result
end
