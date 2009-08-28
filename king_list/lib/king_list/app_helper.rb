module KingList
  # Functions in here are only used by the table helper. Those should be moved
  # to a more general place or an own king view helper
  module AppHelper
    # Returns the "real" (in URL visible) parameters of the current URL. That means all but the keys "action" and "controller"
    def visible_params
      @visible_params ||= params.dup.delete_if{|key,value| [:action, :controller].include?(key.to_sym)}
    end

    # Change some params of the current URL (and preserve all others)
    # Example:
    # If the current URL is
    #    /clients?filter[letter]=T&filter[tags]=abc&mode=cards
    # and you call:
    #    change_params(:mode => 'list')
    # The result is:
    #    => /clients?filter[letter]=T&filter[tags]=abc&mode=list
    #
    # Attention, this method uses deep_merge, so it works recursive.
    # See this example: If you call
    #    change_params(:filter => { :letter => 'S' })
    # you get
    #    => /clients?filter[letter]=S&filter[tags]=abc&mode=list
    # Beware that filter[tags] is NOT removed!
    def change_params(options={})
      visible_params.deep_merge(options)
    end

  end
end