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
          "last_max_id"   => config.param("last_max_id", :integer, default: nil),
          "last_since_id" => config.param("last_since_id", :integer, default: nil),
        }

        columns = [
          Column.new(0, "screen_name", :string),
          Column.new(1, "id", :string),
          Column.new(2, "text", :string),
          Column.new(3, "creator_screen_name", :string),
          Column.new(4, "created_at", :string),
          Column.new(5, "url", :string),
        ]

        resume(task, columns, 1, &control)
      end

      def self.resume(task, columns, count, &control)
        task_reports = yield(task, columns, count)

        next_config_diff = {}

        max_ids = task_reports.map { |task_report| task_report["last_max_id"].to_i }
        since_ids = task_reports.map { |task_report| task_report["last_since_id"].to_i }
        max_id = max_ids.min
        since_id = since_ids.max

        next_config_diff["last_max_id"] = max_id if max_id.nonzero?
        next_config_diff["last_since_id"] = since_id if since_id.nonzero?

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
        @max_id = task["last_max_id"]

        @client = Twitter::REST::Client.new do |config|
          config.consumer_key        = consumer_key
          config.consumer_secret     = consumer_secret
          config.access_token        = access_token
          config.access_token_secret = access_token_secret
        end
      end

      def run
        params = {count: 100}
        current_max_id = nil
        current_since_id = nil

        params[:max_id] = @max_id.to_i if @max_id

        # TODO: もろもろ共通化
        tweets = @client.favorites(@screen_name, params).sort { |t| t.created_at.to_i }

        # NOTE: 次回最新から取るための値を入れておく
        current_since_id = tweets.first.id unless tweets.empty?

        while !tweets.empty? do
          tweets.each do |tweet|
            page_builder.add(
              [
                @screen_name,
                "#{tweet.id}",
                tweet.text,
                tweet.user.screen_name,
                tweet.created_at,
                tweet.url.to_s,
              ]
            )
          end

          current_max_id = tweets.last.id - 1
          params[:max_id] = current_max_id
          Embulk.logger.info("favorite tweets are loaded until: #{current_max_id}")
          tweets = @client.favorites(@screen_name, params).sort { |t| t.created_at.to_i }
        end

        # since_idは指定があるときのみ使う
        if @since_id
          params[:since_id] = @since_id.to_i

          tweets = @client.favorites(@screen_name, params).sort { |t| t.created_at.to_i }
          while !tweets.empty? do
            tweets.each do |tweet|
              page_builder.add(
                [
                  @screen_name,
                  "#{tweet.id}",
                  tweet.text,
                  tweet.user.screen_name,
                  tweet.created_at,
                  tweet.url.to_s,
                ]
              )
            end

            current_since_id = tweets.first.id + 1
            params[:since_id] = current_since_id
            Embulk.logger.info("favorite tweets are loaded since: #{current_since_id}")
            tweets = @client.favorites(@screen_name, params).sort { |t| t.created_at.to_i }
          end
        end

      rescue Twitter::Error::TooManyRequests => e
        rate_limit = e.rate_limit
        Embulk.logger.info("rate limit: limit: #{rate_limit.limit}, remaining: #{rate_limit.remaining}, reset_at: #{rate_limit.reset_at}")
      rescue => e
        Embulk.logger.error(e.message)
        raise e
      ensure
        page_builder.finish

        task_report = {}
        task_report["last_max_id"] = current_max_id if current_max_id
        task_report["last_since_id"] = current_since_id if current_since_id

        return task_report
      end
    end

  end
end
