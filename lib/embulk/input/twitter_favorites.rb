require "twitter"

module Embulk
  module Input
    class TwitterFavorites < InputPlugin
      Plugin.register_input("twitter_favorites", self)

      def self.transaction(config, &control)
        task = {
          "screen_name" => config.param("screen_name", :string, default: ""),
          "consumer_key"     => config.param("consumer_key", :string),
          "consumer_secret"  => config.param("consumer_secret", :string),
          "access_token"        => config.param("access_token", :string),
          "access_token_secret" => config.param("access_token_secret", :string),
        }

        columns = [
          Column.new(0, "tweet",         :json),
        ]

        resume(task, columns, 1, &control)
      end

      def self.resume(task, columns, count, &control)
        task_reports = yield(task, columns, count)

        next_config_diff = {}
        return next_config_diff
      end

      # TODO
      # def self.guess(config)
      #   sample_records = [
      #     {"example"=>"a", "column"=>1, "value"=>0.1},
      #     {"example"=>"a", "column"=>2, "value"=>0.2},
      #   ]
      #   columns = Guess::SchemaGuess.from_hash_records(sample_records)
      #   return {"columns" => columns}
      # end

      def init
        # initialization code:
        @screen_name = task["screen_name"]

        consumer_key     = task["consumer_key"]
        consumer_secret  = task["consumer_secret"]
        access_token        = task["access_token"]
        access_token_secret = task["access_token_secret"]

        @client = Twitter::REST::Client.new do |config|
          config.consumer_key        = consumer_key
          config.consumer_secret     = consumer_secret
          config.access_token        = access_token
          config.access_token_secret = access_token_secret
        end
      end

      def run
        max_id = nil
        tweets = @client.favorites(@screen_name)
        while !tweets.empty? do
          tweets.each do |tweet|
            json = {
              screen_name: @screen_name,
              id: tweet.id,
              text: tweet.text,
              creator_screen_name: tweet.user.screen_name,
              created_at: tweet.created_at,
            }.to_json

            page_builder.add([json])
          end
          max_id = tweets.last.id
          Embulk.logger.info("favorite tweets are loaded until: #{max_id}")
          tweets = @client.favorites(@screen_name, max_id: max_id - 1)
        end
      rescue Twitter::Error::TooManyRequests => e
        rate_limit = e.rate_limit
        Embulk.logger.info("rate limit: limit: #{rate_limit.limit}, remaining: #{rate_limit.remaining}, reset_at: #{rate_limit.reset_at}")
      ensure
        page_builder.finish
        task_report = {last_max_id: max_id}
        return task_report
      end
    end

  end
end
