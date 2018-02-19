defmodule Client do
	
	def register(engine_node, engine_gen_pid, user_id, curr, gen_pid, n, name) do
		password = hash_sha256(user_id)
		user_map = %{:user_id => user_id, :password => password, :client_node => Node.self, 
					 :client_gen_pid => gen_pid, :user_pid => self(), :node_name => name}
		state = %{:engine_node => engine_node, :engine_gen_pid => engine_gen_pid, :gen_pid => gen_pid,
					:user_id => user_id, :password => password, :id => curr, :total_users=> n, :node_name => name}

		args = [user_map]
		args = [engine_gen_pid | args]
		Node.spawn(engine_node, Engine, :register, args)

		IO.puts user_id <> " registered."
		# follow_users(user_id)
		run(state)
	end

	def login(engine_node, engine_gen_pid, user_id, curr, gen_pid, n, name) do
		password = hash_sha256(user_id)
		user_map = %{:user_id => user_id, :password => password, :client_node => Node.self, 
					 :client_gen_pid => gen_pid, :user_pid => self(), :node_name => name}
		state = %{:engine_node => engine_node, :engine_gen_pid => engine_gen_pid, 
					:user_id => user_id, :password => password, :id => curr, :total_users=> n}
		args = [user_map]
		args = [engine_gen_pid | args]
		Node.spawn(engine_node, Engine, :login, args)
		IO.puts user_id <> " logged in."
		send self(), {:start_tweeting, true}
		run(state)
	end

	def retweet_probability(c) do
		# n = :math.pow(2,c) |> round
		# l = Enum.take_random(1..n, 1)
		c = c + 1
		l = Enum.take_random(1..c, 1)
		[head | l] = l
		if c == head do
			true
		else
			false
		end
	end

	def tweet(parent_pid, ts, state) do
		
		l = DB.getData(:metadata, :hashtags)
		hs = Enum.take_random(l, 2)
		l1 = getUsers(state[:total_users], 1, state[:id])
		text = random_string()
		in_mid = " "
		text = listToString(hs, text, in_mid)
		text = listToString(l1, text, in_mid <> "@")
		# IO.inspect "tweet generated => " <> text
		user_id = state[:user_id]
		tweet_obj = %{:user_id => user_id, :owner => user_id, :text => text, :hashtags => hs, :mentions => l1, :count => 1}
		args = [tweet_obj]
		args = [user_id | args]
		args = [state[:engine_gen_pid] | args]
		# IO.puts "before sending tweets to engine args " <> inspect(args)
		Node.spawn(state[:engine_node], Engine, :tweet, args)
		
		val = String.slice(user_id, 1..-1) |> Integer.parse |> elem(0)
		
		# if user_id == 'u256' do
		# 	IO.puts "tweet of u256 is " <> inspect(text)
		# end
		:timer.sleep(250)
		if ts > 0 do
			tweet(parent_pid, ts-1, state)
		else 
			if rem(val, 137) == 0 do
				IO.puts user_id <> " tweeted " <> text
			end
			send parent_pid, {:logout}
		end
	end

	def concat(list, c, text) do
		if c == 0 do
			text
		else
			[head | list] = list
			text = text <> "\n" <> "Notification: " <> head[:text] <> "  Tweet: \"" <> head[:tweet][:text] <> "\""
			concat(list, c-1, text)
		end
	end

	def process(c, feed) do
		if c > 0  && feed != [] do
			[head | feed] = feed
			send self(), {:notify, head[:tweet], head[:text]}
			process(c-1, feed)
		end
	end

	def run(state) do
		receive do 
			{:feed, feed} -> 
							Process.flag(:trap_exit, true)
							args = [state]
							ts = :rand.uniform(50)
							args = [ts | args]
							args = [self() | args]
							Task.start(__MODULE__, :tweet, args)
							# IO.puts "feed count for " <> inspect(state[:user_id]) <> inspect(length(feed))
							text = "From " <> state[:user_id] <> "'s feed  showing the latest 3 tweeets.. "
							text = concat(feed, 3, text)
							IO.puts text
							# Enum.each(feed, fn(x) -> IO.puts "From " <> inspect(state[:user_id]) <> "'s feed: " <> inspect(x[:text]) <> " tweet obj -> " <> inspect(x[:tweet]) end)
							process(100, feed)
							run(state)
			{:start_tweeting, f} -> # start tweeting 
						if f do
							Process.flag(:trap_exit, true)
							args = [state]
							ts = :rand.uniform(100)
							args = [ts | args]
							args = [self() | args]
							Task.start(__MODULE__, :tweet, args)
						end
						# l = DB.getData(:metadata, :hashtags)
						# hs = Enum.take_random(l, 1)
						# l1 = getUsers(state[:total_users], 1, state[:id])
						# text = random_string()
						# in_mid = " "
						# text = listToString(hs, text, in_mid)
						# text = listToString(l1, text, in_mid <> "@")
						# # IO.inspect "tweet generated => " <> text
						# user_id = state[:user_id]
						# tweet_obj = %{:user_id => user_id, :owner => user_id, :text => text, :hashtags => hs, :mentions => l1}
						# args = [tweet_obj]
						# args = [user_id | args]
						# args = [state[:engine_gen_pid] | args]
						# # IO.puts "before sending tweets to engine args " <> inspect(args)
						# Node.spawn(state[:engine_node], Engine, :tweet, args)
						:timer.sleep(500)
						run(state)
			{:notify, tweet, text} -> #IO.puts "inside notify message."
										#IO.inspect text <> " tweet -> " <> inspect(tweet)
										c = tweet[:count]
										tweet = Map.put(tweet, :count, c+1)

										if retweet_probability(c) do
											if c > 4 && c <= 20 do
												if c == 4 do
													IO.puts state[:user_id] <> " retweeted " <> tweet.user_id <>  "'s tweet.   Tweet => " <> tweet.text
												else 
													IO.puts tweet.user_id <> "'s tweet is retweeted " <> to_string(c) <> " times.   Tweet =>" <> tweet.text
												end
											end
											if c <= 20 do
												args = [tweet]
												args = [state[:user_id] | args]
												args = [state[:engine_gen_pid] | args]
												Node.spawn(state[:engine_node], Engine, :retweet, args)
											end
										end
										run(state)

			{:logout} -> 	user_map = %{:user_id => state[:user_id], :password => state[:password]}
							args = [user_map]
							args = [state[:engine_gen_pid] | args ]
							Node.spawn(state[:engine_node], Engine, :logout, args)

							IO.puts state[:user_id] <> " logged out."
							
							ts = :rand.uniform(10)
							:timer.sleep(ts*1000)
							engine_node = state[:engine_node]
							engine_gen_pid = state[:engine_gen_pid]
							gen_pid = state[:gen_pid]
							curr = state[:id]
							n = state[:total_users]
							name = state[:node_name]
							user_id = state[:user_id]

							send DB.getData(:metadata, :main_pid), {:login, engine_node, engine_gen_pid, user_id, curr, gen_pid, n, name}
							
		end
	end

	def listToString(list, res, in_mid) do
		if list == [] do
			res
		else
			[head | list] = list
			listToString(list, res <> in_mid <> to_string(head), in_mid)
		end
	end

	def getUsers(n, c, p) do
		l = Enum.take_random(1..n, c+1)
		solve(l, 0, c, p, [])
	end

	def solve(rem, i, c, p, res) do
		if i == c do
			res
		else
			[u | rem] = rem
			if u == p do
				solve(rem, i, c, p, res)
			else
				res = [ "u" <> to_string(u) | res]
				solve(rem, i+1, c, p, res)
			end
		end
	end

	def hash_sha256(str) do
		:crypto.hash(:sha256, str) |> Base.encode16
	end

	def random_string(n \\ 16, pool \\ "abcdefghijklmnopqrstuvwxyz") do 
        random_string_util("", n, pool)
    end
    def random_string_util(s, n, pool) do
        if n <= 0 do 
            s 
        else 
            size = byte_size(pool)
            random_number = :rand.uniform(size)
            str = s <> String.at(pool, random_number-1)
            random_string_util(str, n-1, pool)
        end
    end

end