class IncomingMessage

  delegate :yes?,
           :vacation?,
           :skip?,
           :postpone?,
           :quit?,
           :edit?,
           :delete?,
           :help?,
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
    return if user.bot?

    if start? && standup.disabled?
      user.update_attributes(admin_user: true)
      start_standup

    else
      # Checks if a command was entered by the user.
      if command_klass
        command_klass.new(@client, @message, standup).execute

      elsif !edit?
        process_answer
      end

      complete_standup if standup.channel.complete?
    end
  end

  def process_answer
    if yes?
      standup.start!

      @client.message channel: @message['channel'], text: standup.current_question

    elsif standup.in_progress?
      standup.process_answer(@message['text'])

      if standup.complete?
        @client.message channel: @message['channel'], text: 'Good Luck Today!'

        next_user

      else
        @client.message channel: @message['channel'], text: standup.current_question
      end
    end
  end

  def start_standup
    @client.message channel: @message['channel'], text: I18n.t('activerecord.models.incoming_message.standup_started')
    @client.message channel: @message['channel'],
                    text: I18n.t('activerecord.models.incoming_message.welcome', user: @message['user'])
  end

  def next_user
    if (user = channel.pending_users.first)
      @client.message channel: @message['channel'],
                      text: I18n.t('activerecord.models.incoming_message.welcome', user: user.nickname)
    end
  end

  def complete_standup
    User.admin.update_attributes(admin_user: false)
    @client.message channel: @message['channel'], text: I18n.t('activerecord.models.incoming_message.resume', web_url: Setting.first.web_url)

    @client.stop!
  end

  private

  # @return [User]
  def user
    slack_id = (vacation? || skip?) ? message_type.user_id : @message['user']

    @user ||= User.find_by(slack_id: slack_id.upcase)
  end

  # @return [Standup]
  def standup
    @standup ||= Standup.create_if_needed(user.id, channel.id)
  end

  def channel
    @channel ||= Channel.where(slack_id: @message['channel']).first
  end

  # @return [Setting]
  def settings
    @settings ||= Setting.first
  end

  # @return [IncomingMessage::Base]
  def command_klass
    if vacation?                   then Vacation
    elsif skip?                    then Skip
    elsif postpone?                then Postpone
    elsif quit?                    then Quit
    elsif help?                    then Help
    elsif edit? || standup.editing then Edit
    elsif delete?                  then Delete
    end
  end

  # @return [MessageType]
  def message_type
    @message_type ||= MessageType.new(@message['text'])
  end

end
