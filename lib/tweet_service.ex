defmodule TweetService do

	# tweet
	# 	user_id : ""
	# 	owner : ""
	# 	text : ""
	# 	mentions : []
	# 	hashtags : []

	def tweet(user_id, tweet, mpid) do
		
		# TODO c should be incremented by only one method.

		send mpid, {:tweet}
#		if user_id == "u256" do
#			IO.puts "send tweet " <> inspect(tweet[:text])
#		end
		mentions = tweet[:mentions]
		text = user_id <> " mentioned you in a tweet."
		Enum.each(mentions, fn(x) -> sendTweet(x, tweet, text) end)

		followers = DB.getData(:user_followers, user_id)
		text = user_id <> " is tweeting."
		Enum.each(followers, fn(x) -> sendTweet(x, tweet, text) end)
		hashtags = tweet[:hashtags]
		Enum.each(hashtags, 
			fn(x) -> 
				text = "users are tweeting about " <> x;
				y = DB.getData(:hashtag_followers, x);
				if y do
					Enum.each(y, fn(z) -> sendTweet(z, tweet, text) end);
				end
			end)

	end

	def retweet(user_id, tweet, mpid) do
		
		send mpid, {:tweet}

#		if user_id == "u256" do
#			IO.puts "send retweet " <> inspect(tweet[:text])
#		end
		
		Process.flag(:trap_exit, true)

		followers = DB.getData(:user_followers, user_id)
		text = user_id <> " retweeted " <> tweet.user_id <> "'s tweet"
		Enum.each(followers, fn(x) -> sendTweet(x, tweet, text) end)

		# hashtags = tweet_obj[:hashtags]
		# Enum.each(hashtags, 
		# 	fn(x) -> 
		# 		text = "users are tweeting about " <> x
		# 		y = DB.getData(:hashtag_followers, x);
		# 		if y do
		# 			Enum.each(y, fn(z) -> sendTweet(z, tweet, text));
		# 		end
		# 	end)
	end

	def sendTweet(user_id, tweet, text) do
		pid_map = UserService.getUserPid(user_id)
		# IO.puts user_id <> " pid_map is " <> inspect(pid_map)
		if pid_map do
			# args = [text]
			# args = [tweet | args]
			# args = [pid_map | args]
			UserService.sendMessage(pid_map, tweet, text)
			# Task.start(UserService, :sendMessage, args)
		else 
			FeedService.saveFeed(user_id, tweet, text)
		end
	end

end