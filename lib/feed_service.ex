defmodule FeedService do

	def feed(user_id, pid_map) do
		list = DB.getData(:feed, user_id)
		if list do
			if list != [] do
				DB.save(:feed, user_id, [])
				# args = [list]
				# args = [pid_map | args]
				# Process.flag(:trap_exit, true)
				# Task.start(UserService, :sendFeed, args)
				UserService.sendFeed(pid_map, list)				
			end
		end
		
	end

	def feed(user_id) do
		pid_map = UserService.getUserPid(user_id)
		list = DB.getData(:feed, user_id)
		if list do
			if list != [] do
				Process.flag(:trap_exit, true)
				DB.save(:feed, user_id, [])
				# args = [list]
				# args = [pid_map | list]
				# Task.start(UserService, :sendFeed, args)
				UserService.sendFeed(pid_map, list)				
			end
		end
		
	end

	def saveFeed(user_id, tweet, text) do
		list = DB.getData(:feed, user_id)
		tweet_map = %{:tweet => tweet, :text => text}
		list =
			if list do
				list
			else
				[]
			end
		
		list = [tweet_map | list]
		DB.save(:feed, user_id, list)
	end

end