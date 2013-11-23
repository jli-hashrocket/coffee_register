require 'pry'
require_relative "coffeeregister.rb"

puts "Welcome to the Coffee Emporium"

cashier = Cashier.new
cashier.menu_pull
cashier.menu

while true
  cashier.ask
end
