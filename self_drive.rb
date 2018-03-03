require 'pp'

def compute_distance(a, b)
	(b[:x] - a[:x]).abs + (b[:y] - a[:y]).abs
end

def get_car_t(car, ride)
	distance_to  = compute_distance(car[:pos], ride[:a])

	[ car[:t] + distance_to, ride[:start_t] ].max + ride[:length]
end

def assign_ride_to_car(fleet, car, ride)
	t = get_car_t(fleet[car], ride)

	fleet[car][:rides] << ride
	fleet[car][:pos]   = ride[:b]
	fleet[car][:t]     = t
end

def assign_rides(rides, fleet)
	rides.each do |ride|
		car = get_best_car(ride, fleet)
		assign_ride_to_car(fleet, car, ride)
	end
end

def car_ride_score(car, ride)
	distance_to  = compute_distance(car[:pos], ride[:a])
	arrival_time = car[:t] + distance_to
	wait_time    = [ ride[:start_t] - arrival_time, 0 ].max

	return 0 if arrival_time + ride[:length] >= ride[:finish_t]

	if arrival_time <= ride[:start_t]
		ride[:length] + B - (wait_time * 1.0) / B
	else
		ride[:length]
	end
end

#rides = RIDES.dup

RIDES = []

t = 0
ride_n = 0
first = true

STDIN.each do |line|
	if first
		R, C, F, N, B, T = line.split.map {|i| i.to_i }
		first = false
		next
	end
	

	l = line.split.map {|i| i.to_i }
	
	ride = {
		n: ride_n,
		a: {
			x: l[0],
			y: l[1]
		},
		b: {
			x: l[2],
			y: l[3]
		},
		start_t:  l[4],
		finish_t: l[5],
	}

	ride[:length] = compute_distance(ride[:a],ride[:b])

	RIDES << ride
	ride_n += 1
end

fleet = {}

(0..F-1).map do |i|
	fleet[i] = {
		rides: [],
		t: 0,
		pos: {
			x: 0,
			y: 0
		}
	}
end

def get_max_score(rides, fleet)
	# max_score = {
	# 	car:  nil,
	# 	ride: nil,
	# 	score: 0
	# }

	max_score = {}

	(0..F-1).each do |i|
		max_score[i] = {
			ride: nil,
			score: 0
		}
	end
	
	fleet.each do |car_idx, car|
		max_car_score = max_score[car_idx]

		rides.each do |ride|
			car_ride_score = car_ride_score(car, ride)

			if car_ride_score > max_car_score[:score]
				max_score[car_idx] = {
					ride:  ride,
					score: car_ride_score
				}
			end
		end
	end

	#STDERR.puts max_score
	max_score
end

rides = RIDES.dup

STDERR.puts "total rides: #{rides.size}"

while true do
	max_score = get_max_score(rides, fleet)

	break if max_score.map {|id, ms| ms[:score] }.max == 0

	max_score.each do |car_idx, max_score|
		if rides.include? max_score[:ride]
			assign_ride_to_car(fleet, car_idx, max_score[:ride])
			rides.delete max_score[:ride]
		end
	end
	
  STDERR.puts "#{rides.size} left to assign"
end

fleet.each do |c, r|
  puts [r[:rides].size, r[:rides].map { |x| x[:n] }.join(" ") ].join (" ")
end
