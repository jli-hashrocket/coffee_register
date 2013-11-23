# As a cashier
# I want to specify a CSV of products
# So that I can process transactions involving those products
# Acceptance Criteria:

# The file must contain a name, a SKU, a retail price, and a purchasing price.
# I can add these items to an order
# As a manager
# I want to get a daily list of sales
# So that I can gage the profitability of my business
# Acceptance Criteria:

# I can opt to enter a reporting section of the application where I am prompted to enter a date
# If sales data is found for that date, I am informed of the gross sales as well as the net profit. I am also told how many items were sold
# If sales data is found for that date, a well-formatted list of orders is outputted. Each order should include the date the order was completed, the time the order was completed, the total number of items purchased, the gross sales, and the cost of goods involved in that order
# If the date specified is in the future, alert the user with an error message
# If the date specified is invalid, alert the user with an error message
# If sales data is not found for that day, alert the user that no sales data was found
require 'pry'
require 'json'
require 'csv'

class Cashier
  def initialize
    @qty = 0
    @p_price_arr = []
    @r_price_arr = []
    @p_price_total = 0.00
    @r_price_total = 0.00
    @purchased = {}
    @all_items = []
    @tender = 0.00
    @items_file = "coffee.csv"
    @report_file = "report.csv"
    @menu = {}
    @hashed_cof_arr = []
  end

  def menu_pull
    csv_contents = CSV.read( @items_file, { headers: true,
                  header_converters: :symbol } )
    @cof_arr = csv_contents.to_a
  end

  def menu
    @cof_arr[1, @cof_arr.length-1].each do |item|
      @hashed_cof= Hash[*(@cof_arr[0].zip(item)).flatten]
      @hashed_cof_arr << @hashed_cof
      puts "SKU:#{@hashed_cof[:sku]} | Name:#{@hashed_cof[:name]} | Retail Price:#{@hashed_cof[:retail_price]} | Purchase Price: #{@hashed_cof[:purchase_price]}"
    end
    puts "Type 'report' to get daily report.\n\n"
    puts "Type 'done' to quit"
    ask
  end

  def ask
    puts "Please select SKU number"
    @selection = gets.chomp
    if @selection == "done"
        tender
        receipt
        abort
    elsif @selection == "report"
          get_report
          abort
    elsif @hashed_cof_arr.any?{|item| @selection == item[:sku]}
        puts "How many bags?"
        @qty = gets.chomp
        if !@qty.match(/\d{2,}|\D/)
          @qty = @qty.to_i
          find_item(@selection)
          subtotal
          store_item
          record_report
        else
          puts "That's an invalid option"
        end
    else
      puts "Invalid option"
    end
  end

  def find_item(selection)
    @ordered_item = @hashed_cof_arr.find do |item|
     item[:sku] == selection
    end
  end

  def get_report
    keep_going = true
    while keep_going
      puts "Enter the date(MM/DD/YYYY) of the report."
      report_date = gets.chomp
      read_file = CSV.read(@report_file)
      date_format = Date.strptime(report_date, '%m/%d/%Y')
      if date_format.to_time < Time.now
        read_file.each do |item|
          if item[0].include?(report_date)
            puts "Date:#{item[0]} | SKU:#{item[1]} | Name:#{item[2]} | Qty:#{item[5]} | Gross Sales:#{item[3]} | Net Profit:#{(item[4].to_f-item[3].to_f).round(2).abs}}"
            keep_going = false
          else
            break puts "No date found"
          end
        end
      else
        puts "Date is in the future!"
      end
    end
  end

  def subtotal
    @p_price_total = @ordered_item[:purchase_price].to_f * @qty
    @r_price_total = @ordered_item[:retail_price].to_f * @qty
    @p_price_arr << @p_price_total
    @r_price_arr << @r_price_total
    @p_price_all = @p_price_arr.inject(:+)
    @r_price_all = @r_price_arr.inject(:+)
    puts "Subtotal: $#{@r_price_all}"
  end

  def store_item
    item_sku = @ordered_item[:sku]
    item_name = @ordered_item[:name]
    item_qty = @qty
    r_item_subtotal = @r_price_all
    p_item_subtotal = @p_price_all
    @purchased['stamp'] = Time.now.strftime("%m/%d/%Y %I:%M:%S")
    @purchased[:item] = {sku:item_sku,name:item_name, retail_subtotal:r_item_subtotal, purchase_subtotal:p_item_subtotal, qty:item_qty}
    @all_items << @purchased[:item]
  end

  def record_report
    reports = File.zero?(@report_file) ? {} : CSV.read( @report_file, { headers: false} )
    date = Time.now.strftime("%m/%d/%Y %I:%M:%S")
    reports[0] = []
    reports[0] << @all_items
    CSV.open(@report_file,'a+') do |log|
      @all_items.each do |item|
        log << item.values.unshift(date)
      end
    end
  end

  def tender
    puts "What is the amount tendered?"
    @tender = gets.chomp
    @change = @tender.to_f - @r_price_all
  end

  def receipt
    date = Time.now.strftime("%m/%d/%Y %I:%M:%S")
    puts "===Sale Complete==="
    @all_items.each do |item|
      puts "$#{item[:retail_subtotal].round(2)} - #{item[:qty]} #{item[:name]}"
    end
    puts "=====Thank You!====="
    puts "\nThe total change due is:#{@change}"
    puts "#{date}"
    puts "===================="
  end
end
