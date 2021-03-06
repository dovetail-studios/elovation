class SlackNotifier
  def initialize(username = "DovePong", icon_emoji = ":table_tennis_paddle_and_ball:")
    @webhook_url = ENV["SLACK_WEBHOOK_URL"]
    @username = username
    @icon_emoji = icon_emoji
  end

  def send(text)
    return unless @webhook_url

    headers = { 'Content-Type' => 'application/json' }
    body = { "text": text, "icon_emoji": @icon_emoji, username: @username}

    begin
      r = HTTParty.post(@webhook_url, body: body.to_json, headers: headers )
      return (r.code == 200)
    rescue
      return false
    end
  end
end
