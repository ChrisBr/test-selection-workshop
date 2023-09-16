# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

puts "Seeding database..."

article = Article.create!(title: "Rails World", body: "The Rails Foundation is excited to announce Rails World, our first conference. It will take place on October 5 & 6 in the stunning city of Amsterdam, Netherlands.")
article.comments.create!(title: "Awesome!", body: "This is really awesome! I will join!")

article = Article.create!(title: "Rails 7.0.8 has been released", body: "I am happy to announce that Rails 7.0.8 has been released.")
article.comments.create!(title: "Yesss!", body: "This is the best Rails release ever!")

puts "Successfully seeded database..."
