# load schemas for cache, cable and queue

%i[cache cable queue].each do |db|
  ActiveRecord::Base.establish_connection(db)
  load "db/#{db}_schema.rb"
end
