require "rubygems"
require "sequel"
require 'logger'
require 'thread'

db = Sequel.connect("postgres://localhost/books",
					 loggers: Logger.new($stdout))

class Book < Sequel::Model
	one_to_many :uses
	many_to_many :words, join_table: :uses
end

class Use < Sequel::Model
	many_to_one :book
	many_to_one :word
end

class Word < Sequel::Model
	one_to_many :uses
	many_to_many :books, join_table: :uses
end

Book.each do |book|
	puts "#{book.title} uses #{book.words.count}."
end