class MessageSorter
  @settings = Setting.first

  class << self

    # Directs incomming text 
    def sort_incomming_messages(data, client)
      standup = Standup.check_for_standup(data).first
      user = User.find_by(user_id: data['user'])
      Standup.vacation(data, client) if data['text'].downcase.include? "vacation: <@"
      Standup.admin_skip(data, client) if data['text'].downcase.include? "skip: <@"
      Standup.edit_question(data, client) if data['text'].downcase.include? "edit:"
      Standup.delete_answer(data, client) if data['text'].downcase.include? "delete:"
      quit_standup(client, data['channel']) if data['text'].downcase == "quit-standup"
      help(client, data['channel']) if data['text'].downcase == "help"
      complete_standup(client, data['channel']) if Standup.complete?(client)
      Standup.skip_until_last_standup(client, data, standup) if standup && data['text'].downcase == "skip" && standup.not_complete?
      user_already_completed_standup(client, data) if standup && standup.complete? && data['text'].downcase.exclude?("edit:")
      check_question_status(client, data, user, standup) unless data['text'].downcase.include? "edit:"
      start_standup(client, data) if data['text'].downcase == 'start' && standup.nil?
    end

    def help(client, channel)
      client.message channel: channel, text: "
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

    def start_standup(client, data)
      client.message channel: data['channel'], text: "Standup has started."
      client.message channel: data['channel'], text: "Good morning <@#{data['user']}>, Welcome to daily standup! Are you ready to begin?  ('yes', or 'skip')"
      Standup.check_registration(client, data, true)
    end

    def user_already_completed_standup(client, data)
      text = data['text']
      standup = Standup.where(created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day, user_id: data['user']).first
      if standup.editing
        save_edit_answer(client, data, standup)
      elsif text.include?("vacation: <@") || text.include?("skip: <@") || text.include?("delete:") || text == "help"
      else
        client.message channel: data['channel'], text: "You have already submitted a standup for today, thanks! <@#{data['user']}>"
      end
    end

    def save_edit_answer(client, data, standup)
      if standup.yesterday.nil?
        standup.update_attributes(yesterday: data['text'])
      elsif standup.today.nil?
        standup.update_attributes(today: data['text'])
      elsif standup.conflicts.nil?
        standup.update_attributes(conflicts: data['text'])
      end
      standup.update_attributes(editing: false)
      client.message channel: data['channel'], text: "Your answer has been saved."
    end

    def check_question_status(client, data, user, standup)
      if standup && standup.not_complete? && user.not_ready? && data['text'].downcase == "yes"
        Standup.question_1(client, data, user) if standup && standup.not_complete? && user.not_ready? && data['text'].downcase == "yes"
      elsif standup && standup.not_complete? && user.ready?
        Standup.check_question(client, data, standup)
      end
    end

    def quit_standup(client, channel)
      client.message channel: channel, text: "Quiting Standup"
      client.stop!
    end

    def complete_standup(client, channel)
      channel = client.groups.detect { |c| c['name'] == @settings.name }['id']
      client.message channel: channel, text: "That concludes our standup. For a recap visit http://quiet-shore-3330.herokuapp.com/"
      User.where(admin_user: true).first.update_attributes(admin_user: false) unless User.where(admin_user: true).first.nil?
      client.stop!
    end
  end
end
