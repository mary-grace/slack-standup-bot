class MessageType

  # @param [String] message.
  def initialize(message)
    @message = message || ''
  end

  # @return [Boolean]
  def yes?
    @message.include?('yes')
  end

  # @return [Boolean]
  def vacation?
    @message.include?('vacation: <@')
  end

  # @return [Boolean]
  def skip?
    @message.include?('skip: <@')
  end

  # @return [Boolean]
  def postpone?
    @message.include?('skip')
  end

  # @return [Boolean]
  def edit?
    @message.include?('edit:')
  end

  # @return [Boolean]
  def delete?
    @message.include?('delete:')
  end

  # @return [Boolean]
  def quit?
    @message.include?('quit-standup')
  end

  # @return [Boolean]
  def help?
    @message.include?('help')
  end

  # @return [Boolean]
  def start?
    @message.include?('start')
  end

end

