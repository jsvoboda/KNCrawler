# t1 = Thread.new do
# 	puts "thread 1"
# 	sleep 10
# end

# t2 = Thread.new do
# 	puts "thread 2"
# 	sleep 10
# end

# def func1
#   i = 0
#   while i <= 5
#     puts "func1 at: #{Time.now}"
#     sleep(2)
#     i = i + 1
#   end
# end
# def func2
#   i = 0
#   while i <= 5
#     puts "func2 at: #{Time.now}"
#     sleep(1)
#     i = i + 1
#   end
# end

# puts "Start at: #{Time.now}"
# t1 = Thread.new{func1()}
# t2 = Thread.new{func2()}
# t1.join
# t2.join
# puts "End at: #{Time.now}"

while true
	# go_to_land(land_num_guess.to_s << sub_num.to_s, @current_region)

	# text = @driver.find_element(:id, "content").text.encode('UTF-8')

	# if text.match(@land_num_regex) then
	#     land_details = get_land_details
	#     store_land_details land_details
	# else
	#     break
	# end

	sub_num++
end