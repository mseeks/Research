require "rubygems"
require "sequel"
require 'logger'

db = Sequel.connect('sqlite://words.db', loggers: Logger.new($stdout))

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

Dir.glob("./books/*.txt") do |file|
	text = IO.read(file)
	title = /Title:\s(.+)/i.match(text)[1]
	author = /Author:\s(.+)/i.match(text)[1]
	year = /Year:\s(.+)/i.match(text)[1]
	book = Book.where(title: title, author: author, year: year).first
	if book == nil
		book = Book.create(title: title, author: author, year: year)
		text.strip.split(/[[:punct:]||[:space:]||[:blank:]]+/).each do |body|
			body.downcase!
				word = Word.where(body: body).first
				if word == nil
					word = Word.create(body: body, length: body.length)
				end
				use = Use.where(book_id: book.id, word_id: word.id).first
				if use == nil
					use = Use.create(book_id: book.id, word_id: word.id, count: 0)
				end
				use.count += 1
				use.save
			end
	end
end