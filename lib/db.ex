defmodule DB do
	def getData(table, key) do
		res = :ets.lookup(table, key)
		if length(res) == 0 do
			nil
		else 
			elem(Enum.at(res, 0),1)
		end
	end

	def save(table, key, value) do
		:ets.insert(table, {key, value})
	end

	def delete(table, key) do
		:ets.delete(table, key)
	end

	def createTable(table) do
		:ets.new(table, [:public, :named_table])
	end

	# def print(table) do
	# 	IO.puts "table: " <> inspect(table)
	# 	:ets.i(table)
	# end

end