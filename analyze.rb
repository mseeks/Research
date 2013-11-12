require "rubygems"
require "sequel"
require 'logger'

db = Sequel.connect('sqlite://words.db')
# , loggers: Logger.new($stdout)

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
  word_count = 0
  book.uses.each do |use|
    word_count += use.count
  end
  most_used = Use.where(book_id: book.id).reverse_order(:count).limit(50)
	puts "#{book.title} uses #{book.words.count} unique words, with a word count of #{word_count}. The most used words were:"
  most_used.each do |use|
    puts "\t| #{use.word.body}\t|\t#{use.count}\t|\t#{((use.count/word_count.to_f)*100).round(2)}%\t|\t#{use.count*use.word.length}"
  end
end