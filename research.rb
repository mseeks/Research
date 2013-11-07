require "rubygems"
require "sequel"
require 'logger'
require 'thread'

db = Sequel.connect("postgres://localhost/books",
					 loggers: Logger.new($stdout))

class Pool
	def initialize(size)
		@size = size
		@jobs = Queue.new

		@pool = Array.new(@size) do |i|
			Thread.new do
				Thread.current[:id] = i

				catch(:exit) do
					loop do
						job, args = @jobs.pop
						job.call(*args)
					end
				end
			end
		end
	end
	def schedule(*args, &block)
		@jobs << [block, args]
	end

	def shutdown
		@size.times do
			schedule { throw :exit }
		end

		@pool.map(&:join)
	end
end

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

p = Pool.new(1000)

Dir.glob("./books/*.txt") do |file|
	text = IO.read(file)
	title = /Title:\s(.+)/i.match(text)[1]
	author = /Author:\s(.+)/i.match(text)[1]
	year = /Year:\s(.+)/i.match(text)[1]
	book = Book.where(title: title, author: author, year: year).first
	if book == nil
		book = Book.create(title: title, author: author, year: year)
		text.strip.split(/\W+/).each do |body|
			body.downcase!
			p.schedule do
				word = Word.where(body: body).first
				if word == nil
					word = Word.create(body: body)
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
end

at_exit { p.shutdown }