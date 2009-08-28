# override rails extra_tags_for_form method wich creates hidden special form
# fields -> method and auth_token
# so they don't use inline styles anymore
# From:
#   <div style="margin:0;padding:0"><input name="authenticity_token"
# To:
#   <div><input name="authenticity_token"
module ActionView::Helpers::FormTagHelper
  private
  # overridden method to kill inline styles
  # from actionpack-2.1.0/lib/action_view/helpers/form_tag_helper.rb
  def extra_tags_for_form(html_options)
    case method = html_options.delete("method").to_s
      when /^get$/i # must be case-insentive, but can't use downcase as might be nil
        html_options["method"] = "get"
        ''
      when /^post$/i, "", nil
        html_options["method"] = "post"
        protect_against_forgery? ? content_tag(:div, token_tag) : ''
      else
        html_options["method"] = "post"
        content_tag(:div, tag(:input, :type => "hidden", :name => "_method", :value => method) + token_tag)
    end
  end
end