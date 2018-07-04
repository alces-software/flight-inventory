
namespace :alces do
  namespace :run do
    task :production_locally do
      ENV['SECRET_KEY_BASE'] = `rake secret`
      ENV['DATABASE_URL'] = 'postgres://postgres@localhost:5432/flight-inventory_development'

      ENV['RAILS_ENV'] = 'production'
      sh 'yarn install'
      Rake::Task['assets:clobber'].invoke
      Rake::Task['assets:precompile'].invoke

      sh 'bundle exec rails server'

    rescue Interrupt
      # Stops Yarn complaining about packages being out-of-date when run `rails
      # server` for development after this.
      sh 'RAILS_ENV=development yarn install'
    end
  end
end
