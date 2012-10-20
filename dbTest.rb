require "sqlite3"

@db = SQLite3::Database.new "testDB.db"
begin
	@db.execute "DROP TABLE testTable"
rescue SQLite3::SQLException
	puts "wtf?!"
end



# @db.execute "CREATE TABLE testTable(attr1 TEXT PRIMARY KEY, attr2 TEXT)"
# @db.execute "CREATE VIRTUAL TABLE IF NOT EXISTS testTable USING fts3(attr1 TEXT PRIMARY KEY, attr2 TEXT)"
# @db.execute "INSERT INTO testTable(attr1, attr2) VALUES ('key1', 'value1')"
# @db.execute "INSERT INTO testTable(attr1, attr2) VALUES ('key1', 'value2')"

rs = @db.execute  "SELECT * FROM testTable WHERE attr1 MATCH 'key1'" 

rs.each do |row|
    puts row
end
