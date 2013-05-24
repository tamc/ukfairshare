require 'sinatra'
require 'json'
require './model'

# We want to be able to work out which methods are unique to our Model
# and which methods are common to all FFI modules, so we create an empty
# FFI module.
module FFIMethodsToIgnore; extend FFI::Library; end

# This should be identical to the one in src/javacripts/chart.js.coffee
url_structure = [
  "version",
  "first_year_of_responsibility",
] - ["version"] # A cludge to make the above lines easier to copy and paste

# This is the method that is used to request data from the model
# the first part of the url is to match a version number the remainder
# should match the url_structure above. 
#
# The method sets the named methods in the url structure to the values passed in the url
# it then alters the year_second_wave_of_building_starts back from 2050 towards 2010 to
# try and get 2050 emissions below 5gCO2/kWh.
#
# It then passes back the results of the model as json
get '/data/1:*' do 
  m = ModelShim.new
  # If a parameter looks like a number, make it a number
  controls =  params[:splat][0].split(':').map { |v| v =~ /^-?\d+\.?\d*$/ ? v.to_f : v }
  m.reset
  controls.each.with_index do |v,i|
    next unless v && v != ""
    m.send(url_structure[i]+"=",v)
  end
  tsv = m.results.map { |row| row.map { |cell| cell ? cell : "" }.join("\t") }.join("\n")
  content_type 'text/tab-separated-values'
  tsv
end

# The root url. Just returns index.html at the moment
get '*' do
  send_file 'public/index.html'
end
