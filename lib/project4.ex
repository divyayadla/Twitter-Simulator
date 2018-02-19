defmodule MN do
  @moduledoc """
  Documentation for MN.
  """

  def main(args) do
    Process.flag(:trap_exit, true)
    node_type = Enum.at(args, 0)

    IO.puts node_type

    :ets.new(:metadata, [:public, :named_table])
    DB.save(:metadata, :main_pid, self())
    
    if node_type == "engine" do
      start_distributed_node("master")
            
      DB.save(:metadata, :tweets_count, 0)
      DB.save(:metadata, :curr_users, 0)
      DB.createTable(:users)
      # DB.createTable(:tweets)
      DB.createTable(:user_followers)
      DB.createTable(:hashtag_followers)
      DB.createTable(:feed)

      # start gen server
      {:ok, gen_pid} = Engine.start_link([])

      # register gen server with an atom name
      :global.register_name(:server, gen_pid)
      
      # :global.register_name(:start_val, 1)

      # IO.inspect "registered " <> inspect(f)


      s = :global.whereis_name(:server)
      # IO.inspect "name " <> inspect(s)

      DB.save(:metadata, :gen_pid, gen_pid)

      IO.puts "Started twitter engine. Now connect simulators."
      start_engine(0, 0, true)
    else
      
      [ name | args] = args

      [val | args] = args
      start_distributed_node(name)
      connect_to_cluster("master@"<>val)

      # sync the global data on each node
      :global.sync

      [n | args] = args
      n = elem(Integer.parse(n), 0)
      IO.puts "Starting twitter simulation with " <> to_string(n) <> " users."
      IO.puts "----------------------------------------------------------------------------"

      engine_node = Enum.at(Node.list, 0)
      IO.inspect "engine_node " <> inspect(engine_node)
      
      # get the gen_servr pid of the backend server from global fata
      gen_pid = :global.whereis_name(:server)

      st = Engine.start_val(gen_pid, n)
      IO.puts "start val is " <> to_string(st)
      ed = st + n

      IO.inspect "master gen_pid is " <> inspect(gen_pid)



      # params = [n]
      # Node.spawn(engine_node ,EngineListener, :initialize, params)


      # [st | args] = args 

      # st = elem(Integer.parse(st), 0)

      # [ed | args] = args
      # ed = elem(Integer.parse(ed), 0)

      args = [ed]
      args = [st | args]
      args = [n | args]
      args = [gen_pid | args]
      args = [engine_node | args]
      args = [name | args]
      {:ok, gen_pid} = Simulator.start_link(args)
      DB.save(:metadata, :gen_pid, gen_pid)
      start_simulation(args)
    end


    # TODO not sure to insert into hashtag_counter.

    # :ets.new(:hashtag_counter, [:public, :named_table])

    

  end

  def start_engine(curr, start_time, f) do
    
    receive do
      {:tweet} -> 
                  if curr == 0 && f do
                    start_time = :os.system_time(:millisecond)
                  end
                  curr = curr + 1;
                  if curr == 1000 do
                    stop_time = :os.system_time(:millisecond)
                    t = stop_time - start_time
                    if t > 0 do
                      ts = 1000000/t
                      IO.puts "tweets per second is " <> inspect(ts)
                    # else
                    #   IO.puts "div by zero" 
                    #   System.halt
                    end

                    # puf()
                    start_engine(0, stop_time, false)
                  else 
                    start_engine(curr, start_time, false)
                  end
    end

    # :timer.sleep(2000)
    # IO.inspect Node.list
    # c = DB.getData(:metadata, :tweets_count)
    # IO.inspect "Tweets send in last 10 seconds are " <> to_string(c)
    # start_engine
  end

  def puf do
    l = Enum.to_list 1..50
    Enum.each(l, fn(x) -> IO.puts "for u" <> to_string(x) <> ", pids are " <> inspect(DB.getData(:users, "u"<> to_string(x))) end)
    Enum.each(l, fn(x) -> IO.puts "for u" <> to_string(x) <> ", fs are " <> inspect(DB.getData(:user_followers, "u"<>to_string(x))) end)

    

  end


  def start_simulation(state) do
    receive do
      {:print, text} -> IO.inspect text
                          start_simulation(state)
      {:login, engine_node, engine_gen_pid, user_id, curr, gen_pid, n, name} -> 
                          args = [name]
                          args = [n | args]
                          args = [gen_pid | args]
                          args = [curr | args]
                          args = [user_id | args]
                          args = [engine_gen_pid | args]
                          args = [engine_node | args]
                          
                          Process.flag(:trap_exit, true)
                          
                          {_, pid} = Task.start(Client, :login, args)
                          start_simulation(state)
      {:exit} -> IO.inspect "Exiting the simulation"
    end
  end


  def start_distributed_node(name) do
    unless Node.alive?() do
      str = "@" <> get_ip_address()
      IO.puts name <> str
      {:ok, _} = Node.start(String.to_atom(name<>str), :longnames)
    end
    cookie = :bitcoins
    Node.set_cookie(cookie)
  end
  def get_ip_address do
    ips = :inet.getif() |> elem(1)
    [head | tail] = ips
    valid_ips = check_if_valid(head, tail, [])
    ip =
      if valid_ips == [] do
        elem(head, 0)
      else 
        Enum.at(valid_ips, 0)
      end
    # ip = Enum.at(valid_ips, 0)
    val = to_string(elem(ip, 0)) <> "." <> to_string(elem(ip, 1)) <> "." <> to_string(elem(ip, 2)) <> "." <> to_string(elem(ip, 3))
    val
  end

  def check_if_valid(head, tail, ipList) do
    ip_tuple = elem(head, 0)

    ipList =
      if !isLocalIp(ip_tuple) do
        if elem(ip_tuple, 0) == 192 || elem(ip_tuple, 0) == 10 || elem(ip_tuple, 0) == 128 do
          [ ip_tuple| ipList]
        else 
          ipList
        end
      else 
        ipList
      end
    
    if tail == [] do
      ipList
    else 
      [new_head | new_tail] = tail
      check_if_valid(new_head, new_tail, ipList)
    end
  end

  def isLocalIp(ip_tuple) do
    if elem(ip_tuple, 0) == 127 && elem(ip_tuple, 1) == 0 && elem(ip_tuple, 2) == 0 && elem(ip_tuple, 3) == 1 do
      true
    else 
      false
    end
  end

  def connect_to_cluster(name) do
    Node.connect String.to_atom(name)
  end



end
