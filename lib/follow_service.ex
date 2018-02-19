defmodule FollowService do
	# def followUser(user_id, follow_user_id) do
	# 		# if UserService.getUserPid(user_id) do
	# 		# 	if UserService.getUserPid(follow_user_id) do
	# 			followers = DB.getData(:user_followers, follow_user_id)

	# 			str = 
	# 				if Enum.member?(followers, user_id) do
	# 					user_id <> " is already following " <> follow_user_id.
	# 				else 
	# 					followers = [user_id | followers]
	# 					DB.save(:user_followers, user_id, followers)
	# 					user_id <> " is now following " <> follow_user_id
	# 				end
	# 		# 	else 
	# 		# 		follow_user_id <> " user doesn't exist."
	# 		# 	end
	# 		# else
	# 		# 	user_id <> " user doesn't exist."
	# 		# end
	# 	send DB.getData(:metadata, main_pid), {:print, str}
	# end

	def followUsers(user_id, followers, c) do
		# IO.puts "for user_id " <> inspect(user_id)
		DB.save(:user_followers, user_id, followers)
		# i = String.slice(user_id, 1..-1) |> elem(0)
		# if rem(i, 7) == 0 do
		# 	str = user_id <> " is now subscribed by " <> to_string(c) <> " users."
		# 	IO.puts inspect(str)
		# end



		# st = DB.getData(:user_followers, user_id)

		# IO.puts user_id <> " followers " <> inspect(st)
        # c = st[:curr_users]

		# c = c - 1
		# st = st |> Map.put(:curr_users, c)
		# DB.print(:users)
		# if c == 0 do
		# 	pid_map = DB.getData(:users, user_id)
		# 	nd = pid_map[:client_node]
		# 	gen_pid = pid_map[:client_gen_pid]
		# 	Node.spawn(nd, Simulator, :start_tweeting, [gen_pid])
		# end
		# DB.save(:metadata, :state, st)

		# send DB.getData(:metadata, :main_pid), {:print, str}
	end

	def followHashtag(hashtag, users, c) do
		DB.save(:hashtag_followers, hashtag, users)
		# str = hashtag <> " is now subscribed by " <> to_string(c) <> " users."
		# IO.puts inspect(str)
	end

	# def followHashtag(user_id, hashtag) do
	# 		# if UserService.getUserPid(user_id) do
	# 			res = DB.getData(:hashtag_followers, hashtag)
	# 			followers =
	# 				if res do
	# 					res
	# 				else
	# 					send DB.getData(:metadata, main_pid), {:print, hashtag <> " created."}
	# 					[]
	# 				end

	# 		str = 		
	# 			if Enum.member?(followers, user_id) do
	# 				user_id <> " is already following " <> hashtag
	# 			else
	# 				followers = [user_id | followers]
	# 				DB.save(:hashtag_followers, hashtag, followers)
	# 				user_id <> " is now following " <> hashtag
	# 			end
	# 		# else
	# 		# 	user_id <> " user doesn't exist."
	# 		# end
	# 	send DB.getData(:metadata, main_pid), {:print, str}		
	# end

	def unfollowUser(user_id, unfollow_user_id) do
		followers = DB.getData(:user_followers, unfollow_user_id)
		list = Enum.filter(followers, fn(x) -> x != user_id end)
		DB.save(:user_followers, unfollow_user_id, list)
		IO.puts "Succesfully unfollowed " <> inspect(unfollow_user_id)
		# send DB.getData(:metadata, :main_pid), {:print, "Succesfully unfollowed " <> unfollow_user_id}
	end

	def unfollowHashtag(user_id, hashtag) do
		followers = DB.getData(:hashtag_followers, hashtag)
		list = Enum.filter(followers, fn(x) -> x != user_id end)
		DB.save(:hashtag_followers, hashtag, list)
		IO.puts "Succesfully unfollowed " <> inspect(hashtag)
		# send DB.getData(:metadata, :main_pid), {:print, "Succesfully unfollowied " <> hashtag}
	end

end