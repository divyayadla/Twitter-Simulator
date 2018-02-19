defmodule UserService do
  
  def register(user_map) do
    # IO.puts "inside reg " <> inspect(user_map)
    user_id = user_map[:user_id]
    password = user_map[:password]
    node = user_map[:client_node]
    pid = user_map[:user_pid]
    gen_pid = user_map[:client_gen_pid]
    str = 
      if DB.getData(:users, user_id) do
        user_id <> " user already registered."
      else
        pid_map = %{:client_node => node, :client_gen_pid => gen_pid, :client_pid=> pid}
        map = %{:password => password, :pid => pid_map}
        DB.save(:users, user_id, map)
        DB.save(:user_followers, user_id, [])
        # IO.puts "saved data " <> inspect(DB.getData(:users, user_id))
        user_id <> " user registered successfully."
        # st = DB.getData(:metadata, :state)

        # IO.puts "st: " <> inspect(st)
        # c = st[:curr_users]
        # c = c + 1
        # n = st[:total_users]
        # st = st |> Map.put(:curr_users, c)
        # if n == c do
        #   IO.puts "before starting follow setup."
        #   Node.spawn(node, Simulator, :follow_setup, [gen_pid])
        # end
        # DB.save(:metadata, :state, st)
      end
    # IO.puts inspect(str)
    # send DB.get(:metadata, :main_pid), {:print, str}
  end

  def login(user_map) do
    user_id = user_map[:user_id]
    password = user_map[:password]
    node = user_map[:client_node]
    pid = user_map[:user_pid]
    gen_pid = user_map[:client_gen_pid]
    res = DB.getData(:users, user_id)
    str = 
      if res do
        if res[:password] == password do
          pid_map = %{:client_node => node, :client_gen_pid => gen_pid, :client_pid=> pid}
          map = res
                  |> Map.put(:pid, pid_map)
          DB.save(:users, user_id, map)
          user_id <> " logged in successfully."
          FeedService.feed(user_id, pid_map)
        else
          "Login failed for user " <> user_id <> ". Reason invalid credentials."
        end
      else 
        user_id <> " is not registered yet."
      end
      # IO.puts inspect(str)
      # send DB.getData(:metadata, :main_pid), {:print, str}
  end

  def logout(user_map) do
    user_id = user_map[:user_id]
    password = user_map[:password]
    
    res = DB.getData(:users, user_id)
    str =
      if res do
        if res[:password] == password do
          map = res
                  |> Map.delete(:pid)
          DB.save(:users, user_id, map)
        else
          "Logout failed for user " <> user_id <> ". Reason user is not loggged in."
        end
      else
        user_id <> " is not registered yet."
      end
    # IO.puts inspect(str)
      # send DB.getData(:metadata, :main_pid), {:print, str}
  end

  def getUserPid(user_id) do
    res = DB.getData(:users, user_id)
    str =
      if res do
        res[:pid]
      else
        nil
      end
  end

  # TODO
  def sendMessage(pid, tweet, text) do
    node = pid[:client_node]
    gen_pid = pid[:client_gen_pid]
    pid = pid[:client_pid]
    args = [text]
    args = [tweet | args]
    args = [pid | args]
    args = [gen_pid | args]
    # IO.puts "send tweet to user with args " <> inspect(args)
    Node.spawn(node, Simulator, :notify, args)
  end

  def sendFeed(pid, feed) do
    node = pid[:client_node]
    gen_pid = pid[:client_gen_pid]
    pid = pid[:client_pid]
    args = [feed]
    args = [pid | args]
    args = [gen_pid | args]
    # IO.puts "send feed to user with args " <> inspect(args)
    Node.spawn(node, Simulator, :feed, args)
  end

end