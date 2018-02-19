defmodule Simulator do
	use GenServer
	
	def start_link(args) do
		GenServer.start_link(__MODULE__, args)
	end

	# def start_tweeting(server) do
	# 	GenServer.cast(server, {:start_tweeting})
	# end

	# def handle_cast({:start_tweeting}, state) do
	# 	Enum.each state[:pids], fn(k,v) -> send v, {:start_tweeting} end
	# 	{:noreply, state}
	# end


	# def login(server, user_id) do
	# 	GenServer.cast(server, {:login, user_id})
	# end

	# def handle_cast({:login, user_id}, state) do
	# 	{:noreply, state}
	# end


	# def logout(server, user_id) do
	# 	GenServer.cast(server, {:logout, user_id})
	# end

	# def handle_cast({:logout, user_id}, state) do
	# 	{:noreply, state}		
	# end


	def notify(server, pid, tweet, text) do
		# IO.puts "inside notify and tweet is " <> inspect(tweet)
		GenServer.cast(server, {:notify, pid, tweet, text})
	end

	def handle_cast({:notify, pid, tweet, text}, state) do
		send pid, {:notify, tweet, text}
		{:noreply, state}
	end
	
	def feed(server, user_pid, feed) do
		GenServer.cast(server, {:feed, user_pid, feed})
	end

	def handle_cast({:feed, user_pid, feed}, state) do
		send user_pid, {:feed, feed}
		{:noreply, state}
	end

	def init(args) do
		Process.flag(:trap_exit, true)
		
		# Task.start(SimulatorService, start, args)
		# IO.inspect(args)
		[name | args] = args
		[nd | args] = args
		[gen_pid | args] = args
		[n | args] = args
		[st | args] = args
		[ed | args] = args
		IO.puts "start val of user_id is: " <> inspect(st) <> ", end value : " <> inspect(ed) 
				<> "\n total no of users present in this simulation node: " <> to_string(n)
						# <> ",gen: " <> inspect(gen_pid) <> ", nd: " <> inspect(nd)
		# IO.inspect "no of users " <> to_string(n)
		createHashtags()
		map = register(nd, gen_pid, st, ed, %{:st => st, :ed => ed}, [], name, [])
		# IO.puts "map => " <> inspect(map)
		map = map |> Map.put(:count, n) |> Map.put(:gen_pid, gen_pid) |> Map.put(:node, nd)
		:timer.sleep(2000)
		follow_setup(map)
		:timer.sleep(2000)
		# IO.puts "pids are " <> inspect(map[:pids])
		Enum.each map[:pids], fn(x) -> send x, {:start_tweeting, true} end
		{:ok, map}
	end

	def createHashtags do
		DB.createTable(:hashtags)
		list = ["#goodmorning", "#goodafternoon", "#goodevening", 
			"#breakfast", "#brunch", "#lunch", "#dinner", 
			"#sunday", "#monday", "#tuesday", "#wednesday", "#thursday", "#friday", "#saturday",
			"#happy", "#sad", "#angry", "#love", "#caring", "#affection"
		]
		DB.save(:metadata, :hashtags, list)
	end


	def register(nd, gen_pid, curr, n, pids, users, name, ps) do
		Process.flag(:trap_exit, true)
		if curr <= n do
			user_id = "u" <> to_string(curr)
			users = [user_id | users]
			args = [name]
			args = [n | args]
			args = [self() | args]
			args = [curr | args]
			args = [user_id | args]
			args = [gen_pid | args]
			args = [nd | args]
			{_, pid} = Task.start(Client, :register, args)
			# res = %{:pids => pids}
			pids = pids |> Map.put(user_id, pid)
			ps = [ pid | ps]
			register(nd, gen_pid, curr+1, n, pids, users, name, ps)
		else
			pids |> Map.put(:users, users) |> Map.put(:pids, ps)
		end
	end

	def follow_setup(state) do
		users = state[:users]
		n = state[:count]
		nd = state[:node]
		gen_pid = state[:gen_pid]
		hashtags = DB.getData(:metadata, :hashtags)
		follow_hashtags(hashtags, users, n, gen_pid, nd)
		st = state[:st] 
		ed = state[:ed]
		follow_setup_helper(users, users, 1, st, ed, gen_pid, nd, st, ed)
	end

	def follow_hashtags(hashtags, users, n, gen_pid, nd) do
		p = round(n/10)
		follow_hashtags_helper(hashtags, users, p, gen_pid, nd)
	end

	def follow_hashtags_helper(hashtags, users, p, gen_pid, nd) do
		if hashtags != [] do
			[ ht | hashtags] = hashtags
			# p1 = :rand.uniform(100) - 50
			# if p + p1 < 10 do
			# 	p
			# else 
			# 	p = p + p1
			# end

			l = Enum.take_random(users, p)
			args = [p]
			args = [l | args]
			args = [ht | args]
			args = [gen_pid | args]
			Node.spawn(nd, Engine, :follow_hashtag, args)
			
			str = ht <> " is randomly subscribed by " <> to_string(p) <> " users."
			IO.puts inspect(str)

			follow_hashtags_helper(hashtags, users, p, gen_pid, nd)
		end
	end

	def follow_setup_helper(users, total_users, curr, c, n, gen_pid, nd, st, ed) do
		if users != [] do
			[user_id | users] = users
			for_each_user(total_users, curr, user_id, c, n, gen_pid, nd, st, ed)
			follow_setup_helper(users, total_users, curr+1, c+1, n, gen_pid, nd, st, ed)
		end
	end

	def for_each_user(users, c, user_id, c_st, n, gen_pid, nd, st, ed) do
		s = 2
		val = round(0.07 * n)
		count = getFollowersCount(c, s, val)
		# IO.puts "for u" <> to_string(c) <> " count of f " <> to_string(count)
		if count < 10 do
			count = 10
		end

		# fc = Enum.take_random(users, count+1)
		# fc = Enum.filter(fc, fn(x) ->  user_id != x end)
		pos = elem(String.slice(user_id, 1..-1) |> Integer.parse,0)
		fc = get_followers(pos, st, ed, count, [])

		args = [count]
		args = [fc | args]
		args = [user_id | args]
		args = [gen_pid | args]
		Node.spawn(nd, Engine, :follow_users, args)
		# if rem(pos, 7) == 0 do
		# 	str = user_id <> " is now subscribed by " <> to_string(count) <> " users."
		# 	IO.puts inspect(str)
		# end
	end

	def get_followers(pos, st, ed, count, res) do
		if count > 0 do
			pos = pos + 1
			if pos == ed do
				pos = st
			end
			res = ["u" <> to_string(pos) | res]
			get_followers(pos, st, ed, count-1, res)
		else
			res
		end
	end

	def getFollowersCount(c, s, n) do
		round(Float.ceil(n / pow(c, s, 1)))
	end

	def pow(i, c, val) do
		if c == 0 do
			1
		else
			if c == 1 do
				val
			else 
				pow(i, c-1, val*i)
			end
		end
	end

end