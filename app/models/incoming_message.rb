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
    return if standup.nil? && !start?

    Standup.vacation(@message, @client)      if vacation?
    Standup.admin_skip(@message, @client)    if skip?
    Standup.edit_question(@message, @client) if edit?
    Standup.delete_answer(@message, @client) if delete?

    quit_standup     if quit?
    help             if help?
    complete_standup if Standup.complete?(@client)

    if postpone? && !standup.try(:complete?)
      Standup.skip_until_last_standup(@client, @message, standup)
    else
      user_already_completed_standup if edit? && standup.try(:complete?)
      check_question_status          if !edit?
      start_standup                  if start? && standup.nil?
    end
  end

  def help
    @client.message channel: @message['channel'], text: "
    Standup-bot help. \n Admin Commands.
      • start                                   Begin Standup. \n
      • vacation: @user          Skip users standup for the day. \n
      • skip: @user                    Place user at the end of standup. \n
      • quit-standup                 Quit standup. \n User Commands.
      • yes                                       Begin your standup. \n
      • skip                                     Skip your standup until the end of standup. \n
      • edit: #(1,2,3)                  Edit your answer for the day. \n
      • delete: #(1,2,3)             Delete your answer for the day. \n"
  end

  def start_standup
    @client.message channel: @message['channel'], text: "Standup has started."
    @client.message channel: @message['channel'], text: "Good morning <@#{@message['user']}>, Welcome to daily standup! Are you ready to begin?  ('yes', or 'skip')"
    Standup.check_registration(@client, @message, true)
  end

  def user_already_completed_standup
    text = @message['text']

    if standup.editing
      save_edit_answer(client, @message, standup)
    elsif text.include?("vacation: <@") || text.include?("skip: <@") || text.include?("delete:") || text == "help"
    else
      @client.message channel: @message['channel'],
                      text: "You have already submitted a standup for today, thanks! <@#{@message['user']}>"
    end
  end

  def save_edit_answer
    if standup.yesterday.nil?
      standup.update_attributes(yesterday: @message['text'])
    elsif standup.today.nil?
      standup.update_attributes(today: @message['text'])
    elsif standup.conflicts.nil?
      standup.update_attributes(conflicts: @message['text'])
    end
    standup.update_attributes(editing: false)
    @client.message channel: @message['channel'], text: "Your answer has been saved."
  end

  def check_question_status
    if standup && !standup.complete? && user.not_ready? && yes?
      Standup.question_1(@client, @message, user) if standup && !standup.complete? && user.not_ready? && yes?
    elsif standup && !standup.complete? && user.ready?
      Standup.check_question(@client, @message, standup)
    end
  end

  def quit_standup
    @client.message channel: @message['channel'], text: "Quiting Standup"
    @client.stop!
  end

  def complete_standup
    @client.message channel: @message['channel'], text: "That concludes our standup. For a recap visit http://quiet-shore-3330.herokuapp.com/"

    User.where(admin_user: true).first.update_attributes(admin_user: false) unless User.where(admin_user: true).first.nil?

    @client.stop!
  end

  private

  # @return [User]
  def user
    @user ||= User.find_by(user_id: @message['user'])
  end

  # @return [Standup]
  def standup
    @standup ||= Standup.check_for_standup(@message).first
  end

  # @return [Setting]
  def settings
    @settings ||= Setting.first
  end

  # @return [MessageType]
  def message_type
    @message_type ||= MessageType.new(@message['text'])
  end

end
