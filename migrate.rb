require "rubygems"
require "sequel"
require 'logger'

db = Sequel.connect("postgres://localhost/books",
					 loggers: Logger.new($stdout))
					 
db.create_table :books do
	primary_key :id
	String :title
	String :author
	Integer :year
end

db.create_table :words do
	primary_key :id
	String :body
end

db.create_table :uses do
	primary_key :id
	Integer :count
	foreign_key :book_id, :books
	foreign_key :word_id, :words
end