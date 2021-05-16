class ResultService
  def self.create(game, params)
    result = game.results.build

    next_rank = Team::FIRST_PLACE_RANK
    teams = (params[:teams] || {}).values.each.with_object([]) do |team, acc|
      players = Array.wrap(team[:players]).delete_if(&:blank?)
      acc << { rank: next_rank, players: players }

      next_rank = next_rank + 1 if team[:relation] != "ties"
    end

    teams = teams.reverse.drop_while{ |team| team[:players].empty? }.reverse

    teams.each do |team|
      result.teams.build rank: team[:rank], player_ids: team[:players]
    end

    if result.valid?
      Result.transaction do
        game.rater.update_ratings game, result.teams

        result.save!

        verb = [
          "conquered", "crushed" "rolled", "overcame", "ground down",
          "demoralized", "vanquished", "shot down", "foiled", "wrecked",
          "murked", "frustrated", "stymied", "taught a nice lesson to",
          "schooled", "pwned", "whooped", "how bout dem apples-ed", "bossed",
          "sauced", "smoked", "booped", "rinsed", "sacked", "rocked", "clobbered"
        ].sample
        SlackNotifier.new.send("#{result.winners.first.name} #{verb} #{result.losers.first.name}")

        OpenStruct.new(
          success?: true,
          result: result
        )
      end
    else
      OpenStruct.new(
        success?: false,
        result: result
      )
    end
  end

  def self.destroy(result)
    return OpenStruct.new(success?: false) unless result.most_recent?

    Result.transaction do
      result.players.each do |player|
        player.rewind_rating!(result.game)
      end

      result.destroy

      OpenStruct.new(success?: true)
    end
  end
end
