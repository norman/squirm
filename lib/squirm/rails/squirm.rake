namespace :db do
  namespace :schema do
    task :load do
      functions = File.read(Rails.root.join("db", "stored_procedures.sql"))
      ActiveRecord::Base.connection.execute functions
    end
  end
end