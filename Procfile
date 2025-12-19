web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -r ./workers/task_executor_worker.rb -C config/sidekiq.yml
