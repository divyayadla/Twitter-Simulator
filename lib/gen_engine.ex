defmodule Engine do
  
  use GenServer

  # def create(server, name) do
  #   GenServer.cast(server, {:create, name})
  # end

  # def handle_cast({:create, name}, names) do
  #   if Map.has_key?(names, name) do
  #     {:noreply, names}
  #   else
  #     {:ok, bucket} = KV.Bucket.start_link([])
  #     {:noreply, Map.put(names, name, bucket)}
  #   end
  # end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [name: :server])
  end

  def init(args) do
    # IO.puts "inside engine init"
    Process.flag(:trap_exit, true)
    mpid = DB.getData(:metadata, :main_pid)
    {:ok, %{:main_pid => mpid, :start_val => 1}}
  end

  def start_val(server, n) do
    GenServer.call(server, {:start_val, n})
  end 

  def handle_call({:start_val, n}, _from, state) do
    
    st = state[:start_val]
    new_st = st+n
    state = state |> Map.put(:start_val, new_st)

    {:reply, st, state}
  end

  def register(server, user_map) do
    # IO.puts "inside register"
    GenServer.cast(server, {:register, user_map})
  end

  def handle_cast({:register, user_map}, state) do
    # IO.puts "inside register cast"
    UserService.register(user_map)
    {:noreply, state}
  end

  def login(server, user_map) do
    GenServer.cast(server, {:login, user_map})
  end

  def handle_cast({:login, user_map}, state) do
    UserService.login(user_map)
    {:noreply, state}  
  end
  
  def logout(server, user_map) do
    GenServer.cast(server, {:logout, user_map})
  end

  def handle_cast({:logout, user_map}, state) do
    UserService.logout(user_map)
    {:noreply, state}  
  end

  def tweet(server, user_id, tweet) do
    # IO.puts "inside tweets"
    GenServer.cast(server, {:tweet, user_id, tweet})
  end

  def handle_cast({:tweet, user_id, tweet}, state) do
    # IO.puts "inside tweets cast"
    Process.flag(:trap_exit, true)
    
    # TweetService.tweet(user_id, tweet, state[:main_pid])
    args = [state[:main_pid]]
    args = [ tweet | args]
    args = [ user_id | args]
    Task.start(TweetService, :tweet, args)
    {:noreply, state}  
  end

  def retweet(server, user_id, tweet) do
    GenServer.cast(server, {:retweet, user_id, tweet})
  end

  def handle_cast({:retweet, user_id, tweet}, state) do
    Process.flag(:trap_exit, true)
    
    # TweetService.retweet(user_id, tweet, state[:main_pid])
    args = [state[:main_pid]]
    args = [ tweet | args]
    args = [ user_id | args]
    Task.start(TweetService, :retweet, args)

    {:noreply, state}  
  end

  # def follow_user(server, user_id, follow_user_id) do
    
  # end

  def follow_users(server, user_id, followers, c) do
    GenServer.cast(server, {:follow_users, user_id, followers, c})
  end

  def handle_cast({:follow_users, user_id, followers, c}, state) do
    FollowService.followUsers(user_id, followers, c)
    {:noreply, state}  
  end

  def follow_hashtag(server, hashtag, users, c) do
    GenServer.cast(server, {:follow_hashtag, hashtag, users, c})
  end

  def handle_cast({:follow_hashtag, hashtag, users, c}, state) do
    FollowService.followHashtag(hashtag, users, c)
    {:noreply, state}  
  end

  def unfollow_user(server, user_id, unfollow_user_id) do
    GenServer.cast(server, {:unfollow_user, user_id, unfollow_user_id})
  end

  def handle_cast({:unfollow_user, user_id, unfollow_user_id}, state) do
    FollowService.unfollowUser(user_id, unfollow_user_id)
    {:noreply, state}  
  end

  def unfollow_hashtag(server, user_id, hashtag) do
    GenServer.cast(server, {:unfollow_hashtag, user_id, hashtag})
  end

  def handle_cast({:unfollow_hashtag, user_id, hashtag}, state) do
    FollowService.unfollowHashtag(user_id, hashtag)
    {:noreply, state}  
  end

  def getFeed(server, user_id, state) do
    GenServer.cast(server, {:getFeed, user_id})
  end

  def handle_cast({:getFeed, user_id}, state) do
    FeedService.feed(user_id)
    {:noreply, state}  
  end

end