class IncomingMessage

  delegate :yes?,
           :vacation?,
           :skip?,
           :status?,
           :postpone?,
           :quit?,
           :edit?,
           :delete?,
           :help?,
           :not_available?,
           :start?, to: :message_type

  # @param [Hash] message.
  # @option message [String] :type.
  # @option message [String] :channel.
  # @option message [String] :user.
  # @option message [String] :text.
  # @param [Slack::RealTime::Client] client.
  def initialize(message, client)
    @message = message
    @client  = client
  end

  # Executes incomming message.
  def execute
    return if current_user && (current_user.bot? || (channel.standups.empty? && !start? && !help? && !quit?))

    if start?
      start_standup
    elsif current_standup_is_empty?
      channel.start_today_standup!
      command.execute unless ![Quit, Help].include?(command.class)
    elsif command
      command.execute

      if (standup.completed? || standup.idle?) && ![Status, Quit, Help].include?(command.class)
        next_user
      end
    end

  rescue Base::InvalidCommand => e
    @client.message(channel: @message['channel'], text: e.message)
  end

  def start_standup
    current_user.mark_as_admin!
    channel.start_today_standup!

    if standup.idle?
      standup.init!

      @client.message(channel: @message['channel'], text: I18n.t('activerecord.models.incoming_message.standup_started'))

      @client.message(channel: @message['channel'],
                      text: I18n.t('activerecord.models.incoming_message.welcome', user: current_user.slack_id))
    else
      next_user
    end
  end

  def next_user
    if standup.channel.complete?
      complete_standup

    elsif (next_standup = channel.pending_standups.first)
      next_standup.init!

      @client.message(channel: @message['channel'],
                      text: I18n.t('activerecord.models.incoming_message.welcome', user: next_standup.user_slack_id))
    end
  end

  def complete_standup
    User.admin.try(:update_attributes, { admin: false })
    @client.message channel: @message['channel'], text: I18n.t('activerecord.models.incoming_message.resume', url: settings.web_url)

    @client.stop!
  end

  private

  # @return [Boolean]
  def current_standup_is_empty?
    Standup.today.empty?
  end

  # @return [User]
  def current_user
    @user ||= User.find_by(slack_id: @message['user'])
  end

  # @return [Standup]
  def standup
    @standup ||= channel.today_standups.where(user_id: current_user.id).first!
  end

  def channel
    @channel ||= Channel.where(slack_id: @message['channel']).first!
  end

  # @return [Setting]
  def settings
    @settings ||= Setting.first
  end

  # @return [IncomingMessage::Base]
  def command
    return @command if defined?(@command)

    klass =
      if vacation?               then Vacation
      elsif not_available?       then NotAvailable
      elsif skip?                then Skip
      elsif postpone?            then Postpone
      elsif quit?                then Quit
      elsif help?                then Help
      elsif edit?                then Edit
      elsif delete?              then Delete
      elsif status?              then Status
      elsif standup.in_progress? then Answer
      end

    @command = klass.new(@client, @message, standup) if klass
  end

  # @return [MessageType]
  def message_type
    @message_type ||= MessageType.new(@message['text'])
  end

end
