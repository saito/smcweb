# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def hbr(str)
    str = html_escape(str)
    str.gsub(/\r\n|\r|\n/, "<br />")
  end
end
