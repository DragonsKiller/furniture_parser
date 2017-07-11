#!/usr/bin/env ruby
require 'nokogiri'
require 'open-uri'
require 'addressable/uri'
require 'csv'

Dir['../lib/*.rb'].each {|f| require_relative(f)}

begin
  BrwParser.new('https://www.brw.by', 'https://www.brw.by/collections/').parse
  NemanParser.new('http://www.mebel-neman.by', ['http://www.mebel-neman.by/catalog/gostinaya/','http://www.mebel-neman.by/catalog/spalnya/', 'http://www.mebel-neman.by/catalog/molodejnay/', 'http://www.mebel-neman.by/catalog/prikhozhaya/']).parse
  IsleepParser.new('https://isleep.by/matrasy', 'https://isleep.by/matrasy/?page=').parse
end
