---
-- Arrange output into tables.
--
-- This module provides NSE scripts with a way to output structured tables
-- similar to what <code>NmapOutputTable.cc</code> provides.
--
-- Example usage:
-- <code>
-- local t = tab.new(2)
-- tab.add(t, 1, 'A1')
-- tab.add(t, 2, 'A2')
-- tab.nextrow(t)
-- tab.add(t, 1, 'BBBBBBBBB1')
-- tab.add(t, 2, 'BBB2')
-- tab.nextrow(t)
-- tab.addrow(t, 'C1', 'C2')
-- tab.dump(t)
-- </code>
-- @copyright Same as Nmap--See http://nmap.org/book/man-legal.html

module(... or "tab",package.seeall)

require('strbuf')

--- Create and return a new table with a given number of columns and
-- the row counter set to 1.
-- @return A new table.
function new()
	local table ={}

	table.current_row = 1
	setmetatable(table, {__tostring=dump})
	return table
end

--- Add a new string item to a table at a given column position.
--
-- The item will be added to the current row. If <code>nextrow</code> hasn't
-- been called yet that will be row 1.
-- @param t The table.
-- @param v The string to add.
-- @param c The column position at which to add the item.
function add(t, c, v)
	assert(t)
	assert(type(v) == "string")

	-- add a new row if one doesn't exist
	if t[t.current_row] == nil then
		t[t.current_row] = {}
	end

	t[t.current_row][c] = v
	return true
end

--- Add a complete row to the table and move on to the next row.
--
-- Calls <code>add</code> for each argument starting with the second argument
-- and after that calls <code>nextrow</code>.
-- @param t The table.
-- @param ... The elements to add to the row.
function addrow(t, ...)
	for i=1, select("#", ...) do
		add( t, i, tostring( ( select(i, ...)) ) )
	end
	nextrow( t )
end

--- Move on to the next row in the table. If this is not called
-- then previous column values will be over-written by subsequent
-- values.
-- @param t The table.
function nextrow(t)
	assert(t)
	assert(t.current_row)
	t[t.current_row] = t[t.current_row] or {}
	t.current_row = t.current_row + 1
end

--- Return a formatted string representation of the table.
--
-- The number of spaces in a column is based on the largest element in the
-- column with an additional two spaces for padding.
-- @param t The table.
function dump(t)
	assert(t)

	local column_width = {}	
	local num_columns = {}
	local buf = strbuf.new()

	-- find widest element in each column
	for i, row in ipairs(t) do
		num_columns[i] = 0
		for x, elem in pairs(row) do
			local elem_width = string.len(elem)
			if not column_width[x] or elem_width > column_width[x] then
				column_width[x] = elem_width
			end
			if x > num_columns[i] then
				num_columns[i] = x
			end
		end
	end

	-- build buf with padding so all column elements line up
	for i, row in ipairs(t) do
		local text_row = {}
		for x = 1, num_columns[i] do
			local elem = row[x] or ""
			if x < num_columns[i] then
				text_row[#text_row + 1] = elem .. string.rep(" ", column_width[x] - #elem)
			else
				text_row[#text_row + 1] = elem
			end
		end
		buf = buf .. table.concat(text_row, "  ") .. "\n"
	end

	return strbuf.dump(buf)
end
